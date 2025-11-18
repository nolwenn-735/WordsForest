//
//  File.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/24.
//

import Foundation

// 既存どおり
extension PartOfSpeech: Codable {}

struct StoredWord: Codable, Hashable {
    var word: String
    var meaning: String
    var pos: PartOfSpeech
}

/// 単語の一意キー（品詞＋単語＋意味）
struct WordKey: Hashable, Codable {
    var pos: PartOfSpeech
    var word: String
    var meaning: String
}

final class HomeworkStore {
    static let shared = HomeworkStore()
    private init() {
        load()
        loadFavorites()
        loadLearned()
        migrateIfNeeded()   // ← これを追加
        loadLastUsed()      // 🆕 直近サイクル情報の読み込み
    }

    // 既存の保存キー（単語本体）
    private let key = "homework_words_v1"
    // 新規：お気に入り・覚えた用のキー
    private let favKey = "homework_favs_v1"
    private let learnedKey = "homework_learned_v1"
    // 追加：保存スキーマのバージョン管理
    private let schemaVersionKey = "homework_schema_version"
    private let currentSchemaVersion = 2
    
    // 🆕 lastUsed 用キー
    private let lastUsedKey = "homework_last_used_v1"

    // 単語本体
    private(set) var words: [StoredWord] = []

    // 新規：保存先
    private(set) var favorites: Set<WordKey> = []
    private(set) var learned: Set<WordKey> = []
    
    // 🆕 直近サイクルでの出題記録（WordKey → cycleIndex）
    private var lastUsed: [WordKey: Int] = [:]
    

    
    // MARK: - 単語の保存/読込（既存）
    private func save() {
        let data = try? JSONEncoder().encode(words)
        UserDefaults.standard.set(data, forKey: key)
    }
    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let arr = try? JSONDecoder().decode([StoredWord].self, from: data) {
            words = arr
        }
    }
    

    // MARK: - 新規: 保存/読込（お気に入り・覚えた）
    private func saveFavorites() {
        let data = try? JSONEncoder().encode(Array(favorites))
        UserDefaults.standard.set(data, forKey: favKey)
    }
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: favKey),
           let arr = try? JSONDecoder().decode([WordKey].self, from: data) {
            favorites = Set(arr)
        }
    }

    private func saveLearned() {
        let data = try? JSONEncoder().encode(Array(learned))
        UserDefaults.standard.set(data, forKey: learnedKey)
    }
    private func loadLearned() {
        if let data = UserDefaults.standard.data(forKey: learnedKey),
           let arr = try? JSONDecoder().decode([WordKey].self, from: data) {
            learned = Set(arr)
        }
    }
    // 🆕 MARK: - 直近サイクル情報の保存/読込
    private func saveLastUsed() {
        let data = try? JSONEncoder().encode(lastUsed)
        UserDefaults.standard.set(data, forKey: lastUsedKey)
    }

    private func loadLastUsed() {
        guard let data = UserDefaults.standard.data(forKey: lastUsedKey),
              let dict = try? JSONDecoder().decode([WordKey: Int].self, from: data) else {
            lastUsed = [:]
            return
        }
        lastUsed = dict
    }

    // MARK: - 正規化ヘルパ
    private func norm(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // 一度だけ実行する移行処理（お気に入り/覚えた/単語の重複を正規化）
    private func migrateIfNeeded() {
        let v = UserDefaults.standard.integer(forKey: schemaVersionKey)
        guard v < currentSchemaVersion else { return }

        // WordKey を統一ルールで正規化
        func normalized(_ k: WordKey) -> WordKey {
            WordKey(
                pos: k.pos,
                word: norm(k.word), // 小文字＋前後空白除去
                meaning: k.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }

        // 1) ♡ / ✅ セットを正規化して保存
        favorites = Set(favorites.map(normalized))
        learned   = Set(learned.map(normalized))
        saveFavorites()
        saveLearned()

        // 2) 単語本体の重複/余分な空白を整理（表示の大文字は保持）
        var seen = Set<WordKey>()
        words = words.reduce(into: []) { acc, s in
            let key = WordKey(
                pos: s.pos,
                word: norm(s.word),
                meaning: s.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            if seen.insert(key).inserted {
                acc.append(StoredWord(
                    word: s.word.trimmingCharacters(in: .whitespacesAndNewlines),
                    meaning: s.meaning.trimmingCharacters(in: .whitespacesAndNewlines),
                    pos: s.pos
                ))
            }
        }
        save()

        // バージョンを更新
        UserDefaults.standard.set(currentSchemaVersion, forKey: schemaVersionKey)
    }
    // MARK: - 新規: Key 化ヘルパー
    
    // ここを置き換え
    private func key(for c: WordCard) -> WordKey {
        .init(
            pos: c.pos,
            word: norm(c.word),
            meaning: c.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
    private func key(for s: StoredWord) -> WordKey {
        .init(
            pos: s.pos,
            word: norm(s.word),
            meaning: s.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    // MARK: - CRUD

    @discardableResult
    func add(word: String, meaning: String, pos: PartOfSpeech) -> Bool {
        if exists(word: word, meaning: meaning, pos: pos) { return false } // 完全かぶりは弾く
        words.append(.init(word: word, meaning: meaning, pos: pos))
        save()
        NotificationCenter.default.post(name: .storeDidChange, object: nil)   // ← 追加
        return true
    }

    func clear() {
        words.removeAll()
        save()
        favorites.removeAll()
        learned.removeAll()
        saveFavorites()
        saveLearned()
        NotificationCenter.default.post(name: .storeDidChange, object: nil)   // ← 追加
    }

    func delete(_ card: WordCard) {
        // 同じ品詞・単語・意味の「最初の1件だけ」を消す
        if let i = words.firstIndex(where: {
            $0.pos == card.pos &&
            $0.word == card.word &&
            $0.meaning == card.meaning
        }) {
            words.remove(at: i)
            save()
        }
        // セット側からも掃除
        let k = key(for: card)
        if favorites.remove(k) != nil { saveFavorites() }
        if learned.remove(k) != nil   { saveLearned()   }
        NotificationCenter.default.post(name: .storeDidChange, object: nil)   // ← 追加
    }

    // MARK: - 重複チェックヘルパ
    func exists(word: String, pos: PartOfSpeech) -> Bool {
        let w = norm(word)
        return words.contains { $0.pos == pos && norm($0.word) == w }
    }

    func exists(word: String, meaning: String, pos: PartOfSpeech) -> Bool {
        let w = norm(word)
        let m = meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        return words.contains {
            $0.pos == pos &&
            norm($0.word) == w &&
            $0.meaning.trimmingCharacters(in: .whitespacesAndNewlines) == m
        }
    }

    // 既存意味の一覧（重複除去して返す）
    func existingMeanings(for word: String, pos: PartOfSpeech) -> [String] {
        let w = norm(word)
        let list = words
            .filter { $0.pos == pos && norm($0.word) == w }
            .map { $0.meaning.trimmingCharacters(in: .whitespacesAndNewlines) }
        var seen = Set<String>()
        return list.filter { seen.insert($0).inserted }
    }
    /// 一覧表示用に変換
    func list(for pos: PartOfSpeech) -> [WordCard] {
        words
            .filter { $0.pos == pos }
            .filter { !learned.contains(self.key(for: $0)) } // ← ここで覚えたを除外
            .map { sw in
                WordCard(
                    word: sw.word,
                    meaning: sw.meaning,
                    pos: sw.pos
                )
            }
    }

    ///（AddWordView の「更新」に対応させるなら）
    func update(_ old: WordCard, word: String, meaning: String) {
        if let i = words.firstIndex(where: {
            $0.pos == old.pos &&
            $0.word == old.word &&
            $0.meaning == old.meaning
        }) {
            // セットのキー整合を保つ（変更時は入れ替え）
            let oldKey = key(for: old)
            let newKey = WordKey(pos: old.pos, word: word, meaning: meaning)
            if favorites.remove(oldKey) != nil { favorites.insert(newKey); saveFavorites() }
            if learned.remove(oldKey) != nil   { learned.insert(newKey);   saveLearned()   }

            words[i].word = word
            words[i].meaning = meaning
            save()
            NotificationCenter.default.post(name: .storeDidChange, object: nil) // ← 追加
        }
    }

    // MARK: - ♡ / ✅ API（UI から使う）
    // My Collection
    func isFavorite(_ c: WordCard) -> Bool { favorites.contains(key(for: c)) }
    func setFavorite(_ c: WordCard, enabled: Bool) {
        let k = key(for: c)
        if enabled {
            if favorites.insert(k).inserted {          // 追加が本当に起きた時だけ
                saveFavorites()
                NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
            }
        } else if favorites.remove(k) != nil {          // 削除が本当に起きた時だけ
            saveFavorites()
            NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
        }
    }

    func toggleFavorite(_ c: WordCard) { setFavorite(c, enabled: !isFavorite(c)) }
    // My Collection 一覧
    func favoriteList() -> [WordCard] {
        words
            .filter { favorites.contains(WordKey(pos: $0.pos, word: $0.word, meaning: $0.meaning)) }
            .map { WordCard(word: $0.word, meaning: $0.meaning, pos: $0.pos, isFavorite: true)
        }
    }
    
    
    // 覚えたBOX
    func isLearned(_ c: WordCard) -> Bool { learned.contains(key(for: c)) }
    func setLearned(_ c: WordCard, enabled: Bool) {
        let k = key(for: c)
        if enabled {
            if learned.insert(k).inserted {
                saveLearned()
                NotificationCenter.default.post(name: .learnedDidChange, object: nil)
            }
        } else if learned.remove(k) != nil {
            saveLearned()
            NotificationCenter.default.post(name: .learnedDidChange, object: nil)
        }
    }
    func toggleLearned(_ c: WordCard) { setLearned(c, enabled: !isLearned(c)) }
    // 覚えたBOX 一覧
    func learnedList() -> [WordCard] {
        words
            .filter { learned.contains(WordKey(pos: $0.pos, word: $0.word, meaning: $0.meaning)) }
            .map { WordCard(word: $0.word, meaning: $0.meaning, pos: $0.pos) }
    }
}

// 既存の補完＆更新（そのまま生かす）
extension HomeworkStore {
    /// 品詞ごとに target 枚になるまで SampleDeck から重複なく補完
    func autofill(for pos: PartOfSpeech, target: Int = 24) {
        guard pos != .others else { return }
        let current = list(for: pos)
        guard current.count < target else { return }

        let bank = SampleDeck.filtered(by: pos)
        let existing = Set(current.map { $0.word.lowercased() })

        var count = current.count
        for card in bank where count < target {
            if !existing.contains(card.word.lowercased()) {
                add(word: card.word, meaning: card.meaning, pos: pos)
                count += 1
            }
        }
    }    
}
 
extension Notification.Name {
    
    static let favoritesDidChange = Notification.Name("FavoritesDidChange")
    static let learnedDidChange   = Notification.Name("LearnedDidChange")
    static let storeDidChange     = Notification.Name("storeDidChange")   // 追加/削除など
}

// MARK: - Homework 用出題ロジック
extension HomeworkStore {

    /// 直近 `window` サイクルで出ていない単語を優先して count 個選ぶ
    func pickHomeworkWords(
        for pos: PartOfSpeech,
        cycleIndex: Int,
        count: Int,
        window: Int = 4
    ) -> [WordCard] {

        // 1. いま登録されている単語（覚えたBOXは list(for:) が除外済）
        let all = list(for: pos)
        guard !all.isEmpty else { return [] }

        // 2. 直近 window サイクル以内に出題された単語を集める
        let recentThreshold = max(0, cycleIndex - window + 1)
        let recentlyUsedKeys: Set<WordKey> = Set(
            lastUsed.compactMap { (key, usedCycle) in
                usedCycle >= recentThreshold ? key : nil
            }
        )

        // 3. 最近出たもの / 出ていないもの に分ける
        var fresh: [WordCard] = []
        var older: [WordCard] = []

        for card in all.shuffled() {
            let k = key(for: card)
            if recentlyUsedKeys.contains(k) {
                older.append(card)
            } else {
                fresh.append(card)
            }
        }

        // 4. まず fresh から優先的に取る
        var selected = Array(fresh.prefix(count))

        // 足りなければ older から補充
        if selected.count < count {
            let remain = count - selected.count
            selected.append(contentsOf: older.prefix(remain))
        }

        // 5. lastUsed を更新
        for c in selected {
            lastUsed[key(for: c)] = cycleIndex
        }
        saveLastUsed()

        return selected
    }
}

// MARK: - HomePage 用の読み取りプロパティ
extension HomeworkStore {
    var favoritesCount: Int { favorites.count }
    var learnedCount:  Int { learned.count }
    var hasFavorites:  Bool { !favorites.isEmpty }
    var hasLearned:    Bool { !learned.isEmpty }    
    
    @available(*, deprecated, message: "Use favoriteList()")
    func myCollectionList(for pos: PartOfSpeech? = nil) -> [WordCard] {
        let base = self.favoriteList()
        if let p = pos { return base.filter { $0.pos == p } }
        return base
    }
}
