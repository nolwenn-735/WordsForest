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

        let raw = UserDefaults.standard.string(forKey: DefaultsKeys.hwHistoryJSON) ?? "active"
        self.status = HomeworkStatus(rawValue: raw) ?? .active

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
    
    // 交互ローテ
    @AppStorage("hw_pairIndex") private var pairIndex: Int = 0
    var currentPair: PosPair { PosPair(rawValue: pairIndex) ?? .nounAdj }

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
        let raw = UserDefaults.standard.string(forKey: "hw_history_json") ?? "active"
        self.status = HomeworkStatus(rawValue: raw) ?? .active
        self.history = Self.decode(historyRaw)
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
        // ペア交互
        pairIndex = (pairIndex + 1) % 2
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
    

    private static func decode(_ raw: String) -> [HomeworkEntry] {
        (try? JSONDecoder().decode([HomeworkEntry].self, from: Data(raw.utf8))) ?? []
    }
    private static func encode(_ list: [HomeworkEntry]) -> String {
        let data = try? JSONEncoder().encode(list)
        return String(data: data ?? Data("[]".utf8), encoding: .utf8) ?? "[]"
    }
}
