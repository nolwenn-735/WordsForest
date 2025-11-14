//
//  SpellingChallengeSupport.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/31.
//
/// 「この単語から紛らわしい文字を1コちょうだい」をやるためのextension
// SpellingChallengeSupport.swift

import Foundation

extension String {
    /// この単語から「紛らわしい余分1文字」を1つ返す
    func misleadingLetter() -> Character? {
        let chars = Array(self.lowercased())

        // 母音の取り違え候補
        let vowelConfusions: [Character: [Character]] = [
            "a": ["e", "o"],
            "e": ["a", "i"],
            "i": ["e", "y"],
            "o": ["a", "u"],
            "u": ["a", "i"],
        ]

        // 子音の取り違え候補（例）
        let consonantConfusions: [Character: [Character]] = [
            "m": ["n"],
            "n": ["m"],
            "b": ["v"],
            "v": ["b"],
            "p": ["b"],
            "r": ["l"],
            "l": ["r"],
            "c": ["s","k"],
            "k": ["c"],
            "s": ["c"],
            "f": ["p","h"],
            // 必要に応じて増やしてOK
        ]

        var candidates: [Character] = []

        for ch in chars {
            if let vs = vowelConfusions[ch] {
                candidates.append(contentsOf: vs)
            }
            if let cs = consonantConfusions[ch] {
                candidates.append(contentsOf: cs)
            }
        }

        // 1つも候補が作れなかった場合だけ「単語に含まれないランダム1文字」
        if candidates.isEmpty {
            let alphabet = Array("abcdefghijklmnopqrstuvwxyz")
            let base = Set(chars)
            let filtered = alphabet.filter { !base.contains($0) }
            return filtered.randomElement()
        }

        return candidates.randomElement()
    }
}
