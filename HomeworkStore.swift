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
            save() // ← 既存の保存処理を呼ぶ
        }
    }
    // 画面で使う WordCard に変換（必要に応じて初期値は調整）
    func list(for pos: PartOfSpeech) -> [WordCard] {
        words
            .filter { $0.pos == pos }
            .map { sw in
                WordCard(
                    word: sw.word,
                    meaning: sw.meaning,
                    pos: sw.pos        // ← ここまででOK（id は自動）
                )
            }
    }
}
