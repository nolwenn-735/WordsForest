//
//  SpellingModels.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/31.
//
// SpellingModels.swift
// WordsForest

import SwiftUI   // Colorとか使うかもだから入れとく

// ① スペリングの難易度（みんなで共通で使うやつ）
enum SpellingDifficulty: String, CaseIterable, Identifiable {
    case easy // 全部必要なアルファベットだけ or まぎらわしいのを1つ混入
    case hard
    var id: String { rawValue }
}

// ② ゲームに渡す1件分の単語
struct SpellingWord: Identifiable,Hashable {
    let id = UUID()
    let text: String      // 英単語
    let pos: PartOfSpeech // 品詞（色づけ用）
    let meaningJa: String
    
    init(card: WordCard) {
        self.text = card.word
        self.meaningJa = card.meaning
        self.pos = card.pos
    }
}
