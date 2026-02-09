//
//  WordsForest
//
//  Created by Nami .T on 2025/09/15.→01/20履歴閲覧可能版へ→2026/01/24宿題履歴系
//
// HomeworkState.swift
import SwiftUI

// CEFR レベル（必要なら別ファイルでもOK）
enum CEFRLevel: String, CaseIterable, Hashable {
    case A1, A2, B1, B2, C1, C2
}

// 既存の PosPair に、対応する品詞配列を返すヘルパー
extension PosPair {
    var parts: [PartOfSpeech] {
        switch self {
        case .nounAdj: return [.noun, .adj]
        case .verbAdv: return [.verb, .adv]
        }
    }
    // 追加：表示名
    var jaTitle: String {
        switch self {
        case .nounAdj: return "名詞＋形容詞"
        case .verbAdv: return "動詞＋副詞"
        }
    }
}
enum HomeworkStatus: String, Codable { case active, paused, none }
enum PosPair: Int, Codable { case nounAdj = 0, verbAdv = 1 }

struct HomeworkEntry: Identifiable, Codable,Hashable {
    var id: UUID
    var date: Date
    var status: HomeworkStatus
    var pair: PosPair
    var wordsCount: Int

    // ★追加（過去データには無いので decodeIfPresent で拾う）
    var wordIDs: [UUID]

    private enum CodingKeys: String, CodingKey {
        case id, date, status, pair, wordsCount, wordIDs
    }

    // ふだん作るとき用（新規作成）
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        status: HomeworkStatus = .active,
        pair: PosPair,
        wordsCount: Int = 24,
        wordIDs: [UUID] = []
    ) {
        self.id = id
        self.date = date
        self.status = status
        self.pair = pair
        self.wordsCount = wordsCount
        self.wordIDs = wordIDs
    }

    // 過去JSON互換（wordIDs が無くても落ちない）
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try c.decode(UUID.self, forKey: .id)
        self.date = try c.decode(Date.self, forKey: .date)
        self.status = try c.decode(HomeworkStatus.self, forKey: .status)
        self.pair = try c.decode(PosPair.self, forKey: .pair)
        self.wordsCount = try c.decode(Int.self, forKey: .wordsCount)
        self.wordIDs = (try? c.decode([UUID].self, forKey: .wordIDs)) ?? []
    }

    var statusIcon: String {
        switch status {
        case .active: return "🟩"
        case .paused: return "⏸️"
        case .none:   return "⛔️"
        }
    }

    var pairLabel: String {
        switch pair {
        case .nounAdj: return "名詞＋形容詞"
        case .verbAdv: return "動詞＋副詞"
        }
    }

    var titleLine: String {
        "\(statusIcon) 宿題：\(pairLabel) (\(wordsCount)語)"
    }
}


final class HomeworkState: ObservableObject {
    // 設定
    @AppStorage("hw_daysPerCycle") var daysPerCycle: Int = 7
    // 当初の設定（先生が「今回は1週/2週」って決めた値）
    @AppStorage("hw_baseDaysPerCycle") private var baseDaysPerCycle: Int = 7

    // 延長した週数（0,1,2...）
    @AppStorage("hw_extensionWeeks") private var extensionWeeks: Int = 0
    @AppStorage("hw_paused") var paused: Bool = false
    // ✅ 自動サイクル更新をするか（あなたの運用では false 推奨）
    @AppStorage("hw_autoAdvanceByDate") private var autoAdvanceByDate: Bool = false
    @AppStorage("hw_statusRaw") private var statusRaw: String = HomeworkStatus.active.rawValue
    // 取り込み（複数ID対応）
    @AppStorage("hw_lastImportedPayloadID") private var lastImportedPayloadID: String = ""
    // 取り込み（複数ID対応）
    @AppStorage("hw_importedPayloadIDs_json") private var importedIDsRaw: String = "[]"

    /// 取得済みpayload.idの集合
    private var importedIDs: Set<String> {
        get {
            guard let data = importedIDsRaw.data(using: .utf8),
                  let arr = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return Set(arr)
        }
        set {
            let arr = Array(newValue)
            if let data = try? JSONEncoder().encode(arr),
               let s = String(data: data, encoding: .utf8) {
                importedIDsRaw = s
            } else {
                importedIDsRaw = "[]"
            }
        }
    }
    // 交互ローテ
    @AppStorage("hw_pairIndex") private var pairIndex: Int = 0
    var currentPair: PosPair { PosPair(rawValue: pairIndex) ?? .nounAdj }

    // 🆕 サイクル番号（0,1,2,...）
    @AppStorage("hw_cycleIndex") private var cycleIndex: Int = 0
    var currentCycleIndex: Int { cycleIndex }
    @Published var status: HomeworkStatus {
        didSet { statusRaw = status.rawValue; logNow() }
    }
    @Published var variantOthers = 0
    // 週合計24の内訳（お好みで変更可）
    @Published var weeklyQuota: [PartOfSpeech: Int] = [
        .noun: 12, .verb: 12, .adj: 12, .adv: 12
    ]    
    // 学習に含める語彙レベル（まずは A1〜B1）
    @Published var allowedLevels: Set<CEFRLevel> = [.A1, .A2, .B1]
    
    // 🔷 今サイクルの宿題セット（品詞ごと）
    //    画面に反映させたいので @Published にする
    @Published private(set) var cachedHomework: [PartOfSpeech: [WordCard]] = [:]

    // restore / build の多重実行防止
    private var restoreRequested = false
    private var buildRequested = false
    
    // 🆕 今サイクル表示用のラベル
    var currentPairLabel: String { currentPair.jaTitle }

    var cycleLengthLabel: String {
        switch daysPerCycle {
        case 7:  return "1週間"
        case 14: return "2週間"
        default: return "\(daysPerCycle)日"
        }
    }
    
    // 🆕 ボタンなどで使う「今サイクル」まとめ表示
    var currentCycleLabel: String {
        "\(currentPairLabel)"   // 今はペア名だけでOK
        // もし「名詞＋形容詞・1週間」とか出したくなったら ↓ にすればいい
        // "\(currentPairLabel)・\(cycleLengthLabel)"
    }
    
    // サイクル開始
    @AppStorage("hw_cycleStart") private var cycleStartISO: String =
        ISO8601DateFormatter().string(from: Date())
    // 動物色（起点）
    @AppStorage("variant_noun") var variantNoun: Int = 0
    @AppStorage("variant_adj")  var variantAdj:  Int = 0
    @AppStorage("variant_verb") var variantVerb: Int = 0
    @AppStorage("variant_adv")  var variantAdv:  Int = 0

    // 履歴
    @AppStorage(DefaultsKeys.hwHistoryJSON) private var historyRaw: String = "[]"
    @Published private(set) var history: [HomeworkEntry] = []
    @Published var uiTick: Int = 0

    private let iso = ISO8601DateFormatter()
    private var cycleStartDate: Date {
        get { iso.date(from: cycleStartISO) ?? Date() }
        set { cycleStartISO = iso.string(from: newValue) }
    }
    
    // ✅ 期限切れ“表示用”（中身は変えない）
    var isCycleExpired: Bool {
        let elapsed = Calendar.current.dateComponents([.day], from: cycleStartDate, to: Date()).day ?? 0
        return elapsed >= daysPerCycle
    }

    init() {
        // ① UserDefaults から“生”の値を読む（self を経由しない）
        let rawStatus = UserDefaults.standard.string(forKey: "hw_statusRaw")
            ?? HomeworkStatus.active.rawValue
        self.status = HomeworkStatus(rawValue: rawStatus) ?? .active

        let rawHistory = UserDefaults.standard.string(forKey: DefaultsKeys.hwHistoryJSON)
            ?? "[]"
        self.history = Self.decode(rawHistory)
        sanitizeHistoryIfNeeded()

        // ② HomeworkStateBridge に自分を登録
        if let bridge = HomeworkStateBridge.shared {
            bridge.state = self
        } else {
            _ = HomeworkStateBridge(state: self)
        }
    }
    
    // ✅ 方針：日数経過で自動的に新パックへ進めない
    // 宿題は「先生が明示操作」した時だけ変わる
    
    func refresh(now: Date = Date()) {
        
            #if DEBUG
            print("extensionWeeks =", extensionWeeks,
                  "baseDaysPerCycle =", baseDaysPerCycle,
                  "daysPerCycle =", daysPerCycle)
            #endif
            
        guard status != .none else { return }
        guard !paused && status != .paused else { return }

        // ✅ あなたの運用：自動更新しない
        guard autoAdvanceByDate else { return }

        let elapsed = Calendar.current.dateComponents([.day], from: cycleStartDate, to: now).day ?? 0
        if elapsed >= daysPerCycle {
            advanceCycle(from: now)
        }
    }
    
    func resetExtension() {
        extensionWeeks = 0
        daysPerCycle = baseDaysPerCycle
    }
    
    func advanceCycle(from now: Date = Date()) {
        // 🔹 新しいサイクルに入るので宿題セットをリセット
        cachedHomework.removeAll()
        // ペア交互
        pairIndex = (pairIndex + 1) % 2
        // 🆕 サイクル番号を進める
        cycleIndex += 1
        
        // 色ローテ（当該ペアのみ）
        switch currentPair {
        case .nounAdj:
            variantNoun = (variantNoun + 1) % 3
            variantAdj  = (variantAdj  + 1) % 3
        case .verbAdv:
            variantVerb = (variantVerb + 1) % 3
            variantAdv  = (variantAdv  + 1) % 3
        }
        cycleStartDate = now
        logNow(now) // サイクル切替も履歴に刻む
    }

    // 表示用：当初の「1週間/2週間」
    var baseCycleLengthLabel: String {
        switch baseDaysPerCycle {
        case 7:  return "1週間"
        case 14: return "2週間"
        default:
            if baseDaysPerCycle % 7 == 0 { return "\(baseDaysPerCycle / 7)週間" }
            return "\(baseDaysPerCycle)日"
        }
    }

    // 表示用：延長が入ってるときだけ出す
    var extensionLabel: String? {
        extensionWeeks > 0 ? "+\(extensionWeeks)週延長" : nil
    }

    var isExtended: Bool { extensionWeeks > 0 }
    
    // 先生が当初設定を切り替える（延長はリセット）
    func setBaseDaysPerCycle(_ days: Int) {
        
       #if DEBUG
       print("setBaseDaysPerCycle called ->", days, " (reset extension)")
       #endif
        baseDaysPerCycle = days
        extensionWeeks = 0
        daysPerCycle = days
    }
    
    // 先生が「＋1週延長」を押した
    func extendOneWeek() {
        extensionWeeks += 1
        daysPerCycle = baseDaysPerCycle + extensionWeeks * 7
    }
    // 操作系（ワンタップ）
    func setActive() { status = .active; paused = false }
    func setPaused() { status = .paused; paused = true }
    func setNone()   { status = .none;   paused = false }
    

    // 起点色の参照（WordCardPageへ）
    func variantIndex(for pos: PartOfSpeech) -> Int {
        switch pos {
        case .noun: return variantNoun
        case .adj: return variantAdj
        case .verb: return variantVerb
        case .adv: return variantAdv
        case .others: return variantOthers
        }
    }

   
    // 履歴の上限（必要なら好きな件数に変えてOK）
    private let maxHistoryCount = 200

    // MARK: - 履歴保存
    
    func logImportedHomework(dateISO: String, pairRaw: Int) {
        guard let d = parseISO(dateISO) else { return }
        let p = PosPair(rawValue: pairRaw) ?? currentPair
        logNowIfNeeded(date: d, status: .active, pair: p, wordsCount: 24) // ここは運用に合わせて
    }
    
    private func parseISO(_ s: String) -> Date? {
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f1.date(from: s) { return d }

        let f2 = ISO8601DateFormatter()
        return f2.date(from: s)
    }

    private func logNow(_ now: Date = Date()) {
        logNowIfNeeded(date: now, status: status, pair: currentPair, wordsCount: 24)
    }
    
    private func logNowIfNeeded(date: Date,
                                status: HomeworkStatus,
                                pair: PosPair,
                                wordsCount: Int) {
        let cal = Calendar.current
        var list = history

        // 同日＋同ペアが既にあるなら「更新」して増殖させない
        if let i = list.firstIndex(where: { cal.isDate($0.date, inSameDayAs: date) && $0.pair == pair }) {
            list[i].date = date
            list[i].status = status
            list[i].wordsCount = wordsCount
        } else {
            list.insert(
                HomeworkEntry(date: date, status: status, pair: pair, wordsCount: wordsCount),
                at: 0
            )
        }

        // 降順（新しい順）に正規化
        list.sort { $0.date > $1.date }

        // 上限カット（君の変数名）
        if list.count > maxHistoryCount {
            list.removeLast(list.count - maxHistoryCount)
        }

        // 保存
        history = list
        historyRaw = Self.encode(list)
    }
    
    // 履歴を起動時に1回だけ整形（重複除去＋降順＋上限カット）
    private func sanitizeHistoryIfNeeded() {
        let cal = Calendar.current

        struct Key: Hashable {
            let day: Date
            let pair: PosPair
        }

        var dict: [Key: HomeworkEntry] = [:]

        for e in history {
            let key = Key(day: cal.startOfDay(for: e.date), pair: e.pair)

            // 同日+同ペアは「新しい方（dateが大きい方）」を残す
            if let old = dict[key] {
                if e.date > old.date { dict[key] = e }
            } else {
                dict[key] = e
            }
        }

        var list = Array(dict.values)
        list.sort { $0.date > $1.date }

        if list.count > maxHistoryCount {
            list.removeLast(list.count - maxHistoryCount)
        }

        history = list
        historyRaw = Self.encode(list)
    }
    
    private func saveHistory() {
        historyRaw = Self.encode(history)   // AppStorageに保存（＝UserDefaultsにも反映）
    }
    // MARK: - Import helper（外部から履歴を刻む用）
    func addImportedToHistory(payload: HomeworkExportPayload) {

        #if DEBUG
        print("[HW] addImportedToHistory called createdAt=\(payload.createdAt)")
        #endif

        // ✅ 履歴日付は「生徒が取り込んだ日」
        let now = Date()

        let p = PosPair(rawValue: payload.pair) ?? currentPair
        logNowIfNeeded(date: now, status: .active, pair: p, wordsCount: payload.totalCount)
    }
 
    func isAlreadyImported(payload: HomeworkExportPayload) -> Bool {
        // ✅ 取得済み集合で判定（複数OK）
        if importedIDs.contains(payload.id) { return true }

        // 旧方式の保険（残してある場合）
        if payload.id == lastImportedPayloadID { return true }

        return false
    }

    func markImported(payload: HomeworkExportPayload) {
        // ✅ 集合に追加して永続化
        var set = importedIDs
        set.insert(payload.id)
        importedIDs = set

        // 旧方式も一応更新（残しておくなら）
        lastImportedPayloadID = payload.id
    }
    
    private static func decode(_ raw: String) -> [HomeworkEntry] {
        (try? JSONDecoder().decode([HomeworkEntry].self, from: Data(raw.utf8))) ?? []
    }
    private static func encode(_ list: [HomeworkEntry]) -> String {
        let data = try? JSONEncoder().encode(list)
        return String(data: data ?? Data("[]".utf8), encoding: .utf8) ?? "[]"
    }
}

// MARK: - 宿題用デッキの取得
extension HomeworkState {

    // ✅ 外（WeeklySetView）から呼べるように public（= private外す）
    func requestRestoreFixedPackIfNeeded() {

        // すでにキャッシュがあるなら何もしない
        if !cachedHomework.isEmpty { return }

        // 多重呼び出し防止
        guard !restoreRequested else { return }
        restoreRequested = true

        // ✅ “いまの描画ターン”では更新しない（Publish警告を避ける）
        Task { @MainActor in
            await Task.yield()
            self.restoreFixedPackIfNeeded()
        }
    }

    private func restoreFixedPackIfNeeded() {
        if let payload = HomeworkPackStore.shared.load(
            cycleIndex: currentCycleIndex,
            pair: currentPair
        ) {
            // ここで cachedHomework が埋まる想定
            applyImportedPayload(payload)
        }
    }

    // ✅ 「固定パックがまだ無い」ケースでも、1回だけ作って保存→次回起動で復元されるようにする
    private func requestBuildFixedPackIfNeeded() {

        // すでにキャッシュがあるなら不要
        if !cachedHomework.isEmpty { return }

        // 多重実行防止
        guard !buildRequested else { return }
        buildRequested = true

        Task { @MainActor in
            await Task.yield()

            // buildOrLoadFixedPack が「無ければ作って保存」する想定
            let payload = HomeworkPackStore.shared.buildOrLoadFixedPack(
                hw: self,
                requiredCount: 10,
                totalCount: 24
            )

            // これで cachedHomework が埋まる想定
            applyImportedPayload(payload)
        }
    }

    func homeworkWords(for pos: PartOfSpeech) -> [WordCard] {

        // ✅ まず復元を試す（保存済みがあればここで復活する）
        requestRestoreFixedPackIfNeeded()

        // ✅ すでに今サイクルぶんが決まっていれば、それをそのまま返す（サイクル中は固定）
        if let cached = cachedHomework[pos], !cached.isEmpty {
            return cached
        }

        // ✅ 保存済みが無い場合は「作って保存」を1回だけ走らせる
        requestBuildFixedPackIfNeeded()

        // ✅ まだ埋まってない描画ターンは空で返す（@Published があるので後で埋まったら画面が更新される）
        return cachedHomework[pos] ?? []
    }

    // ✅ “今サイクル”のキャッシュを全部捨てる（確実に効く版）
    func clearCachedHomeworkAll() {
        cachedHomework.removeAll()
        restoreRequested = false
        buildRequested = false
    }
}


extension HomeworkState {

    func resetImportedIDs() {
        importedIDs = []
        lastImportedPayloadID = ""
    }
}

extension HomeworkState {

    /// 履歴1件（wordIDs）から WordCard を引き直す
    func cards(for entry: HomeworkEntry) -> [WordCard] {
        guard !entry.wordIDs.isEmpty else { return [] }

        // 4品詞ぶん全部から「ID→カード」の辞書を作って引く
        let allCards = PartOfSpeech.homeworkCases.flatMap { HomeworkStore.shared.list(for: $0) }
        let dict = Dictionary(uniqueKeysWithValues: allCards.map { ($0.id, $0) })

        return entry.wordIDs.compactMap { dict[$0] }
    }
}

extension HomeworkState {

    /// 取り込んだpayloadを「履歴」に1件追加する（wordIDs も可能な範囲で入れる）
    func recordImportedPayloadIfNeeded(_ payload: HomeworkExportPayload) {

        let pair = PosPair(rawValue: payload.pair) ?? currentPair

        // payload の各 item から「代表meaning」を作って、その StoredWord の id を探す
        let ids: [UUID] = payload.items.compactMap { item -> UUID? in
            guard let pos = PartOfSpeech(rawValue: item.pos) else { return nil }

            let meaning = (item.meanings.first ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !meaning.isEmpty else { return nil }

            return HomeworkStore.shared.storedWordID(pos: pos, word: item.word, meaning: meaning)
        }

        let entry = HomeworkEntry(
            id: UUID(),
            date: Date(),
            status: .active,          // ここは運用に合わせてOK（.noneでも可）
            pair: pair,
            wordsCount: payload.totalCount,
            wordIDs: ids
        )

        // ▼ ここは “あなたの HomeworkState の履歴配列名” に合わせて差し替え
        history.insert(entry, at: 0)

        // ▼ 保存メソッド名もあなたの実装に合わせて差し替え
        saveHistory()
    }
}
// MARK: - キャッシュ操作用 extension

extension HomeworkState {
    /// HomeworkStore から「キャッシュだけリセット」したいときに呼ぶ
    func resetCache() {
        cachedHomework.removeAll()
    }
}

// MARK: - HomeworkStateBridge
/// HomeworkStore から HomeworkState の一部プロパティへ安全にアクセスするための窓口
final class HomeworkStateBridge {

    /// 共有インスタンス（存在しない間は nil）
    static var shared: HomeworkStateBridge?

    /// 実体の HomeworkState（App 側の @StateObject）
    weak var state: HomeworkState?

    init(state: HomeworkState) {
        self.state = state
        HomeworkStateBridge.shared = self
    }

    // HomeworkStore.repairHomeworkSets() から呼ばれる API

    func resetCache() {
        state?.resetCache()
    }

    var variantNoun: Int {
        get { state?.variantNoun ?? 0 }
        set { state?.variantNoun = newValue }
    }

    var variantAdj: Int {
        get { state?.variantAdj ?? 0 }
        set { state?.variantAdj = newValue }
    }

    var variantVerb: Int {
        get { state?.variantVerb ?? 0 }
        set { state?.variantVerb = newValue }
    }

    var variantAdv: Int {
        get { state?.variantAdv ?? 0 }
        set { state?.variantAdv = newValue }
    }
}


// MARK: - Import payload → cache（宿題カードに落とし込む）
extension HomeworkState {

    /// 取り込んだ宿題JSONを「今サイクルの宿題カード」として反映する
    func applyImportedPayload(_ payload: HomeworkExportPayload) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.cachedHomework.removeAll()

            self.daysPerCycle = payload.daysPerCycle
            self.pairIndex = payload.pair
            self.cycleIndex = payload.cycleIndex
            self.baseDaysPerCycle = payload.daysPerCycle
            self.extensionWeeks = 0
            self.daysPerCycle = payload.daysPerCycle
            
            self.uiTick += 1

            // ✅ サイクル開始日は「取り込んだ日」にする（運用的に自然）
            // ※payload.createdAt は履歴表示などで別に使う
            self.cycleStartDate = Date()

            var byPos: [PartOfSpeech: [WordCard]] = [:]
            for it in payload.items {
                let pos = self.mapPOS(it.pos)
                let card = WordCard(pos: pos, word: it.word, meanings: it.meanings, examples: [])
                byPos[pos, default: []].append(card)
            }
            self.cachedHomework = byPos
        }
    }

    /// payload の pos 文字列を PartOfSpeech に寄せる
    private func mapPOS(_ raw: String) -> PartOfSpeech {
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "n", "noun": return .noun
        case "v", "verb": return .verb
        case "adj", "a", "adjective": return .adj
        case "adv", "adverb": return .adv
        default: return .others
        }
    }
}

#if DEBUG
extension HomeworkState {

    /// 履歴をまとめて置き換えて永続化（debug用）
    func debugReplaceHistory(_ list: [HomeworkEntry]) {
        history = list
        historyRaw = Self.encode(list)
    }

    /// 履歴を空にする（debug用）
    func debugClearHistory() {
        debugReplaceHistory([])
    }

    /// 宿題カードのキャッシュを空にする（debug用）
    func debugClearCachedHomeworkOnly() {
        cachedHomework.removeAll()
        restoreRequested = false
    }
}
#endif
