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

        // よく間違える候補たち（母音→母音、子音→子音）
        let vowelConfusions: [Character: [Character]] = [
            "a": ["e","o"],
            "e": ["i","a"],
            "i": ["e","u"],
            "o": ["a","u"],
            "u": ["a","i"],
        ]

        let consonantConfusions: [Character: [Character]] = [
            "n": ["m"], "m": ["n"],
            "r": ["l"], "l": ["r"],
            "k": ["c"],
            "s": ["c"],
            "b": ["v"], "v": ["b"],
        ]

        // 文字列の中にある文字をシャッフル順で見て、
        //「それに紛らわしさがあるかな？」って探す
        for (i, ch) in chars.enumerated().shuffled() {
            // ① 母音系の混同行列
            if let list = vowelConfusions[ch], let pick = list.randomElement() {
                return pick
            }

            // ② c は文脈で分岐（"ce", "ci", "cy" → s、それ以外 → k）
            if ch == "c" {
                let next = (i + 1 < chars.count) ? chars[i + 1] : nil
                if let n = next, "eiy".contains(n) { return "s" }
                return "k"
            }
            // ③ g も文脈で分岐（ge, gi, gy → j、それ以外 → k）
            if ch == "g" {
                let next = (i + 1 < chars.count) ? chars[i + 1] : nil
                if let n = next, "eiy".contains(n) { return "j" }
                return "k"
            }

            // ③ それ以外の子音系
            if let list = consonantConfusions[ch], let pick = list.randomElement() {
                return pick
            }
        }

        // ④ どれにも当てはまらなければ混入しない
        return nil
    }
}
