//
//  IrregularVerbBank.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/14.→2026/01/24宿題セット編集フォーム作成対応
//

import Foundation

enum IrregularVerbBank {
    /// base -> [base, past, past participle]
    static let forms: [String: [String]] = [
        "write": ["write", "wrote", "written"],
        "go":    ["go", "went", "gone"],
        "come":  ["come", "came", "come"],
        "know":  ["know", "knew", "known"],
        "run":   ["run", "ran", "run"],
        "ride":  ["ride", "rode", "ridden"],
        "read":  ["read", "read", "read"],
        "eat":   ["eat", "ate", "eaten"],
        "drink": ["drink", "drank", "drunk"],
        "sleep": ["sleep", "slept", "slept"],
        "sing":  ["sing", "sang", "sung"],
        "swim":  ["swim", "swam", "swum"],
        "draw":  ["draw", "drew", "drawn"],
        "build": ["build", "built", "built"],
        "think": ["think", "thought", "thought"],
        "buy":   ["buy", "bought", "bought"],
        "bring": ["bring", "brought", "brought"],
        "take":  ["take", "took", "taken"],
        "give":  ["give", "gave", "given"],
        "see":   ["see", "saw", "seen"],
        "teach": ["teach", "taught", "taught"],
        "catch": ["catch", "caught", "caught"],
        "leave": ["leave", "left", "left"],
        "meet":  ["meet", "met", "met"],
        "stand": ["stand", "stood", "stood"],
        "sit":   ["sit", "sat", "sat"],
        "pay":   ["pay", "paid", "paid"],
        "sell":  ["sell", "sold", "sold"],
        "put":   ["put", "put", "put"],
        "find":  ["find", "found", "found"],
        "make":  ["make", "made", "made"],
        "do":    ["do", "did", "done"],
        "cut":   ["cut", "cut", "cut"],
        
        
        
        // ここに追加
    ]

    /// "write · wrote · written" みたいなのが来ても "write" にする
        static func base(from raw: String) -> String {
            raw.lowercased()
                .split(whereSeparator: { ch in
                    ch == " " || ch == "(" || ch == "·" || ch == "•" || ch == "・"
                })
                .first
                .map(String.init) ?? raw.lowercased()
        }

    static func forms(for base: String) -> [String]? {
        forms[base.lowercased()]
    }

    /// WordCard の word を渡すだけでOKな入口
    static func forms(from word: String) -> [String]? {
        forms(for: base(from: word))
    }
}
