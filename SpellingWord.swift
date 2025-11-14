//
//  SpellingWord.swift
//  WordsForest
//
//  Created by Nami .T on 2025/11/04.
//

import Foundation

struct SpellingWord: Identifiable {
    let id = UUID()

    let display: String       // 画面に出す用（go・went・gone 等）
    let answer: String        // 判定に使う正解（go 等）
    let letters: [Character]  // タイル用（answer を大文字配列にしたもの）

    let pos: PartOfSpeech
    let meaningJa: String

    init(card: WordCard) {
        display = card.word
        pos = card.pos
        meaningJa = card.meaning

        // 「・」より前だけを拾う（不規則動詞カード対応）
        let raw = card.word.components(separatedBy: "・").first ?? card.word
        _ = raw.lowercased()

        // 不規則動詞カードの代表形だけ拾う
        let base: String
        switch raw {
        case _ where raw.contains("went"):
            base = "go"
        case _ where raw.contains("gone"):
            base = "go"
        case _ where raw.contains("ran"):
            base = "run"
        case _ where raw.contains("kept"):
            base = "keep"
        // 必要なものをここに追加
        default:
            // "keep・kept・kept" みたいなやつは "・" より前だけ取る
            base = raw.components(separatedBy: ["・", " "]).first ?? raw
        }

        answer = base
        letters = Array(base.uppercased())
    }
}
