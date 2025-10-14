//
//  IrregularVerbBank.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/14.
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

    static func forms(for base: String) -> [String]? {
        forms[base.lowercased()]
    }
}
