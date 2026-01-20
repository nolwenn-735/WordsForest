//
//  HomeworkExport.swift
//  WordsForest
//
//  Created by Nami .T on 2025/12/15.
//

import Foundation

// MARK: - Export JSON Schema（配布用）

struct HomeworkExportExample: Codable, Hashable {
    var en: String
    var ja: String?
    var note: String?
}

struct HomeworkExportCard: Codable, Hashable {
    var pos: String          // "noun" "verb" "adj" "adv" "others"
    var word: String
    var meanings: [String]
    var example: HomeworkExportExample?
    var required: Bool       // 先生の印（生徒UIには出さない）
}

/// 1回ぶんの“配布パック”（中身JSON）
struct HomeworkExportPayload: Codable {
    var id: String                 // 例: "2025-12-14-words-cycle3-verbAdv"
    var createdAt: String          // ISO8601
    var pair: Int                  // PosPair.rawValue
    var cycleIndex: Int
    var daysPerCycle: Int
    var requiredCount: Int
    var totalCount: Int
    var items: [HomeworkExportCard]
}

// MARK: - Freeze store（確定セットをサイクル中固定で保持）

final class HomeworkPackStore {
    static let shared = HomeworkPackStore()

    private let keyPrefix = "hw_export_pack.v1."
    private let iso = ISO8601DateFormatter()

    private init() {}

    /// サイクルごとに固定キーを作る
    private func key(cycleIndex: Int, pair: PosPair) -> String {
        "\(keyPrefix)\(cycleIndex).\(pair.rawValue)"
    }

    func load(cycleIndex: Int, pair: PosPair) -> HomeworkExportPayload? {
        let k = key(cycleIndex: cycleIndex, pair: pair)
        guard let data = UserDefaults.standard.data(forKey: k) else { return nil }
        return try? JSONDecoder().decode(HomeworkExportPayload.self, from: data)
    }

    func save(_ payload: HomeworkExportPayload, cycleIndex: Int, pair: PosPair) {
        let k = key(cycleIndex: cycleIndex, pair: pair)
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: k)
        }
    }

    /// 先生だけが「作り直し」たいとき用（普段は触らない）
    func clear(cycleIndex: Int, pair: PosPair) {
        let k = key(cycleIndex: cycleIndex, pair: pair)
        UserDefaults.standard.removeObject(forKey: k)
    }

    /// 1) 必須10語 + 2) 抽選で残り を“確定”して返す（既に確定済ならそれを返す）
    func buildOrLoadFixedPack(
        hw: HomeworkState,
        requiredCount: Int = 10,
        totalCount: Int = 24
    ) -> HomeworkExportPayload {

        let cycle = hw.currentCycleIndex
        let pair = hw.currentPair

        if let existing = load(cycleIndex: cycle, pair: pair) {
            return existing
        }

        let now = Date()
        let createdAt = iso.string(from: now)

        // 対象品詞（2品詞）
        let parts = pair.parts

        // 候補（learned除外）
        func candidates(for pos: PartOfSpeech) -> [WordCard] {
            HomeworkStore.shared.list(for: pos)
                .filter { !HomeworkStore.shared.isLearned($0) }
        }

        let poolA = candidates(for: parts[0])
        let poolB = candidates(for: parts[1])
        let pool = poolA + poolB

        // required候補
        let requiredPool = pool.filter { HomeworkStore.shared.isRequired($0) }
        let nonRequiredPool = pool.filter { !HomeworkStore.shared.isRequired($0) }

        // 必須を先に確保（足りなければあるだけ）
        let reqTake = min(requiredCount, requiredPool.count)
        let pickedRequired = Array(requiredPool.shuffled().prefix(reqTake))

        // 残りを抽選
        let remain = max(0, totalCount - pickedRequired.count)
        let pickedRest = Array(nonRequiredPool.shuffled().prefix(remain))

        // word重複防止用の正規化（表記ゆれ・空白事故を吸収）
        func normWord(_ s: String) -> String {
            s.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
        }

        // 合体 → wordで重複しないように守る
        var seen = Set<String>()
        var final: [WordCard] = []

        for c in (pickedRequired + pickedRest) {
            let k = normWord(c.word)
            if seen.contains(k) { continue }
            seen.insert(k)
            final.append(c)
            if final.count >= totalCount { break }
        }

        // 足りない場合、poolから補充（最後の安全網）
        if final.count < totalCount {
            for c in pool.shuffled() {
                let k = normWord(c.word)
                if seen.contains(k) { continue }
                seen.insert(k)
                final.append(c)
                if final.count >= totalCount { break }
            }
        }

        // JSON化
        let items: [HomeworkExportCard] = final.map { c in

            // ✅ どの meaning の例文を詰めるかを安定化：先頭 meaning 優先
            let m0 = (c.meanings.first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

            let ex = ExampleStore.shared.firstExample(pos: c.pos, word: c.word, meaning: m0)
                ?? ExampleStore.shared.firstExample(pos: c.pos, word: c.word)

            let exPayload: HomeworkExportExample? = ex.map {
                HomeworkExportExample(en: $0.en, ja: $0.ja, note: $0.note)
            }

            return HomeworkExportCard(
                pos: c.pos.rawValue,
                word: c.word,
                meanings: c.meanings,
                example: exPayload,
                required: HomeworkStore.shared.isRequired(c)
            )
        }
        
        let id = "\(createdAt.prefix(10))-words-cycle\(cycle)-pair\(pair.rawValue)"

        let payload = HomeworkExportPayload(
            id: id,
            createdAt: createdAt,
            pair: pair.rawValue,
            cycleIndex: cycle,
            daysPerCycle: hw.daysPerCycle,
            requiredCount: requiredCount,
            totalCount: totalCount,
            items: items
        )

        save(payload, cycleIndex: cycle, pair: pair)
        return payload
    }
    /// JSON文字列を作る（GitHubに置ける形）
    func makePrettyJSONString(_ payload: HomeworkExportPayload) -> String {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        if #available(iOS 15.0, *) {
            enc.outputFormatting.insert(.withoutEscapingSlashes)
        }
        guard let data = try? enc.encode(payload) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

#if DEBUG
extension HomeworkPackStore {

    func clearAll() {
        let defaults = UserDefaults.standard
        let dict = defaults.dictionaryRepresentation()
        for (k, _) in dict where k.hasPrefix(keyPrefix) {
            defaults.removeObject(forKey: k)
        }
    }

    func debugClearAllPacks() {
        clearAll()
    }
}
#endif
// MARK: - Import（生徒端末でJSONを取り込む）

extension HomeworkPackStore {

    enum ImportError: Error, LocalizedError {
        case invalidPair(Int)

        var errorDescription: String? {
            switch self {
            case .invalidPair(let v):
                return "pair が不正です: \(v)"
            }
        }
    }

    /// 生徒が受け取ったJSON（HomeworkExportPayload）を取り込み、今サイクルの固定セットとして保存する
    func importHomeworkPayload(_ payload: HomeworkExportPayload, hw: HomeworkState) throws {

        guard let pair = PosPair(rawValue: payload.pair) else {
            throw ImportError.invalidPair(payload.pair)
        }

        // 取り込んだ回を、その回のキーに保存
        save(payload, cycleIndex: payload.cycleIndex, pair: pair)

        // 今見ている回にも保険で保存（必要なら残す）
        save(payload, cycleIndex: hw.currentCycleIndex, pair: hw.currentPair)

        // ✅ 追加：payload内の例文を ExampleStore に反映
        for item in payload.items {
            guard let ex = item.example else { continue }
            guard let pos = PartOfSpeech(rawValue: item.pos) else { continue }

            let meaning = (item.meanings.first ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if meaning.isEmpty { continue }

            ExampleStore.shared.saveExample(
                pos: pos,
                word: item.word,
                meaning: meaning,
                en: ex.en,
                ja: ex.ja,
                note: ex.note
            )
        }
        
        hw.recordImportedPayloadIfNeeded(payload)
        // ✅ ここが重要：カード（cachedHomework）へ落とし込み
        hw.applyImportedPayload(payload)
        
    }
}


