//
//  PartOfSpeech.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/30. →12/06
//
// PartOfSpeech.swift
import Foundation
import SwiftUI

enum PartOfSpeech: String, CaseIterable, Hashable, Codable {
    case noun, verb, adj, adv
    case others
}

extension PartOfSpeech {
    static func parse(_ s: String) -> PartOfSpeech? {
        switch s.lowercased() {
        case "noun","名詞","n": return .noun
        case "verb","動詞","v": return .verb
        case "adjective","形容詞","adj","a": return .adj
        case "adverb","副詞","adv","r": return .adv
        case "others","other","misc","その他","他":  return .others   // ← 追加
        default: return nil
        }
    }
}

extension PartOfSpeech {
    /// 品詞の日本語タイトル
    var jaTitle: String {
        switch self {
        case .noun: return "名詞"
        case .verb: return "動詞"
        case .adj:  return "形容詞"
        case .adv:  return "副詞"
        case .others: return "その他の品詞"
        }
    }
}

extension PartOfSpeech {
    static let collectionCases: [PartOfSpeech] = [.noun, .verb, .adj, .adv, .others]
    static let homeworkCases:   [PartOfSpeech] = [.noun, .verb, .adj, .adv]
}

extension PartOfSpeech {
    var tileColor: Color {
        switch self {
        case .noun: return .pink
        case .verb: return .blue
        case .adj: return .green
        case .adv: return .yellow
        case .others: return .purple
        }
    }
}
