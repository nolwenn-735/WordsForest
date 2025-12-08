//
//  File.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/24.
//
//  HomeworkStore.swift  （🍊Clément完全版・複数意味対応）💛　→ 12/7 Thinking🍊版

import Foundation

// 品詞・単語・意味を合わせたキー（重複判定用）
struct WordKey: Hashable, Codable {
    var pos: PartOfSpeech
    var word: String
    var meaning: String
}

// 単語データ本体（保存対象）
struct StoredWord: Hashable, Codable {
    var word: String
    var meaning: String
    var pos: PartOfSpeech
}

final class HomeworkStore: ObservableObject {

    static let shared = HomeworkStore()

    // 保存対象
    @Published private(set) var words: [StoredWord] = []
    @Published private(set) var favorites: Set<WordKey> = []
    @Published private(set) var learned: Set<WordKey> = []

    private let key = "homework_v3"
    private let favKey = "favorites_v3"
    private let learnedKey = "learned_v3"

    private init() {
        load()
        loadFavorites()
        loadLearned()
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
        let data = try? JSONEncoder().encode(Array(favorites))
        UserDefaults.standard.set(data, forKey: favKey)
    }

    private func loadFavorites() {
        if let d = UserDefaults.standard.data(forKey: favKey),
           let arr = try? JSONDecoder().decode([WordKey].self, from: d) {
            favorites = Set(arr)
        }
    }

    private func saveLearned() {
        let data = try? JSONEncoder().encode(Array(learned))
        UserDefaults.standard.set(data, forKey: learnedKey)
    }

    private func loadLearned() {
        if let d = UserDefaults.standard.data(forKey: learnedKey),
           let arr = try? JSONDecoder().decode([WordKey].self, from: d) {
            learned = Set(arr)
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

        // 名詞・動詞・形容詞・副詞ぶん種をまく
        for pos in PartOfSpeech.homeworkCases {
            seed(from: pos)
        }

        // ここまでで words[] が埋まるので、以降の list(for:)
        // や homeworkWords(for:) からカードが見えるようになる
    }

    // MARK: - WordKey 生成

    func key(for c: WordCard) -> WordKey {
        // WordCard は meanings:[String] → 最初の意味だけキーに使う
        WordKey(
            pos: c.pos,
            word: norm(c.word),
            meaning: c.meanings.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        )
    }

    func key(for s: StoredWord) -> WordKey {
        WordKey(
            pos: s.pos,
            word: norm(s.word),
            meaning: s.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private func norm(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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
        let m = meaning.trimmingCharacters(in: .whitespacesAndNewlines)

        return words.contains(where: {
            $0.pos == pos &&
            norm($0.word) == w &&
            $0.meaning.trimmingCharacters(in: .whitespacesAndNewlines) == m
        })
    }

    func delete(_ card: WordCard) {
        // WordCard → StoredWord の1件だけ削除
        let k = key(for: card)

        if let i = words.firstIndex(where: {
            $0.pos == k.pos &&
            norm($0.word) == k.word &&
            $0.meaning.trimmingCharacters(in: .whitespacesAndNewlines) == k.meaning
        }) {
            words.remove(at: i)
            save()
            NotificationCenter.default.post(name: .storeDidChange, object: nil)
        }
    }

    // MARK: - Favorite / Learned

    func isFavorite(_ c: WordCard) -> Bool {
        favorites.contains(key(for: c))
    }

    func setFavorite(_ c: WordCard, enabled: Bool) {
        let k = key(for: c)
        if enabled { favorites.insert(k) }
        else { favorites.remove(k) }
        saveFavorites()
        NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
    }

    func toggleFavorite(_ c: WordCard) {
        setFavorite(c, enabled: !isFavorite(c))
    }

    func isLearned(_ c: WordCard) -> Bool {
        learned.contains(key(for: c))
    }

    func setLearned(_ c: WordCard, enabled: Bool) {
        let k = key(for: c)
        if enabled { learned.insert(k) }
        else { learned.remove(k) }
        saveLearned()
        NotificationCenter.default.post(name: .learnedDidChange, object: nil)
    }

    func toggleLearned(_ c: WordCard) {
        setLearned(c, enabled: !isLearned(c))
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
            guard let first = group.first else { return nil }

            let meanings = group.map { $0.meaning }
            let idFav = favorites.contains(key(for: first))
            return WordCard(
                id: UUID(),
                pos: first.pos,
                word: first.word,
                meanings: meanings,
                examples: []   // 例文は外部 ExampleStore が担当
            )
        }

        return cards.sorted { $0.word < $1.word }
    }

    // MARK: - Favorites / Learned の補助API（HomePage用）

    // お気に入り数（badge用）
    var favoritesCount: Int {
        favorites.count
    }

    // 覚えた数（badge用）
    var learnedCount: Int {
        learned.count
    }

    // お気に入り一覧（WordCard形式）
    func favoriteList() -> [WordCard] {
        let favKeys = favorites

        // favorites に該当する StoredWord を抽出
        let matched = words.filter { s in
            favKeys.contains(key(for: s))
        }

        // WordCard へ統合（複数意味対応）
        let grouped = Dictionary(grouping: matched, by: { $0.word })

        return grouped.values.compactMap { group in
            guard let first = group.first else { return nil }
            let meanings = group.map { $0.meaning }

            return WordCard(
                id: UUID(),
                pos: first.pos,
                word: first.word,
                meanings: meanings,
                examples: []   // 例文は外部 ExampleStore が担当
            )
        }
        .sorted { $0.word < $1.word }
    }

    // 覚えたBOX一覧（WordCard形式）
    func learnedList() -> [WordCard] {
        let learnedKeys = learned

        let matched = words.filter { s in
            learnedKeys.contains(key(for: s))
        }

        let grouped = Dictionary(grouping: matched, by: { $0.word })

        return grouped.values.compactMap { group in
            guard let first = group.first else { return nil }
            let meanings = group.map { $0.meaning }

            return WordCard(
                id: UUID(),
                pos: first.pos,
                word: first.word,
                meanings: meanings,
                examples: []   // 例文は外部 ExampleStore が担当
            )
        }
        .sorted { $0.word < $1.word }
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

        let newStored = StoredWord(
            word: newWord,
            meaning: newMeaning.trimmingCharacters(in: .whitespacesAndNewlines),
            pos: original.pos
        )
        let newKey = key(for: newStored)

        // 元の StoredWord を探して差し替え（なければ append）
        if let idx = words.firstIndex(where: { key(for: $0) == oldKey }) {
            words[idx] = newStored
        } else {
            words.append(newStored)
        }

        // MyCollection / 覚えたBOX のキーも更新
        if favorites.remove(oldKey) != nil {
            favorites.insert(newKey)
        }
        if learned.remove(oldKey) != nil {
            learned.insert(newKey)
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

// MARK: - Safe repair (Nolwenn gentle reset)

extension HomeworkStore {

    /// データ構造を壊さない「優しい宿題セット修復」
    func repairHomeworkSets() {
        // 通知抑止したい場合は後でラップしてもOK

        // 1. cachedHomework（HomeworkStateが使うキャッシュ）をリセット
        if let hw = HomeworkStateBridge.shared {
            hw.resetCache()
        }

        // 2. variant（動物カラー）を補正
        // 3色ループから外れてるなどの壊れを防ぐ
        func fix(_ value: inout Int) {
            if value < 0 || value > 2 { value = 0 }
        }

        if let hw = HomeworkStateBridge.shared {
            var n = hw.variantNoun; fix(&n); hw.variantNoun = n
            var a = hw.variantAdj;  fix(&a); hw.variantAdj  = a
            var v = hw.variantVerb; fix(&v); hw.variantVerb = v
            var d = hw.variantAdv;  fix(&d); hw.variantAdv  = d
        }

        // 3. 必要なら pos ごとに autofill（24語構成が崩れた時など）
        for pos in [PartOfSpeech.noun, .verb, .adj, .adv] {
            autofill(for: pos, target: 24)
        }

        // 完了通知
        NotificationCenter.default.post(name: .storeDidChange, object: nil)
    }
}
