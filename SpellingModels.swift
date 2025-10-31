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
    case easy   // 全部必要なアルファベットだけ
    case hard   // まぎらわしいのを1つ混入

    var id: String { rawValue }
}

// ② ゲームに渡す1件分の単語
struct SpellingWord: Identifiable {
    let id = UUID()
    let text: String      // 英単語
    let pos: PartOfSpeech // 品詞（色づけ用）    
    let meaningJa: String
}
