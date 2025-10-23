//
//  POSTheme.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/29.
//

import SwiftUI

extension PartOfSpeech {

    // 画面の背景色（Assets の Color Set 名）
    var backgroundColor: Color {
        switch self {
        case .noun:   return Color("nounPink")
        case .verb:   return Color("verbBlue")
        case .adj:    return Color("adjGreen")
        case .adv:    return Color("advYellow")
        case .others: return Color("othersLavender")
        }
    }

    // アクセント色（ボタンなど）
    var accentColor: Color {
        switch self {
        case .noun:   return .pink
        case .verb:   return .blue
        case .adj:    return .green
        case .adv:    return .yellow
        case .others: return Color("othersPurple")
        }
    }

    // 互換用（過去に pos.accent を使っていた呼び出しを生かす）
    var accent: Color { accentColor }

    // サイクル番号から、表示する動物画像名を 1 つ選ぶ
    func animalName(forCycle cycle: Int) -> String {
        let list = animalVariants
        guard !list.isEmpty else { return "" }
        return list[cycle % list.count]
    }

    // 品詞ごとの画像名リスト（Assets の名前）
    private var animalVariants: [String] {
        switch self {
        case .noun:   return ["noun_bear_brown", "noun_bear_white", "noun_bear_panda"]
        case .verb:   return ["verb_cat_gray", "verb_cat_black", "verb_cat_tabby"]
        case .adj:    return ["adj_rabbit_white", "adj_rabbit_beige", "adj_rabbit_gray"]
        case .adv:    return ["adv_alpaca_ivory", "adv_alpaca_brown", "adv_alpaca_beige"]
        case .others: return ["others_deer_fawn", "others_deer_doe", "others_deer_stag"]
        }
    }
}

// どこでもOK（例：POSTheme.swift の下など）
import Foundation

struct SampleDeckFilter {
    // あなたの SampleDeck にレベル情報が無い場合、
    // この関数は「pos だけでフィルタ → そのまま返す」にフォールバックします。
    static func by(pos: PartOfSpeech, levels: Set<CEFRLevel>?) -> [WordCard] {
        // 既存のヘルパがあるならそれを使用（無い場合は適宜差し替え）
        // 例: SampleDeck.filtered(by: pos)
        let base = SampleDeck.filtered(by: pos)

        // いまは levels を無視（SampleDeck に載せてない前提）
        // 後で SampleDeck に `level: CEFRLevel` を足したらここで絞り込めばOK
        return base
    }
}
