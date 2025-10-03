//
//  POSTheme.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/29.
//

import SwiftUI

extension PartOfSpeech {
    
    /// 画面の背景に使う“固定パステル”（Assets の Color Set を参照）
    var backgroundColor: Color {
        switch self {
        case .noun:  return Color("nounPink")
        case .verb:  return Color("verbBlue")
        case .adj:   return Color("adjGreen")
        case .adv:   return Color("advYellow")   // ← orange ではなく yellow
        }
    }
    // 品詞ごとのアクセント色
    var accent: Color {
        switch self {
        case .noun: return .pink
        case .verb: return .blue
        case .adj:  return .green      // 好きな色に変えてOK
        case .adv:  return .yellow
        }
    }

    // タイトル左の絵文字
    var icon: String {
        switch self {
        case .noun: return "🐻"
        case .verb: return "🐈"
        case .adj:  return "🐇"
        case .adv:  return "🦙"
        }
    }

    // 右下マスコットの候補（ローテーション用）
    var animalVariants: [String] {
        switch self {
        case .noun: return ["noun_bear_brown", "noun_bear_white", "noun_bear_panda"]
        case .verb: return ["verb_cat_gray",  "verb_cat_black",  "verb_cat_tabby"]
        case .adj:  return ["adj_rabbit_white","adj_rabbit_beige","adj_rabbit_gray"]
        case .adv:  return ["adv_alpaca_ivory","adv_alpaca_brown","adv_alpaca_beige"]
        }
    }

    // サイクル番号から表示する1枚を選ぶ
    func animalName(forCycle cycle: Int) -> String {
        let list = animalVariants
        guard !list.isEmpty else { return "" }
        return list[cycle % list.count]
    }
}

