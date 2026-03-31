//
//  File.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/24.
//
//  HomeworkStore.swift  （🍊Clément完全版・複数意味対応）💛　→ 12/7 Thinking🍊版→12/12 before5.2版→12/14jason対応化前→jason12/15対応→2026/01/20最初のmeaningsにID付版→01/24不規則動詞と宿題履歴→UUID方式に変更🌿🍊



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

final class HomeworkStore: ObservableObject {

    static let shared = HomeworkStore()

    // 保存対象
    @Published private(set) var words: [StoredWord] = []
    @Published private(set) var favoriteIDs: Set<UUID> = []
    @Published private(set) var learnedIDs: Set<UUID> = []
    
    private let key = "homework_v3"
    private let favKey = "favorites_v3"
    private let learnedKey = "learned_v3"

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
    
    // 今回は migrate の中身は仮。旧データがあればここで変換する。
    private func migrateIfNeeded() {
        // すでに v3 の words が入っていれば何もしない
        guard words.isEmpty else { return }

        // ここで旧バージョンからの移行をすることもできるけど、
        // ひとまず「SampleDeck の単語を初期データとして流し込む」だけやる

        func seed(from pos: PartOfSpeech) {
            let bank = SampleDeck.filtered(by: pos)

            for card in bank {
                // SampleDeck 側は 1語1意味なので、最初の意味だけ使う
                let base = card.meanings.first ?? ""
                let trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }

                // 既に同じ word+meaning+pos が入っていれば add() 側で弾かれる
                _ = add(word: card.word, meaning: trimmed, pos: pos)
            }
        }

        // 名詞・動詞・形容詞・副詞ぶん種をまく(added .others 12/12)
        for pos in PartOfSpeech.collectionCases {
            seed(from: pos)
        }

        // ここまでで words[] が埋まるので、以降の list(for:)
        // や homeworkWords(for:) からカードが見えるようになる
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
            let meanings = Array(Set(group.map { normMeaning($0.meaning) }))
                .sorted()
            guard let firstMeaning = meanings.first else { return nil }
            
            // first を「意味が firstMeaning の StoredWord」に固定
            guard let first = group.first(where: { normMeaning($0.meaning) == firstMeaning }) else { return nil }
            
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

                let mergedMeanings = Array(Set(same.map { normMeaning($0.meaning) }))
                    .sorted()

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

        let bank = SampleDeck.filtered(by: pos)
        let existing = Set(current.map { $0.word.lowercased() })

        var count = current.count
        for card in bank where count < target {
            if !existing.contains(card.word.lowercased()) {
                add(word: card.word, meaning: card.meanings.first ?? "", pos: pos)
                count += 1
            }
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

    /// 既存カードの更新（とりあえず「最初の意味」を置き換える想定）
    func update(_ original: WordCard, word newWord: String, meaning newMeaning: String) {
        let oldKey = key(for: original)

        let trimmedMeaning = newMeaning.trimmingCharacters(in: .whitespacesAndNewlines)
        let newKey = WordKey(
            pos: original.pos,
            word: newWord.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            meaning: trimmedMeaning
        )

        if let idx = words.firstIndex(where: { key(for: $0) == oldKey }) {
            // ✅ ここが大事：既存IDを保持
            let existingID = words[idx].id
            words[idx] = StoredWord(id: existingID, word: newWord, meaning: trimmedMeaning, pos: original.pos)
        } else {
            // 見つからない時だけ新規（=新ID）
            words.append(StoredWord(word: newWord, meaning: trimmedMeaning, pos: original.pos))
        }

        save()
        saveFavorites()
        saveLearned()
        NotificationCenter.default.post(name: .storeDidChange, object: nil)
    }
}

// MARK: - 通知名

extension Notification.Name {
    static let storeDidChange     = Notification.Name("storeDidChange")
    static let favoritesDidChange = Notification.Name("favoritesDidChange")
    static let learnedDidChange   = Notification.Name("learnedDidChange")
}

// MARK: - My Collection 用お気に入りヘルパー
extension HomeworkStore {

    /// My Collection に出すお気に入りカード（全部品詞）
/*    var collectionFavorites: [WordCard] {
        PartOfSpeech.allCases         // noun / verb / adj / adv / others ぜんぶ
            .flatMap { pos in list(for: pos) }
            .filter { card in
                isFavorite(card)      // そこでさっきの isFavorite(_:)
            }
            .sorted { $0.word < $1.word }  // アルファベット順
    }
*/

    /// 品詞ごとに分けたお気に入り（セクション分けしたいとき用）
/*    var collectionFavoritesByPos: [PartOfSpeech: [WordCard]] {
        var dict: [PartOfSpeech: [WordCard]] = [:]

        for pos in PartOfSpeech.allCases {
            let favs = list(for: pos)
                .filter { isFavorite($0) }
                .sorted { $0.word < $1.word }

            if !favs.isEmpty {
                dict[pos] = favs
            }
        }
        return dict
    }
*/
 
    /// My Collection の総数表示用（WordCard 単位）
 /*   var collectionFavoritesCount: Int {
        collectionFavorites.count
    }
  */
    
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
