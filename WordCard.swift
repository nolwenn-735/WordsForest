//
//  WordCard.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/30.
//

import Foundation

struct WordCard: Identifiable, Hashable {
    var id: UUID
    var word: String
    var meaning: String
    var pos: PartOfSpeech   // ← 使わないなら後で消してOK

    // 明示イニシャライザ（引数ラベルを固定）
    init(word: String, meaning: String, pos: PartOfSpeech, id: UUID = UUID()) {
        self.id = id
        self.word = word
        self.meaning = meaning
        self.pos = pos
    }
}
