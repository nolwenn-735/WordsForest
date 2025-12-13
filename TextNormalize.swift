//
//  TextNormalize.swift
//  WordsForest
//
//  Created by Nami .T on 2025/12/13.
//

import Foundation

func normWord(_ s: String) -> String {
    s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}

func normMeaning(_ s: String) -> String {
    // 全角スペース→半角、全角スラッシュ→半角
    let replaced = s
        .replacingOccurrences(of: "　", with: " ")
        .replacingOccurrences(of: "／", with: "/")

    // 連続空白を1個に畳む
    let collapsed = replaced
        .components(separatedBy: .whitespacesAndNewlines)
        .filter { !$0.isEmpty }
        .joined(separator: " ")

    return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
}
