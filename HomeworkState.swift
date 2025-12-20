//
//  WordsForest
//
//  Created by Nami .T on 2025/09/15.
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
}
enum HomeworkStatus: String, Codable { case active, paused, none }
enum PosPair: Int, Codable { case nounAdj = 0, verbAdv = 1 }

struct HomeworkEntry: Identifiable, Codable {
    var id: UUID
    var date: Date
    var status: HomeworkStatus
    var pair: PosPair
    var wordsCount: Int
    
    init(pair: PosPair, wordsCount: Int = 24) {
        self.id = UUID()
        self.date = Date()
        self.status = .active          // ← ここは素直にactiveでOK
        self.pair = pair
        self.wordsCount = wordsCount
    }

    init(date: Date, status: HomeworkStatus, pair: PosPair, wordsCount: Int = 24) {
        self.id = UUID()
        self.date = date
        self.status = status
        self.pair = pair
        self.wordsCount = wordsCount
    }

    var statusIcon: String {
        switch status { case .active: return "🟩"; case .paused: return "⏸️"; case .none: return "⛔️" }
    }
    var pairLabel: String {
        switch pair { case .nounAdj: "名詞＋形容詞"; case .verbAdv: "動詞＋副詞" }
    }
    var titleLine: String { "\(statusIcon) 宿題：\(pairLabel)（\(wordsCount)語）" }
}

final class HomeworkState: ObservableObject {
    // 設定
    @AppStorage("hw_daysPerCycle") var daysPerCycle: Int = 7
    @AppStorage("hw_paused") var paused: Bool = false
    @AppStorage("hw_statusRaw") private var statusRaw: String = HomeworkStatus.active.rawValue
    // 取り込み
    @AppStorage("hw_lastImportedPayloadID") private var lastImportedPayloadID: String = ""
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
    
   
    // 🆕 今サイクル表示用のラベル
    var currentPairLabel: String {
        switch currentPair {
        case .nounAdj: return "名詞＋形容詞"
        case .verbAdv: return "動詞＋副詞"
        }
    }

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
    @AppStorage("hw_history_json") private var historyRaw: String = "[]"
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
    private let maxHistoryCount = 50

    // MARK: - 履歴保存
    private func logNow(_ now: Date = Date()) {
        var list = history

        // ① 新しいエントリを先頭に追加（最新が一番上）
        list.insert(
            HomeworkEntry(date: now, status: status, pair: currentPair),
            at: 0
        )

        // ② 上限を超えた分、末尾（＝古いエントリ）から削除
        if list.count > maxHistoryCount {
            let overflow = list.count - maxHistoryCount
            list.removeLast(overflow)
        }

        // ③ 保存
        history = list
        historyRaw = Self.encode(list)
    }
    
    // MARK: - Import helper（外部から履歴を刻む用）
    func logImportedHomework(dateISO: String, pairRaw: Int) {
        let d = ISO8601DateFormatter().date(from: dateISO) ?? Date()
        // payloadの pair を currentPair に反映するかは運用次第。ここでは “今の状態のまま刻む” が安全。
        logNow(d)
    }

    func addImportedToHistory(payload: HomeworkExportPayload) {
        let d = ISO8601DateFormatter().date(from: payload.createdAt) ?? Date()
        let p = PosPair(rawValue: payload.pair) ?? currentPair

        var list = history
        list.insert(
            HomeworkEntry(date: d,
                          status: .active,
                          pair: p,
                          wordsCount: payload.totalCount),
            at: 0
        )

        if list.count > maxHistoryCount {
            list.removeLast(list.count - maxHistoryCount)
        }

        history = list
        historyRaw = Self.encode(list)
    }
    
    func isAlreadyImported(payload: HomeworkExportPayload) -> Bool {
        // まずはIDで即判定（最強）
        if payload.id == lastImportedPayloadID { return true }

        // 保険：履歴にも同じIDを刻んでる場合だけ（任意）
        // 今のHomeworkEntryにidStringが無いなら、ここは無しでOK
        return false
    }

    func markImported(payload: HomeworkExportPayload) {
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
    func homeworkWords(for pos: PartOfSpeech) -> [WordCard] {

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
