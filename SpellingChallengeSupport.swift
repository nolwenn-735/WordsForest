//
//  SpellingChallengeSupport.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/31.
//

import SwiftUI




/// 「この単語から紛らわしい文字を1コちょうだい」をやるためのextension
extension String {
    func misleadingLetter() -> Character? {
        // まずは文字をぜんぶ小文字に
        let chars = Array(self.lowercased())

        // よく間違う候補たち
        let vowelConfusions: [Character: [Character]] = [
            "a": ["e", "i"],
            "e": ["a", "i"],
            "i": ["e", "a", "u"],
            "o": ["u", "a"],
            "u": ["o", "a"]
        ]
        let consonantConfusions: [Character: [Character]] = [
            "r": ["l"],
            "l": ["r"],
            "c": ["k"],
            "k": ["c"]
        ]

        // 文字列の中にある文字を1コずつ見て、
        // 「これには紛らわしさがあるかな？」って探す
        for ch in chars.shuffled() {
            if let list = vowelConfusions[ch], let pick = list.randomElement() {
                return pick
            }
            if let list = consonantConfusions[ch], let pick = list.randomElement() {
                return pick
            }
        }

        // どれにも当てはまらなかったときの保険
        return "a"
    }
}
