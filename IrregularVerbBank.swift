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
