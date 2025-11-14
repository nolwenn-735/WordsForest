//
//  SpellingModels.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/31.
//
// SpellingModels.swift
// WordsForest
import Foundation

enum SpellingDifficulty: String, Identifiable {
    case easy
    case hard

    var id: String { rawValue }
}
