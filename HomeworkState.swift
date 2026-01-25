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
    @AppStorage("hw_paused") var paused: Bool = false
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
    
    // 🔹 今サイクルの宿題セット（品詞ごと）
     private var cachedHomework: [PartOfSpeech: [WordCard]] = [:]
    
    // restore の多重発火防止
    private var restoreRequested = false
    
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

    private let iso = ISO8601DateFormatter()
    private var cycleStartDate: Date {
        get { iso.date(from: cycleStartISO) ?? Date() }
        set { cycleStartISO = iso.string(from: newValue) }
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
    
    // 起動/HOME 表示時に呼ぶ
    func refresh(now: Date = Date()) {
        guard status != .none else { return }       // 宿題なし → 進めない
        guard !paused && status != .paused else { return } // ストップ中 → 進めない
        let elapsed = Calendar.current.dateComponents([.day], from: cycleStartDate, to: now).day ?? 0
        if elapsed >= daysPerCycle {
            advanceCycle(from: now)
        }
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

    // 操作系（ワンタップ）
    func setActive() { status = .active; paused = false }
    func setPaused() { status = .paused; paused = true }
    func setNone()   { status = .none;   paused = false }
    func extendOneWeek() { daysPerCycle = 14 } // “今回だけ”にしたければ advanceCycle() 時に 7 に戻す処理を追加

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

        guard let d = parseISO(payload.createdAt) else {
    #if DEBUG
            print("[HW] createdAt parse failed: \(payload.createdAt)")
    #endif
            return
        }

        let p = PosPair(rawValue: payload.pair) ?? currentPair
        logNowIfNeeded(date: d, status: .active, pair: p, wordsCount: payload.totalCount)
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

    /// 品詞ごとの宿題用デッキを返す
    /// - ポイント
    ///   - HomeworkStore にある単語だけを使う（learned は“出題履歴”とは切り離す）
    ///   - 1 サイクル中は cachedHomework に固定しておく
    ///   - 最大で weeklyQuota[pos] 語（デフォルト 12 語）
    
    // ✅ 外（WeeklySetView）から呼べるように private を外す
    func requestRestoreFixedPackIfNeeded() {

        // すでにキャッシュがあるなら何もしない
        if !cachedHomework.isEmpty { return }

        // 多重呼び出し防止
        guard !restoreRequested else { return }
        restoreRequested = true

        // ✅ “いまの描画ターン”では更新しない（Publish警告を避ける）
        Task { @MainActor in
            await Task.yield()
            self.restoreFixedPackIfNeeded()   // ← cachedHomework を更新してOK
        }
    }
    
    private func restoreFixedPackIfNeeded() {
        if let payload = HomeworkPackStore.shared.load(
            cycleIndex: currentCycleIndex,
            pair: currentPair
        ) {
            applyImportedPayload(payload)
        }
    }
    
    func homeworkWords(for pos: PartOfSpeech) -> [WordCard] {

        requestRestoreFixedPackIfNeeded()
        
        // すでに今サイクルぶんが決まっていれば、それをそのまま返す
        if let cached = cachedHomework[pos], !cached.isEmpty {
            return cached
        }

        // この品詞の目標数（デフォルト 12）
        let quota = weeklyQuota[pos] ?? 12

        // HomeworkStore から、その品詞のカード一覧を取得
        let allCards = HomeworkStore.shared.list(for: pos)

        // 単語が 0 のときの安全策
        guard !allCards.isEmpty else {
            cachedHomework[pos] = []
            return []
        }

        let chosen: [WordCard]

        if allCards.count <= quota {
            // 単語が少ないときは全部
            chosen = allCards
        } else {
            // 🔹ポイント：アルファベット順の「窓」ではなく、
            //   ランダムに並べ替えて先頭から quota だけ取る
            chosen = Array(allCards.shuffled().prefix(quota))
        }

        // 今サイクルのキャッシュとして保持（サイクル中は固定）
        cachedHomework[pos] = chosen
        return chosen
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

            // ✅ サイクル開始日を「取り込み日」ではなく「先生の書き出し日」に寄せる
            if let d = self.parseISO(payload.createdAt) {
                self.cycleStartDate = d
            } else {
                self.cycleStartDate = Date() // パース失敗時の保険
            }

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
