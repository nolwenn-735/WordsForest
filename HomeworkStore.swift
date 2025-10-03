//
//  File.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/24.
//

import Foundation

//enum PartOfSpeech: String, Codable, CaseIterable { case noun, verb, adj }
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
