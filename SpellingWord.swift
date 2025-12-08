//
//  SpellingWord.swift
//  WordsForest
//  Created by Nami .T on 2025/11/04.
//
//  modified ver. 2025/12/06  （WordCard 複数意味対応版）

import Foundation

struct SpellingWord: Identifiable {
    let id = UUID()

    let display: String       // go・went・gone 表示用
    let answer: String        // 判定用（基本形 go）
    let letters: [Character]  // タイル用
    let pos: PartOfSpeech
    let meaningJa: String

    init(card: WordCard) {

        // 不規則動詞の形（動詞のときだけ）
        let forms: [String]
        if card.pos == .verb {
            forms = IrregularVerbBank.forms(for: card.word) ?? []
        } else {
            forms = []
        }

        // 1) 表示用：forms[] があればそれを繋ぐ
        if !forms.isEmpty {
            display = forms.joined(separator: "・")
        } else {
            display = card.word        // 旧形式との互換
        }

        pos = card.pos

        // 2) 意味（配列 → とりあえず最初の意味だけ表示）
        meaningJa = card.meanings.first ?? ""

        // 3) 判定用：基本形は forms[0]
        let base: String
        if let first = forms.first {
            base = first          // go / run / write
        } else {
            // 旧形式 fallback：word の一番左を使う（go・went・gone → go）
            let raw = card.word.components(separatedBy: ["・", " "]).first ?? card.word
            base = raw.lowercased()
        }

        answer = base
        letters = Array(base.uppercased())
    }
}
