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
    }

    // 既存の保存キー（単語本体）
    private let key = "homework_words_v1"
    // 新規：お気に入り・覚えた用のキー
    private let favKey = "homework_favs_v1"
    private let learnedKey = "homework_learned_v1"

    // 単語本体
    private(set) var words: [StoredWord] = []

    // 新規：保存先
    private(set) var favorites: Set<WordKey> = []
    private(set) var learned: Set<WordKey> = []

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

    // MARK: - 新規: Key 化ヘルパー
    private func key(for c: WordCard) -> WordKey {
        .init(pos: c.pos, word: c.word, meaning: c.meaning)
    }
    private func key(for s: StoredWord) -> WordKey {
        .init(pos: s.pos, word: s.word, meaning: s.meaning)
    }

    // MARK: - CRUD
    func add(word: String, meaning: String, pos: PartOfSpeech) {
        words.append(.init(word: word, meaning: meaning, pos: pos))
        save()
    }

    func clear() {
        words.removeAll()
        save()
        favorites.removeAll()
        learned.removeAll()
        saveFavorites()
        saveLearned()
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
    }

    /// 一覧表示用に変換
    func list(for pos: PartOfSpeech) -> [WordCard] {
        words
            .filter { $0.pos == pos }
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
        }
    }

    // MARK: - ♡ / ✅ API（UI から使う）
    // My Collection
    func isFavorite(_ c: WordCard) -> Bool { favorites.contains(key(for: c)) }
    func setFavorite(_ c: WordCard, enabled: Bool) {
        let k = key(for: c)
        if enabled { favorites.insert(k) } else { favorites.remove(k) }
        saveFavorites()
    }
    func toggleFavorite(_ c: WordCard) { setFavorite(c, enabled: !isFavorite(c)) }

    // 覚えたBOX
    func isLearned(_ c: WordCard) -> Bool { learned.contains(key(for: c)) }
    func setLearned(_ c: WordCard, enabled: Bool) {
        let k = key(for: c)
        if enabled { learned.insert(k) } else { learned.remove(k) }
        saveLearned()
    }
    func toggleLearned(_ c: WordCard) { setLearned(c, enabled: !isLearned(c)) }
}

// 既存の補完＆更新（そのまま生かす）
extension HomeworkStore {
    /// 品詞ごとに target 枚になるまで SampleDeck から重複なく補完
    func autofill(for pos: PartOfSpeech, target: Int = 24) {
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
