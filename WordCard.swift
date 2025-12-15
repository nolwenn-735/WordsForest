//
//  WordCard.swift
//  WordsForest
//
//  12/6のrow,POSFlashcardListViewを削除したとりあえず動く緊急パッチ 12/14jason対応前
//

import Foundation

struct WordCard: Identifiable, Codable, Hashable {
    let id: UUID
    let pos: PartOfSpeech
    let word: String
    var meanings: [String]
    var examples: [String]

    init(
        id: UUID = UUID(),
        pos: PartOfSpeech,
        word: String,
        meanings: [String],
        examples: [String] = []
    ) {
        self.id = id
        self.pos = pos
        self.word = word
        self.meanings = meanings
        self.examples = examples
    }
}

// 👇 これをファイルのいちばん下あたりに追加
extension WordCard {
    /// 旧スタイル（meaning: String）呼び出し用のショートカット
    init(word: String, meaning: String, pos: PartOfSpeech) {
        self.init(
            pos: pos,
            word: word,
            meanings: [meaning],
            examples: []
        )
    }
}
