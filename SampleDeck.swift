//
//  SampleDeck.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/30.
//

import Foundation

enum SampleDeck {
    static func filtered(by pos: PartOfSpeech) -> [WordCard] {
        switch pos {
        case .noun:
            return [
                WordCard(word: "apple",  meaning: "りんご",   pos: .noun),
                WordCard(word: "river",  meaning: "川",       pos: .noun),
                WordCard(word: "forest", meaning: "森",       pos: .noun),
                WordCard(word: "music",  meaning: "音楽",     pos: .noun),
            ]
        case .verb:
            return [
                WordCard(word: "run",    meaning: "走る",     pos: .verb),
                WordCard(word: "fly",    meaning: "飛ぶ",     pos: .verb),
                WordCard(word: "write",  meaning: "書く",     pos: .verb),
                WordCard(word: "think",  meaning: "考える",   pos: .verb),
            ]
        case .adj:
            return [
                WordCard(word: "gentle", meaning: "優しい",   pos: .adj),
                WordCard(word: "quiet",  meaning: "静かな",   pos: .adj),
                WordCard(word: "bright", meaning: "明るい",   pos: .adj),
                WordCard(word: "mossy",  meaning: "苔むした", pos: .adj),
            ]
        case .adv:
            return [
                WordCard(word: "quickly", meaning: "素早く",   pos: .adv),
                WordCard(word: "often",   meaning: "しばしば", pos: .adv),
                WordCard(word: "very",    meaning: "とても",   pos: .adv),
                WordCard(word: "almost",  meaning: "ほとんど", pos: .adv),
            ]
        }
    }
}
