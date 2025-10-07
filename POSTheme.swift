//
//  POSTheme.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/29.
//

import SwiftUI

extension PartOfSpeech {

    // 画面の背景に使う色（Assets の Color Set 名）
    var backgroundColor: Color {
        switch self {
        case .noun: return Color("nounPink")
        case .verb: return Color("verbBlue")
        case .adj:  return Color("adjGreen")
        case .adv:  return Color("advYellow")
        }
    }

    // アイコン等のアクセント色（任意）
    var accent: Color {
        switch self {
        case .noun: return .pink
        case .verb: return .blue
        case .adj:  return .green
        case .adv:  return .yellow
        }
    }

    // サイクル番号から表示する動物画像名を1つ選ぶ
    func animalName(forCycle cycle: Int) -> String {
        let list = animalVariants
        guard !list.isEmpty else { return "" }
        return list[cycle % list.count]
    }

    // 品詞ごとの画像名リスト（Assets の画像名）
    private var animalVariants: [String] {
        switch self {
        case .noun: return ["noun_bear_brown", "noun_bear_white", "noun_bear_panda"]
        case .verb: return ["verb_cat_gray", "verb_cat_black", "verb_cat_tabby"]
        case .adj:  return ["adj_rabbit_white", "adj_rabbit_beige", "adj_rabbit_gray"]
        case .adv:  return ["adv_alpaca_ivory", "adv_alpaca_brown", "adv_alpaca_beige"]
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
