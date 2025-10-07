//
//  PartOfSpeech.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/30.
//
// PartOfSpeech.swift
import Foundation

enum PartOfSpeech: String, CaseIterable, Hashable {
    case noun, verb, adj, adv
}
extension PartOfSpeech {
    var jaTitle: String {
        switch self {
        case .noun:       "名詞"
        case .verb:       "動詞"
        case .adj:  "形容詞"
        case .adv:     "副詞"
        }
    }
}
