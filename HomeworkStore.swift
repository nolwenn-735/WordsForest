//
//  File.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/24.
//
//  HomeworkStore.swift  （🍊Clément完全版・複数意味対応）💛　→ 12/7 Thinking🍊版→12/12 before5.2版→12/14jason対応化前→jason12/15対応→2026/01/20最初のmeaningsにID付版→01/24不規則動詞と宿題履歴→UUID方式に変更🌿🍊

//  HomeworkStore.swift


import Foundation

// 旧データ互換・移行用キー（過去の favorites/learned 保存形式）
struct WordKey: Hashable, Codable {
    var pos: PartOfSpeech
    var word: String
    var meaning: String
}

// 単語データ本体（保存対象）
struct StoredWord: Hashable, Codable {
    var id: UUID
    var word: String
    var meaning: String
    var pos: PartOfSpeech

    // 過去データ互換：id が無い古いJSONでも落ちない
    private enum CodingKeys: String, CodingKey { case id, word, meaning, pos }

    init(id: UUID = UUID(), word: String, meaning: String, pos: PartOfSpeech) {
        self.id = id
        self.word = word
        self.meaning = meaning
        self.pos = pos
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        self.word = try c.decode(String.self, forKey: .word)
        self.meaning = try c.decode(String.self, forKey: .meaning)
        self.pos = try c.decode(PartOfSpeech.self, forKey: .pos)
    }
}

// BundledWords.json 読み込み専用
private struct BundledWordRecord: Codable, Hashable {
    let word: String
    let meaning: String
    let pos: PartOfSpeech
}

final class HomeworkStore: ObservableObject {

    static let shared = HomeworkStore()

    // 保存対象
    @Published private(set) var words: [StoredWord] = []
    @Published private(set) var favoriteIDs: Set<UUID> = []
    @Published private(set) var learnedIDs: Set<UUID> = []
    
    private let key = "homework_v3"
    private let favKey = "favorites_v3"
    private let learnedKey = "learned_v3"
    
    private lazy var bundledWords: [BundledWordRecord] = {
        guard let url = Bundle.main.url(
            forResource: "BundledWords",
            withExtension: "json"
        ) else {
            print("❌ BundledWords.json not found")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(
                [BundledWordRecord].self,
                from: data
            )

            #if DEBUG
            print("📚 BundledWords loaded:", decoded.count)
            #endif

            return decoded
        } catch {
            print("❌ BundledWords.json decode failed:", error)
            return []
        }
    }()

    private init() {
        load()
        loadFavorites()
        loadLearned()
        loadRequired()
        migrateIfNeeded()
    }

    // MARK: - 保存 / 読み込み
    

    private func save() {
        let data = try? JSONEncoder().encode(words)
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private func load() {
        if let d = UserDefaults.standard.data(forKey: key),
           let arr = try? JSONDecoder().decode([StoredWord].self, from: d) {
            words = arr
        }
    }

    private func saveFavorites() {
        let data = try? JSONEncoder().encode(Array(favoriteIDs))
        UserDefaults.standard.set(data, forKey: favKey)
    }

    private func loadFavorites() {
        guard let d = UserDefaults.standard.data(forKey: favKey) else { return }

        // 新方式 [UUID]
        if let arr = try? JSONDecoder().decode([UUID].self, from: d) {
            favoriteIDs = Set(arr)
            return
        }

        // 旧方式 [WordKey] -> UUID に移行
        if let legacy = try? JSONDecoder().decode([WordKey].self, from: d) {
            favoriteIDs = ids(fromLegacyKeys: legacy)
            saveFavorites()
        }
    }

    private func saveLearned() {
        let data = try? JSONEncoder().encode(Array(learnedIDs))
        UserDefaults.standard.set(data, forKey: learnedKey)
    }

    private func loadLearned() {
        guard let d = UserDefaults.standard.data(forKey: learnedKey) else { return }

        if let arr = try? JSONDecoder().decode([UUID].self, from: d) {
            learnedIDs = Set(arr)
            return
        }

        if let legacy = try? JSONDecoder().decode([WordKey].self, from: d) {
            learnedIDs = ids(fromLegacyKeys: legacy)
            saveLearned()
        }
    }

    private func saveRequired() {
        let data = try? JSONEncoder().encode(Array(requiredIDs))
        UserDefaults.standard.set(data, forKey: requiredKey)
    }

    private func loadRequired() {
        guard let d = UserDefaults.standard.data(forKey: requiredKey) else { return }

        if let arr = try? JSONDecoder().decode([UUID].self, from: d) {
            requiredIDs = Set(arr)
            return
        }

        if let legacy = try? JSONDecoder().decode([WordKey].self, from: d) {
            requiredIDs = ids(fromLegacyKeys: legacy)
            saveRequired()
        }
    }
 
    private func migrateLegacyBeFormsToBaseVerbIfNeeded() {
        let beMeaning = "be動詞　〜である"

        func isLegacyBeForm(_ item: StoredWord) -> Bool {
            guard item.pos == .others else { return false }

            let word = norm(item.word)
            let meaning = normMeaning(item.meaning)

            switch word {
            case "is", "are":
                return meaning == "be動詞　〜である"

            case "was":
                return meaning == "be動詞　amとisの過去形"

            case "were":
                return meaning == "be動詞　areの過去形"

            default:
                return false
            }
        }

        let legacyWords = words.filter(isLegacyBeForm)

        guard !legacyWords.isEmpty else {
            return
        }

        let legacyIDs = Set(legacyWords.map(\.id))

        let wasFavorite =
            !favoriteIDs.isDisjoint(with: legacyIDs)

        let wasLearned =
            !learnedIDs.isDisjoint(with: legacyIDs)

        let wasRequired =
            !requiredIDs.isDisjoint(with: legacyIDs)

        let beID: UUID

        // すでに正式な be が存在する場合は、そのUUIDを使う
        if let existingBe = words.first(where: {
            $0.pos == .verb &&
            norm($0.word) == "be" &&
            normMeaning($0.meaning) == beMeaning
        }) {
            beID = existingBe.id

        } else {
            // 旧4カードのうち1枚のUUIDを be に引き継ぐ
            let preferredOrder = ["is", "are", "was", "were"]

            guard let source = preferredOrder.compactMap({ target in
                legacyWords.first {
                    norm($0.word) == target
                }
            }).first else {
                return
            }

            beID = source.id

            if let index = words.firstIndex(where: {
                $0.id == beID
            }) {
                words[index] = StoredWord(
                    id: beID,
                    word: "be",
                    meaning: beMeaning,
                    pos: .verb
                )
            }
        }

        // be に引き継いだ1件以外の旧4カードを整理
        words.removeAll {
            legacyIDs.contains($0.id) &&
            $0.id != beID
        }

        // 旧4カードについていた学習状態を be へまとめて引き継ぐ
        favoriteIDs.subtract(legacyIDs)
        learnedIDs.subtract(legacyIDs)
        requiredIDs.subtract(legacyIDs)

        if wasFavorite {
            favoriteIDs.insert(beID)
        }

        if wasLearned {
            learnedIDs.insert(beID)
        }

        if wasRequired {
            requiredIDs.insert(beID)
        }

        save()
        saveFavorites()
        saveLearned()
        saveRequired()
    }

    // MARK: - BundledWords meaning rename migration

    /// BundledWords側で meaning の表記を変更したとき、
    /// 旧StoredWordのUUIDを維持したまま新meaningへ移行する。
    ///
    /// すでに新meaning側のStoredWordが存在する場合も、
    /// 旧カードのUUIDを代表として残し、学習状態をまとめて引き継ぐ。
    @discardableResult
    private func migrateBundledMeaningRename(
        word: String,
        pos: PartOfSpeech,
        from oldMeaning: String,
        to newMeaning: String
    ) -> Bool {

        let normalizedWord = norm(word)
        let oldNormalized = normMeaning(oldMeaning)
        let newNormalized = normMeaning(newMeaning)

        guard let oldItem = words.first(where: {
            $0.pos == pos &&
            norm($0.word) == normalizedWord &&
            normMeaning($0.meaning) == oldNormalized
        }) else {
            return false
        }

        let oldID = oldItem.id

        // すでに新meaning側が追加済みの場合、
        // 新しいUUIDを消して旧UUIDへ状態を集約する。
        if let newItem = words.first(where: {
            $0.pos == pos &&
            norm($0.word) == normalizedWord &&
            normMeaning($0.meaning) == newNormalized &&
            $0.id != oldID
        }) {

            let newID = newItem.id

            if favoriteIDs.remove(newID) != nil {
                favoriteIDs.insert(oldID)
            }

            if learnedIDs.remove(newID) != nil {
                learnedIDs.insert(oldID)
            }

            if requiredIDs.remove(newID) != nil {
                requiredIDs.insert(oldID)
            }

            words.removeAll {
                $0.id == newID
            }
        }

        // 旧UUIDをそのまま使って正式な新meaningへ変更
        guard let oldIndex = words.firstIndex(where: {
            $0.id == oldID
        }) else {
            return false
        }

        words[oldIndex] = StoredWord(
            id: oldID,
            word: word,
            meaning: newMeaning,
            pos: pos
        )

    #if DEBUG
        print(
            "🔁 Bundled meaning migrated:",
            word,
            "[\(oldMeaning)] → [\(newMeaning)]"
        )
    #endif

        return true
    }
 
    // MARK: - BundledWords duplicate meaning collapse migration

    /// BundledWords側で「別meaningではなく言い換え」と判断した旧meaningを、
    /// 正式meaningへ統合する。
    ///
    /// StoredWordのUUIDは削除せず残す。
    /// 同じmeaningになった複数StoredWordは list(for:) 側で1meaningにまとめられるため、
    /// 過去の宿題履歴IDを壊さず表示だけ1件にできる。
    @discardableResult
    private func collapseBundledMeaning(
        word: String,
        pos: PartOfSpeech,
        from oldMeaning: String,
        into canonicalMeaning: String
    ) -> Bool {

        let normalizedWord = norm(word)
        let oldNormalized = normMeaning(oldMeaning)
        let canonicalNormalized = normMeaning(canonicalMeaning)

        guard let oldIndex = words.firstIndex(where: {
            $0.pos == pos &&
            norm($0.word) == normalizedWord &&
            normMeaning($0.meaning) == oldNormalized
        }) else {
            return false
        }

        let oldID = words[oldIndex].id

        // 旧StoredWordのUUIDをそのまま保って、
        // meaningだけ正式meaningへ揃える。
        words[oldIndex] = StoredWord(
            id: oldID,
            word: word,
            meaning: canonicalMeaning,
            pos: pos
        )

        // 同じ正式meaningを持つStoredWordが複数存在しても、
        // UUIDは履歴互換のため残す。
        let matchingIDs = words
            .filter {
                $0.pos == pos &&
                norm($0.word) == normalizedWord &&
                normMeaning($0.meaning) == canonicalNormalized
            }
            .map(\.id)

        guard let representativeID = matchingIDs.first else {
            return true
        }

        let matchingIDSet = Set(matchingIDs)

        // My Collection / 覚えた / 必須 の状態は、
        // 実際に画面で代表になるIDへまとめる。
        let wasFavorite =
            !favoriteIDs.isDisjoint(with: matchingIDSet)

        let wasLearned =
            !learnedIDs.isDisjoint(with: matchingIDSet)

        let wasRequired =
            !requiredIDs.isDisjoint(with: matchingIDSet)

        favoriteIDs.subtract(matchingIDSet)
        learnedIDs.subtract(matchingIDSet)
        requiredIDs.subtract(matchingIDSet)

        if wasFavorite {
            favoriteIDs.insert(representativeID)
        }

        if wasLearned {
            learnedIDs.insert(representativeID)
        }

        if wasRequired {
            requiredIDs.insert(representativeID)
        }

    #if DEBUG
        print(
            "🧹 Bundled meaning collapsed:",
            word,
            "[\(oldMeaning)] → [\(canonicalMeaning)]"
        )
    #endif

        return true
    }
    
    private func migrateIfNeeded() {

        // ---------------------------------------------------------
        // 1. 旧 is / are / was / were → 正式な be へ移行
        // ---------------------------------------------------------

        migrateLegacyBeFormsToBaseVerbIfNeeded()


        // ---------------------------------------------------------
        // 2. BundledWords側で表記変更したmeaningを移行
        // ---------------------------------------------------------

        var renamedCount = 0

        if migrateBundledMeaningRename(
            word: "anyway",
            pos: .adv,
            from: "何でも",
            to: "とにかく／いずれにせよ"
        ) {
            renamedCount += 1
        }

        if migrateBundledMeaningRename(
            word: "project",
            pos: .noun,
            from: "課題研究",
            to: "企画／計画"
        ) {
            renamedCount += 1
        }

        if migrateBundledMeaningRename(
            word: "shine",
            pos: .verb,
            from: "照る",
            to: "（太陽などが）照る"
        ) {
            renamedCount += 1
        }

        if migrateBundledMeaningRename(
            word: "complimentary",
            pos: .adj,
            from: "褒める・好意的な",
            to: "好意的な／褒める内容の"
        ) {
            renamedCount += 1
        }

        if migrateBundledMeaningRename(
            word: "always",
            pos: .adv,
            from: "いつも",
            to: "いつも／必ず"
        ) {
            renamedCount += 1
        }

        if migrateBundledMeaningRename(
            word: "never",
            pos: .adv,
            from: "決して〜ない",
            to: "決して〜ない／一度も〜ない"
        ) {
            renamedCount += 1
        }

        if migrateBundledMeaningRename(
            word: "soon",
            pos: .adv,
            from: "すぐに",
            to: "もうすぐ／近いうちに"
        ) {
            renamedCount += 1
        }

        if migrateBundledMeaningRename(
            word: "later",
            pos: .adv,
            from: "あとで",
            to: "あとで／もっと遅く"
        ) {
            renamedCount += 1
        }

        if migrateBundledMeaningRename(
            word: "again",
            pos: .adv,
            from: "もう一度",
            to: "再び／もう一度"
        ) {
            renamedCount += 1
        }

        if migrateBundledMeaningRename(
            word: "very",
            pos: .adv,
            from: "とても",
            to: "とても／非常に"
        ) {
            renamedCount += 1
        }

        if migrateBundledMeaningRename(
            word: "nearly",
            pos: .adv,
            from: "ほとんど",
            to: "ほとんど／もう少しで"
        ) {
            renamedCount += 1
        }


        // ---------------------------------------------------------
        // 3. 「別meaningではなく言い換え」だった旧meaningを統合
        // ---------------------------------------------------------

        var collapsedCount = 0

        if collapseBundledMeaning(
            word: "disposable",
            pos: .adj,
            from: "使用後に処分する",
            into: "使い捨ての"
        ) {
            collapsedCount += 1
        }

        if collapseBundledMeaning(
            word: "whole",
            pos: .adj,
            from: "ずっと",
            into: "全体の・全部の"
        ) {
            collapsedCount += 1
        }

        // ---------------------------------------------------------
        // 4. BundledWords.json の不足meaningを追加
        //
        // word + meaning + pos の完全一致で判定する。
        // 同じwordに複数meaningがあっても、
        // それぞれ独立したStoredWordとして追加される。
        // ---------------------------------------------------------

        var knownKeys = Set(
            words.map {
                WordKey(
                    pos: $0.pos,
                    word: norm($0.word),
                    meaning: normMeaning($0.meaning)
                )
            }
        )

        var addedCount = 0

        for bundled in bundledWords {

            let word = bundled.word
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let meaning = bundled.meaning
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !word.isEmpty, !meaning.isEmpty else {
                continue
            }

            let bundledKey = WordKey(
                pos: bundled.pos,
                word: norm(word),
                meaning: normMeaning(meaning)
            )

            guard knownKeys.insert(bundledKey).inserted else {
                continue
            }

            words.append(
                StoredWord(
                    word: word,
                    meaning: meaning,
                    pos: bundled.pos
                )
            )

            addedCount += 1

    #if DEBUG
            print(
                "🌱 Bundled meaning added:",
                bundled.pos.rawValue,
                word,
                "[\(meaning)]"
            )
    #endif
        }


        // ---------------------------------------------------------
        // 5. 変更があったときだけ保存
        // ---------------------------------------------------------

        if renamedCount > 0 ||
            collapsedCount > 0 ||
            addedCount > 0 {

            save()
            saveFavorites()
            saveLearned()
            saveRequired()

            NotificationCenter.default.post(
                name: .storeDidChange,
                object: nil
            )

            NotificationCenter.default.post(
                name: .favoritesDidChange,
                object: nil
            )

            NotificationCenter.default.post(
                name: .learnedDidChange,
                object: nil
            )
        }


    #if DEBUG
        print(
            "📚 BundledWords sync:",
            bundledWords.count,
            "bundled /",
            renamedCount,
            "renamed /",
            collapsedCount,
            "collapsed /",
            addedCount,
            "added"
        )
    #endif
    }
    
    private func ensureStored(_ c: WordCard) {
        // meanings の先頭だけ store へ（いまの WordKey 方針と揃える）
        let meaning = c.meanings.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !meaning.isEmpty else { return }

        // すでに存在するなら何もしない
        if exists(word: c.word, meaning: meaning, pos: c.pos) { return }

        // 追加（通知も飛ぶ）
        _ = add(word: c.word, meaning: meaning, pos: c.pos)
    }
    
    // 宿題で取り込んだ payload を「本体ストア(words)」へ upsert
    func mergeImportedPayload(_ payload: HomeworkExportPayload) {
        for it in payload.items {
            // pos（Int）→ PartOfSpeech
            guard let pos = PartOfSpeech(rawValue: it.pos) else { continue }

            // meanings の先頭だけ store へ（いまの WordKey 方針と揃える）
            let meaning = it.meanings.first?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !meaning.isEmpty else { continue }

            // すでに存在するなら何もしない
            if exists(word: it.word, meaning: meaning, pos: pos) { continue }

            // 追加（add() 側で save + 通知が飛ぶ想定）
            _ = add(word: it.word, meaning: meaning, pos: pos)
        }
    }
    
    // MARK: - WordKey 生成

    func key(for c: WordCard) -> WordKey {
        // WordCard は meanings:[String] → 最初の意味だけキーに使う
        WordKey(
            pos: c.pos,
            word: norm(c.word),
            meaning: normMeaning(c.meanings.first ?? "")
        )
    }

    func key(for s: StoredWord) -> WordKey {
        WordKey(
            pos: s.pos,
            word: norm(s.word),
            meaning: normMeaning(s.meaning)
        )
    }

    private func norm(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func normMeaning(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// BundledWords.json に収録されたプリインストール内容を含むカードか判定する
    ///
    /// WordCard は同じ品詞・同じ単語の複数meaningを1枚にまとめているため、
    /// 単語だけではなく、BundledWords.json に収録されているmeaningとの一致も確認する。
    func isBundledCard(_ card: WordCard) -> Bool {
        let targetWord = norm(card.word)

        let cardMeanings = Set(
            card.meanings
                .map { normMeaning($0) }
                .filter { !$0.isEmpty }
        )

        guard !cardMeanings.isEmpty else {
            return false
        }

        let bundledMeanings = Set(
            bundledWords
                .filter {
                    $0.pos == card.pos &&
                    norm($0.word) == targetWord
                }
                .map {
                    normMeaning($0.meaning)
                }
                .filter {
                    !$0.isEmpty
                }
        )

        return !cardMeanings.isDisjoint(with: bundledMeanings)
    }
    

 
   // HomeworkStoreの半角debug用func
    
    func normalizeStoredMeaningsOnce() {
        var seen = Set<WordKey>()
        var newWords: [StoredWord] = []

        for s in words {
            let fixed = StoredWord(
                id: s.id, // ✅ ここが超大事：履歴のwordIDsを壊さない
                word: s.word,
                meaning: normMeaning(s.meaning),
                pos: s.pos
            )

            let k = WordKey(
                pos: fixed.pos,
                word: norm(fixed.word),
                meaning: normMeaning(fixed.meaning)
            )

            if !seen.contains(k) {
                newWords.append(fixed)
                seen.insert(k)
            }
        }

        words = newWords
        save()
        NotificationCenter.default.post(name: .storeDidChange, object: nil)
    }
    
    // MARK: - CRUD（追加・削除・取得）

    /// 追加（完全一致 word + meaning + pos を弾く）
    @discardableResult
    func add(word: String, meaning: String, pos: PartOfSpeech) -> Bool {
        if exists(word: word, meaning: meaning, pos: pos) { return false }

        words.append(StoredWord(word: word, meaning: meaning, pos: pos))
        save()
        NotificationCenter.default.post(name: .storeDidChange, object: nil)
        return true
    }

    func exists(word: String, meaning: String, pos: PartOfSpeech) -> Bool {
        let w = norm(word)
        let m = normMeaning(meaning)

        return words.contains(where: {
            $0.pos == pos &&
            norm($0.word) == w &&
            normMeaning($0.meaning) == m
        })
    }

    func delete(_ card: WordCard) {
        // プリインストール原本は削除させない
        guard !isBundledCard(card) else {
            print("🛡️ Bundled card deletion blocked:", card.word)
            return
        }

        // WordCard → StoredWord の1件だけ削除
        let k = key(for: card)

        if let i = words.firstIndex(where: {
            $0.pos == k.pos &&
            norm($0.word) == k.word &&
            normMeaning($0.meaning) == k.meaning
        }) {
            words.remove(at: i)
            save()
            NotificationCenter.default.post(name: .storeDidChange, object: nil)
        }
    }
    
    // 🦌 その他品詞：追加したmeaning 1件だけを削除
    // 最初に登録されたmeaning（代表ID）は保護する
    @discardableResult
    func deleteOtherMeaning(word: String, meaning: String) -> Bool {
        let w = norm(word)
        let m = normMeaning(meaning)

        let group = words.filter {
            $0.pos == .others &&
            norm($0.word) == w
        }

        // 最後の1件は消さない
        guard group.count > 1 else { return false }

        // 最初に登録されたmeaning = 代表ID は保護
        guard let representativeID = group.first?.id else { return false }

        guard let index = words.firstIndex(where: {
            $0.pos == .others &&
            norm($0.word) == w &&
            normMeaning($0.meaning) == m
        }) else {
            return false
        }

        let deletedID = words[index].id

        // 代表meaningは削除しない
        guard deletedID != representativeID else {
            return false
        }

        words.remove(at: index)

        // 念のためUUIDの残骸も掃除
        favoriteIDs.remove(deletedID)
        learnedIDs.remove(deletedID)
        requiredIDs.remove(deletedID)

        save()
        saveFavorites()
        saveLearned()
        saveRequired()

        NotificationCenter.default.post(name: .storeDidChange, object: nil)
        NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
        NotificationCenter.default.post(name: .learnedDidChange, object: nil)

        return true
    }

//03/31追加部分
    func card(word: String, meanings: [String], pos: PartOfSpeech) -> WordCard? {
        let w = norm(word)
        let normalizedMeanings = meanings
            .map { normMeaning($0) }
            .filter { !$0.isEmpty }

        guard !normalizedMeanings.isEmpty else { return nil }

        let matched = words.filter {
            $0.pos == pos &&
            norm($0.word) == w &&
            normalizedMeanings.contains(normMeaning($0.meaning))
        }

        guard !matched.isEmpty else { return nil }

        // 代表IDは最初の1件を使う
        let representative = matched[0]

        // storeにある意味順を保ちつつ重複除去
        var merged: [String] = []
        for item in matched {
            let m = item.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
            if !m.isEmpty && !merged.contains(m) {
                merged.append(m)
            }
        }

        return WordCard(
            id: representative.id,
            pos: pos,
            word: representative.word,
            meanings: merged,
            examples: []
        )
    }
    
    // MARK: - Favorite / Learned (UUID-based)

    func isFavorite(_ c: WordCard) -> Bool {
        favoriteIDs.contains(c.id)
    }

    func setFavorite(_ c: WordCard, enabled: Bool) {
        ensureStored(c)
        if enabled { favoriteIDs.insert(c.id) }
        else { favoriteIDs.remove(c.id) }
        saveFavorites()
        NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
    }

    func toggleFavorite(_ c: WordCard) {
        setFavorite(c, enabled: !isFavorite(c))
    }

    func isLearned(_ c: WordCard) -> Bool {
        learnedIDs.contains(c.id)
    }

    func setLearned(_ c: WordCard, enabled: Bool) {
        ensureStored(c)
        if enabled { learnedIDs.insert(c.id) }
        else { learnedIDs.remove(c.id) }
        saveLearned()
        NotificationCenter.default.post(name: .learnedDidChange, object: nil)
    }

    func toggleLearned(_ c: WordCard) {
        setLearned(c, enabled: !isLearned(c))
    }

    func isRequired(_ c: WordCard) -> Bool {
        requiredIDs.contains(c.id)
    }

    func setRequired(_ c: WordCard, enabled: Bool) {
        ensureStored(c)
        if enabled { requiredIDs.insert(c.id) }
        else { requiredIDs.remove(c.id) }
        saveRequired()
        NotificationCenter.default.post(name: .storeDidChange, object: nil)
    }

    func toggleRequired(_ c: WordCard) {
        setRequired(c, enabled: !isRequired(c))
    }
    
    // MARK: - WordCard 一覧（画面用）

    /// 画面表示用 WordCard 一覧を（posごとに）作る
    func list(for pos: PartOfSpeech) -> [WordCard] {

        // pos で絞る
        let filtered = words.filter { $0.pos == pos }

        // 単語ごとに grouped（複数意味を束ねる）
        let grouped = Dictionary(grouping: filtered, by: { $0.word })

        // WordCard へ変換
        let cards: [WordCard] = grouped.values.compactMap { group in
            // meanings を正規化して確定
            var meanings: [String] = []
            var seenMeanings = Set<String>()

            for storedWord in group {
                let meaning = normMeaning(storedWord.meaning)

                if !meaning.isEmpty, seenMeanings.insert(meaning).inserted {
                    meanings.append(meaning)
                }
            }

            guard !meanings.isEmpty else { return nil }

            // 🦌 その他品詞だけは、最初に登録されたStoredWordを代表IDにする
            // → meaningを追加しても代表IDが変わりにくい
            let first: StoredWord

            if pos == .others {
                guard let originalFirst = group.first else { return nil }
                first = originalFirst
            } else {
                // 主要4品詞は今までの代表IDルールを維持
                guard
                    let firstMeaning = meanings.sorted().first,
                    let existingFirst = group.first(where: {
                        normMeaning($0.meaning) == firstMeaning
                    })
                else {
                    return nil
                }

                first = existingFirst
            }
            
            return WordCard(
                id: first.id,                 // ✅ ここが重要：代表IDにする（安定）
                pos: first.pos,
                word: first.word,
                meanings: meanings,
                examples: []                  // 例文は ExampleStore 側で合成する前提でOK
            )
        }
        
        // MARK: - History restore helpers（HomeworkEntry.wordIDs 用）

            /// 保存済みIDから StoredWord を引く（代表ID用）
            func storedWord(for id: UUID) -> StoredWord? {
                words.first { $0.id == id }
            }

            /// 履歴用：代表StoredWordを起点に、同じ(pos, word)を集めて WordCard 1枚に再構成
            func mergedCard(for representative: StoredWord) -> WordCard {
                let same = words.filter { $0.pos == representative.pos && $0.word == representative.word }

                var mergedMeanings: [String] = []
                var seenMeanings = Set<String>()

                for storedWord in same {
                    let meaning = normMeaning(storedWord.meaning)

                    if !meaning.isEmpty, seenMeanings.insert(meaning).inserted {
                        mergedMeanings.append(meaning)
                    }
                }

                return WordCard(
                    id: representative.id,          // ✅ 履歴の代表IDを維持
                    pos: representative.pos,
                    word: representative.word,
                    meanings: mergedMeanings,
                    examples: []                    // 例文は ExampleStore 側で合成する前提なら空でOK
                )
            }

            /// 履歴用：wordIDs（24個）から復元（順序はIDs優先・重複は除外）
            func cards(for ids: [UUID]) -> [WordCard] {
                var seen = Set<UUID>()
                var result: [WordCard] = []

                for id in ids {
                    guard !seen.contains(id) else { continue }
                    guard let rep = storedWord(for: id) else { continue }

                    seen.insert(id)
                    result.append(mergedCard(for: rep))
                }
                return result
            }
                        
        return cards.sorted { $0.word < $1.word }
    }
    
    // MARK: - Legacy WordKey -> UUID migration helpers

    private func id(forLegacyKey k: WordKey) -> UUID? {
        words.first {
            $0.pos == k.pos &&
            $0.word == k.word &&
            normMeaning($0.meaning) == normMeaning(k.meaning)
        }?.id
    }

    private func ids(fromLegacyKeys keys: [WordKey]) -> Set<UUID> {
        Set(keys.compactMap { id(forLegacyKey: $0) })
    }
    // MARK: - Favorites / Learned の補助API (HomePage用)

    // ===== ここ：favorites / learned の下あたりに追加 =====
    @Published private(set) var requiredIDs: Set<UUID> = []
    private let requiredKey = "required_v1"
    
    // お気に入り数（badge用）
    var favoritesCount: Int {
        favoriteIDs.count
    }

    var learnedCount: Int {
        learnedIDs.count
    }

  
    // MARK: - autofill（既存を崩さず追加）

    func autofill(for pos: PartOfSpeech, target: Int = 24) {
        guard pos != .others else { return }

        let current = list(for: pos)
        guard current.count < target else { return }

        let bank = bundledWords.filter { $0.pos == pos }

        var existing = Set(
            current.map { norm($0.word) }
        )

        var count = current.count

        for record in bank where count < target {
            let normalizedWord = norm(record.word)

            // 同じ単語の別meaningがBundledWordsに複数あっても、
            // autofillでは1語として数える。
            guard existing.insert(normalizedWord).inserted else {
                continue
            }

            add(
                word: record.word,
                meaning: record.meaning,
                pos: record.pos
            )

            count += 1
        }
    }

    // MARK: - Lookup (History restore)

    /// (pos, word, meaning) から StoredWord の id を探す（見つからなければ nil）
    func storedWordID(pos: PartOfSpeech, word: String, meaning: String) -> UUID? {
        let w = normWord(word)
        let m = normMeaning(meaning)

        return words.first { s in
            s.pos == pos &&
            normWord(s.word) == w &&
            normMeaning(s.meaning) == m
        }?.id
    }
    // MARK: - 既存チェック・更新（AddWordView 用）

    /// 同じ品詞・同じ単語で登録済みの「意味」一覧を返す
    func existingMeanings(for word: String, pos: PartOfSpeech) -> [String] {
        let w = norm(word)
        let list = words.filter { $0.pos == pos && norm($0.word) == w }
        return list.map { $0.meaning.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    /// 単語レベルでの存在チェック（意味は問わない）
    func exists(word: String, pos: PartOfSpeech) -> Bool {
        let w = norm(word)
        return words.contains {
            $0.pos == pos && norm($0.word) == w
        }
    }
}

// MARK: - WordCard update

extension HomeworkStore {

    /// 既存カードの更新
    /// プリインストール原本は変更しない
    func update(
        _ original: WordCard,
        word newWord: String,
        meaning newMeaning: String
    ) {
        guard !isBundledCard(original) else {
            print(
                "🛡️ Bundled card update blocked:",
                original.word
            )
            return
        }

        let oldKey = key(for: original)

        let trimmedMeaning = newMeaning
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if let idx = words.firstIndex(
            where: {
                key(for: $0) == oldKey
            }
        ) {
            let existingID = words[idx].id

            words[idx] = StoredWord(
                id: existingID,
                word: newWord,
                meaning: trimmedMeaning,
                pos: original.pos
            )
        } else {
            words.append(
                StoredWord(
                    word: newWord,
                    meaning: trimmedMeaning,
                    pos: original.pos
                )
            )
        }

        save()
        saveFavorites()
        saveLearned()

        NotificationCenter.default.post(
            name: .storeDidChange,
            object: nil
        )
    }
}

// MARK: - 通知名

extension Notification.Name {
    static let storeDidChange     = Notification.Name("storeDidChange")
    static let favoritesDidChange = Notification.Name("favoritesDidChange")
    static let learnedDidChange   = Notification.Name("learnedDidChange")
}

// MARK: - My Collection / 覚えたBOX 表示用 集計
extension HomeworkStore {

    // 共通で使う品詞一覧（noun / verb / adj / adv / others ぜんぶ）
    private var allCollectionPOS: [PartOfSpeech] {
        PartOfSpeech.collectionCases
    }
    
    // --- My Collection 用：ハート付きカードの一覧（品詞混在） ---
    var collectionFavorites: [WordCard] {
        allCollectionPOS
            .flatMap { pos in list(for: pos) }   // 各品詞の WordCard を全部つなげる
            .filter { isFavorite($0) }           // ハート付きだけ
            .sorted { $0.word < $1.word }        // 英単語でソート
    }

    // 品詞ごとに分けたお気に入り（必要ならセクション表示用）
    var collectionFavoritesByPos: [PartOfSpeech: [WordCard]] {
        var dict: [PartOfSpeech: [WordCard]] = [:]

        for pos in allCollectionPOS {
            let favs = list(for: pos)
                .filter { isFavorite($0) }
                .sorted { $0.word < $1.word }

            if !favs.isEmpty {
                dict[pos] = favs
            }
        }
        return dict
    }

    // My Collection バッジ用の総数
    var collectionFavoritesCount: Int {
        collectionFavorites.count
    }

    // --- 覚えたBOX 用：チェック付きカードの一覧（品詞混在） ---
    var collectionLearned: [WordCard] {
        allCollectionPOS
            .flatMap { pos in list(for: pos) }
            .filter { isLearned($0) }
            .sorted { $0.word < $1.word }
    }

    // 品詞ごとに分けた「覚えた」一覧
    var collectionLearnedByPos: [PartOfSpeech: [WordCard]] {
        var dict: [PartOfSpeech: [WordCard]] = [:]

        for pos in allCollectionPOS {
            let learned = list(for: pos)
                .filter { isLearned($0) }
                .sorted { $0.word < $1.word }

            if !learned.isEmpty {
                dict[pos] = learned
            }
        }
        return dict
    }

    // 覚えたBOX バッジ用の総数
    var collectionLearnedCount: Int {
        collectionLearned.count
    }

    // === 既存ビュー向けの「ラッパー」（古い API 名を残す） ===

    func favoriteList() -> [WordCard] {
        collectionFavorites
    }

    func favoriteListByPos() -> [PartOfSpeech: [WordCard]] {
        collectionFavoritesByPos
    }

    func learnedList() -> [WordCard] {
        collectionLearned
    }

    func learnedListByPos() -> [PartOfSpeech: [WordCard]] {
        collectionLearnedByPos
    }
}


// MARK: - Safe repair (Nolwenn gentle reset)
extension HomeworkStore {

    /// データ構造を壊さない「優しい宿題セット修復」
    func repairHomeworkSets() {

        // 1. HomeworkState 側のキャッシュをリセット
        if let hw = HomeworkStateBridge.shared {
            hw.resetCache()
        }

        // 2. 動物カラー variant を 0〜2 の範囲に補正
        func fix(_ value: inout Int) {
            if value < 0 || value >= 3 { value = 0 }
        }

        if let hw = HomeworkStateBridge.shared {
            var n = hw.variantNoun; fix(&n); hw.variantNoun = n
            var a = hw.variantAdj;  fix(&a); hw.variantAdj  = a
            var v = hw.variantVerb; fix(&v); hw.variantVerb = v
            var d = hw.variantAdv;  fix(&d); hw.variantAdv  = d
        }

        // 3. 宿題４品詞だけ autofill（others は対象外）
        for pos in PartOfSpeech.homeworkCases {   // [.noun, .verb, .adj, .adv]
            autofill(for: pos, target: 24)
        }

        // 4. 「お気に入り」と「覚えた」が両方 ON のカードを整理
        //    → My Collection 優先にして、learned から外す
        let both = favoriteIDs.intersection(learnedIDs)
        if !both.isEmpty {
            learnedIDs.subtract(both)
            saveLearned()
        }

        // 5. 完了通知
        NotificationCenter.default.post(name: .storeDidChange, object: nil)
    }
}

extension HomeworkStore {
    
    func restoreMissingMarkedCards() {
        // UUID方式では、WordKeyのように pos/word/meaning から復元はできない。
        // 代わりに、words に実体のないマークIDを掃除する。
        let existingIDs = Set(words.map(\.id))
        
        let beforeFav = favoriteIDs.count
        let beforeLearned = learnedIDs.count
        let beforeRequired = requiredIDs.count
        
        favoriteIDs = favoriteIDs.intersection(existingIDs)
        learnedIDs = learnedIDs.intersection(existingIDs)
        requiredIDs = requiredIDs.intersection(existingIDs)
        
        if favoriteIDs.count != beforeFav { saveFavorites() }
        if learnedIDs.count != beforeLearned { saveLearned() }
        if requiredIDs.count != beforeRequired { saveRequired() }
        
        NotificationCenter.default.post(name: .storeDidChange, object: nil)
    }
}
    // MARK: - WordsForest Backup support

    extension HomeworkStore {

        /// 統合バックアップへ渡す単語データ
        var backupWords: [StoredWord] {
            words
        }

        /// 統合バックアップへ渡す My Collection のUUID
        var backupFavoriteIDs: [UUID] {
            Array(favoriteIDs)
        }

        /// 統合バックアップへ渡す 覚えたBOX のUUID
        var backupLearnedIDs: [UUID] {
            Array(learnedIDs)
        }
    }

// MARK: - WordsForest Backup restore support

extension HomeworkStore {

    /// 統合バックアップから
    /// 単語本体・My Collection・覚えたBOX を復元する
    ///
    /// ※ この関数は、復元処理が正式に実行されたときだけ呼ぶ
    func restoreFromWordsForestBackup(
        words restoredWords: [StoredWord],
        favoriteIDs restoredFavoriteIDs: [UUID],
        learnedIDs restoredLearnedIDs: [UUID]
    ) {

        // 単語本体をバックアップ時点の状態へ戻す
        words = restoredWords

        // 復元されたwordsに実在するUUIDだけを有効にする
        let existingIDs = Set(restoredWords.map(\.id))

        favoriteIDs = Set(restoredFavoriteIDs)
            .intersection(existingIDs)

        learnedIDs = Set(restoredLearnedIDs)
            .intersection(existingIDs)

        // requiredIDs は統合バックアップ対象外。
        // 復元後に存在しないUUIDだけ掃除する。
        requiredIDs = requiredIDs.intersection(existingIDs)

        // 永続保存
        save()
        saveFavorites()
        saveLearned()
        saveRequired()

        // 画面更新
        NotificationCenter.default.post(
            name: .storeDidChange,
            object: nil
        )

        NotificationCenter.default.post(
            name: .favoritesDidChange,
            object: nil
        )

        NotificationCenter.default.post(
            name: .learnedDidChange,
            object: nil
        )
    }
}
