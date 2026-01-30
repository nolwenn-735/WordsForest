//
//  HomeworkExport.swift
//  WordsForest
//
//  Created by Nami .T on 2025/12/15.
//
// HomeworkExport.swift 2026/01/30複数例文対応版

import Foundation

// =======================================================
// MARK: - Export JSON Schema（配布用）
// =======================================================

struct HomeworkExportExample: Codable, Hashable {
    var en: String
    var ja: String?
    var note: String?
}

struct HomeworkExportExampleByMeaning: Codable, Hashable {
    var meaning: String
    var en: String
    var ja: String?
    var note: String?
}

struct HomeworkExportCard: Codable, Hashable {
    var pos: String          // "noun" "verb" "adj" "adv" "others"
    var word: String
    var meanings: [String]
    var required: Bool       // 先生側の印（生徒UIには出さない想定）

    // v1互換（任意）
    var example: HomeworkExportExample?

    // ✅ v2本命：meaningごとの例文（キーが無い古いJSONでもデコードできるようデフォルト空配列）
    var examplesByMeaning: [HomeworkExportExampleByMeaning] = []
}

struct HomeworkExportPayload: Codable {
    var schemaVersion: Int        // 例: 2
    var senderHwID: String        // 先生端末ID（文字列でOK）
    var id: String
    var createdAt: String
    var pair: Int                 // PosPair.rawValue
    var cycleIndex: Int
    var daysPerCycle: Int
    var requiredCount: Int
    var totalCount: Int
    var items: [HomeworkExportCard]
}

// =======================================================
// MARK: - Freeze store（確定セットをサイクル中固定で保持）
// =======================================================

final class HomeworkPackStore {
    static let shared = HomeworkPackStore()

    private let keyPrefix = "hw_export_pack.v1."
    private let iso = ISO8601DateFormatter()

    private init() {}

    // =======================================================
    // MARK: Required order from HomeworkSetEditorView
    // =======================================================

    /// HomeworkSetEditorView が UserDefaults に保存した required の並びを読むための DTO
    /// ※ RequiredItem 型に依存しない（スコープ問題を回避）
    private struct RequiredItemDTO: Decodable {
        let posRaw: String
        let word: String
        let meaning: String

        enum CodingKeys: String, CodingKey {
            case posRaw
            case pos       // 互換用（昔 pos で保存されてた場合）
            case word
            case meaning
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)

            self.posRaw =
                (try? c.decode(String.self, forKey: .posRaw)) ??
                (try? c.decode(String.self, forKey: .pos)) ??
                ""

            self.word = (try? c.decode(String.self, forKey: .word)) ?? ""
            self.meaning = (try? c.decode(String.self, forKey: .meaning)) ?? ""
        }
    }

    private func orderKeyA(posA: PartOfSpeech, posB: PartOfSpeech) -> String {
        "required_order_v1_\(posA.rawValue)_\(posB.rawValue)_A"
    }
    private func orderKeyB(posA: PartOfSpeech, posB: PartOfSpeech) -> String {
        "required_order_v1_\(posA.rawValue)_\(posB.rawValue)_B"
    }

    private func loadRequiredOrder(posA: PartOfSpeech, posB: PartOfSpeech) -> (a: [RequiredItemDTO], b: [RequiredItemDTO]) {
        func loadArray(key: String) -> [RequiredItemDTO] {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let arr = try? JSONDecoder().decode([RequiredItemDTO].self, from: data)
            else { return [] }
            return arr
        }

        return (
            loadArray(key: orderKeyA(posA: posA, posB: posB)),
            loadArray(key: orderKeyB(posA: posA, posB: posB))
        )
    }

    // =======================================================
    // MARK: Saved pack I/O
    // =======================================================

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

    // =======================================================
    // MARK: Build fixed pack
    // =======================================================

    /// 1) 必須10語（先生が並べた順） + 2) 残り補充 を“確定”して返す（既に確定済ならそれを返す）
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
        let posA = parts[0]
        let posB = parts[1]

        // 候補（learned除外）
        func candidates(for pos: PartOfSpeech) -> [WordCard] {
            HomeworkStore.shared.list(for: pos)
                .filter { !HomeworkStore.shared.isLearned($0) }
        }

        let poolA = candidates(for: posA)
        let poolB = candidates(for: posB)

        // 先生が並べた required の順番を読む（posごと）
        let order = loadRequiredOrder(posA: posA, posB: posB)
        let requiredOrderA = order.a.filter { $0.posRaw == posA.rawValue }
        let requiredOrderB = order.b.filter { $0.posRaw == posB.rawValue }

        // WordCard と RequiredItemDTO の一致判定（word + 先頭meaning）
        func isSameCard(_ c: WordCard, _ r: RequiredItemDTO) -> Bool {
            let w1 = c.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let w2 = r.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let m1 = (c.meanings.first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let m2 = r.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
            return (w1 == w2 && m1 == m2)
        }

        // 目標：合計 requiredCount を A/B に割り振り
        let targetReqA = requiredCount / 2
        let targetReqB = requiredCount - targetReqA

        // ① 保存された順で required を拾う
        var pickedReqA: [WordCard] = requiredOrderA.compactMap { r in
            poolA.first(where: { isSameCard($0, r) })
        }
        var pickedReqB: [WordCard] = requiredOrderB.compactMap { r in
            poolB.first(where: { isSameCard($0, r) })
        }

        // ② 足りない場合の保険：requiredフラグから補充（順序は安定ソート）
        func stableSort(_ cards: [WordCard]) -> [WordCard] {
            cards.sorted { $0.word.lowercased() < $1.word.lowercased() }
        }

        if pickedReqA.count < targetReqA {
            let extra = stableSort(poolA.filter { HomeworkStore.shared.isRequired($0) })
                .filter { c in !pickedReqA.contains(where: { $0.id == c.id }) }
            pickedReqA.append(contentsOf: extra.prefix(targetReqA - pickedReqA.count))
        }
        if pickedReqB.count < targetReqB {
            let extra = stableSort(poolB.filter { HomeworkStore.shared.isRequired($0) })
                .filter { c in !pickedReqB.contains(where: { $0.id == c.id }) }
            pickedReqB.append(contentsOf: extra.prefix(targetReqB - pickedReqB.count))
        }

        pickedReqA = Array(pickedReqA.prefix(targetReqA))
        pickedReqB = Array(pickedReqB.prefix(targetReqB))

        // ここから残り補充：各品詞 12語ずつを目標（totalCount=24想定）
        let targetPerPos = max(1, totalCount / 2)

        func normWord(_ s: String) -> String {
            s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        // グローバル重複防止（A/Bをまたいでも同一wordを避ける）
        var seen = Set<String>()

        func buildSide(posPool: [WordCard], requiredPicked: [WordCard]) -> [WordCard] {
            var result: [WordCard] = []
            var localSeen = Set<String>()

            // required を順に
            for c in requiredPicked {
                let k = normWord(c.word)
                if seen.contains(k) || localSeen.contains(k) { continue }
                seen.insert(k)
                localSeen.insert(k)
                result.append(c)
            }

            // 追加候補：まず nonRequired を優先（安定ソート）
            let nonReq = stableSort(posPool.filter { !HomeworkStore.shared.isRequired($0) })
            let reqRest = stableSort(posPool.filter { HomeworkStore.shared.isRequired($0) })

            func appendFrom(_ list: [WordCard]) {
                for c in list {
                    if result.count >= targetPerPos { break }
                    let k = normWord(c.word)
                    if seen.contains(k) || localSeen.contains(k) { continue }
                    seen.insert(k)
                    localSeen.insert(k)
                    result.append(c)
                }
            }

            appendFrom(nonReq)
            appendFrom(reqRest)

            return result
        }

        let sideA = buildSide(posPool: poolA, requiredPicked: pickedReqA)
        let sideB = buildSide(posPool: poolB, requiredPicked: pickedReqB)

        // A→B の順で最終デッキ
        var final: [WordCard] = sideA + sideB

        // まだ足りない場合：pool全体から最後の安全網（安定ソート）
        if final.count < totalCount {
            let poolAll = stableSort(poolA + poolB)
            for c in poolAll {
                if final.count >= totalCount { break }
                let k = normWord(c.word)
                if seen.contains(k) { continue }
                seen.insert(k)
                final.append(c)
            }
        }

        // totalCount を超えていたら切る（念のため）
        if final.count > totalCount {
            final = Array(final.prefix(totalCount))
        }

        // JSON化
        let items: [HomeworkExportCard] = final.map { c in
            // meanings（複数）それぞれに例文を付ける
            let examplesByMeaning: [HomeworkExportExampleByMeaning] = c.meanings.compactMap { meaning in
                let m = meaning.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !m.isEmpty else { return nil }

                // meaning指定を優先して取得
                let ex = ExampleStore.shared.firstExample(pos: c.pos, word: c.word, meaning: m)
                guard let ex else { return nil }

                return HomeworkExportExampleByMeaning(
                    meaning: m,
                    en: ex.en,
                    ja: ex.ja,
                    note: ex.note
                )
            }

            // v1互換：代表例文を1つだけ入れるなら先頭meaning
            let fallbackExample: HomeworkExportExample? = {
                let m0 = (c.meanings.first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !m0.isEmpty,
                      let ex0 = ExampleStore.shared.firstExample(pos: c.pos, word: c.word, meaning: m0)
                else { return nil }
                return HomeworkExportExample(en: ex0.en, ja: ex0.ja, note: ex0.note)
            }()

            return HomeworkExportCard(
                pos: c.pos.rawValue,
                word: c.word,
                meanings: c.meanings,
                required: HomeworkStore.shared.isRequired(c),
                example: fallbackExample,
                examplesByMeaning: examplesByMeaning
            )
        }

        let id = "\(createdAt.prefix(10))-words-cycle\(cycle)-pair\(pair.rawValue)"

        let payload = HomeworkExportPayload(
            schemaVersion: 2,
            senderHwID: "teacher",
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

    /// JSON文字列を作る（GitHubに置ける形）→ 方針変更：GitHubには置かない
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

// =======================================================
// MARK: - Debug helpers
// =======================================================

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

// =======================================================
// MARK: - Import（生徒端末でJSONを取り込む）
// =======================================================

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
        if payload.cycleIndex == hw.currentCycleIndex && pair == hw.currentPair {
            save(payload, cycleIndex: hw.currentCycleIndex, pair: hw.currentPair)
        }

        // ✅ payload内の例文を ExampleStore に反映（v2優先、v1も救済）
        for item in payload.items {
            guard let pos = PartOfSpeech(rawValue: item.pos) else { continue }

            // --- v2: meaningごとの例文 ---
            if !item.examplesByMeaning.isEmpty {
                for ex in item.examplesByMeaning {
                    let meaning = ex.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !meaning.isEmpty else { continue }

                    ExampleStore.shared.saveExample(
                        pos: pos,
                        word: item.word,
                        meaning: meaning,
                        en: ex.en,
                        ja: ex.ja,
                        note: ex.note
                    )
                }
                continue
            }

            // --- v1救済: example が1個だけある場合 ---
            if let ex1 = item.example {
                let meaning = (item.meanings.first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !meaning.isEmpty else { continue }

                ExampleStore.shared.saveExample(
                    pos: pos,
                    word: item.word,
                    meaning: meaning,
                    en: ex1.en,
                    ja: ex1.ja,
                    note: ex1.note
                )
            }
        }

        // ✅ これは残す（生徒側の状態反映）
        hw.recordImportedPayloadIfNeeded(payload)
        hw.applyImportedPayload(payload)
    }
}
