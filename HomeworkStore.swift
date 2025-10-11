//
//  File.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/24.
//

import Foundation

extension PartOfSpeech: Codable {}

struct StoredWord: Codable, Hashable {
    var word: String
    var meaning: String
    var pos: PartOfSpeech
}

final class HomeworkStore {
    static let shared = HomeworkStore()
    private init() { load() }
    
    private let key = "homework_words_v1"
    
    private(set) var words: [StoredWord] = []
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
    
    func add(word: String, meaning: String, pos: PartOfSpeech) {
        words.append(.init(word: word, meaning: meaning, pos: pos))
        save()
    }
    func clear() { words.removeAll(); save() }

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
    }

    // 画面で使う WordCard に変換
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
} // ← ここでクラスを閉じる

// ===== ここから「拡張」 2️⃣ をそのまま追加 =====
extension HomeworkStore {
    /// 品詞ごとに target 枚になるまで SampleDeck から重複なく補完
    func autofill(for pos: PartOfSpeech, target: Int = 24) {
        let current = list(for: pos)                 // 既存カード（UI用）
        guard current.count < target else { return }

        let bank = SampleDeck.filtered(by: pos)      // A1〜B1の元データ源（あなたの実装のまま）
        let existing = Set(current.map { $0.word.lowercased() })

        var count = current.count
        for card in bank where count < target {
            if !existing.contains(card.word.lowercased()) {
                add(word: card.word, meaning: card.meaning, pos: pos)
                count += 1
            }
        }
    }

    ///（※AddWordView で「更新」を使うなら同梱しておくと便利）
    func update(_ old: WordCard, word: String, meaning: String) {
        if let i = words.firstIndex(where: {
            $0.pos == old.pos &&
            $0.word == old.word &&
            $0.meaning == old.meaning
        }) {
            words[i].word = word
            words[i].meaning = meaning
            save()
        }
    }
}
