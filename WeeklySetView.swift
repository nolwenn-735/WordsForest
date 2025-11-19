//
//  WeeklySetView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/07.
//
import SwiftUI

struct WeeklySetView: View {
    @EnvironmentObject var hw: HomeworkState
    let pair: PosPair

    init(pair: PosPair) {
        self.pair = pair
    }

    var body: some View {
        let parts = pair.parts   // [.noun, .adj] など

        List {
            Section("今週のセット") {
                posRow(parts[0])
                posRow(parts[1])
            }

            Section {
                NavigationLink("24語まとめて学習") {
                    combinedWordcardPage(for: parts)
                }
            }
        }
        .navigationTitle("今週のセット")
    }

    @ViewBuilder
    private func posRow(_ pos: PartOfSpeech) -> some View {
        NavigationLink("\(pos.jaTitle) 12語") {
            singleWordcardPage(for: pos)
        }
        .foregroundStyle(pos.accent)
    }

    // 品詞ごとの12語レッスン
    private func singleWordcardPage(for pos: PartOfSpeech) -> some View {
        let cards = hw.homeworkWords(for: pos)
        let animal = pos.animalName(forCycle: hw.variantIndex(for: pos))

        return POSFlashcardView(
            title: "\(pos.jaTitle) レッスン",
            cards: cards,
            accent: pos.accent,
            background: pos.backgroundColor,
            animalName: animal,
            reversed: false,
            onEdit: { _ in }
        )
    }

    // ✅ 2品詞ぶん（24語）のまとめページ
    private func makeCombinedPage(for parts: [PartOfSpeech]) -> some View {
        // それぞれ 12語ずつ取得して結合
        let cards = parts.flatMap { hw.homeworkWords(for: $0) }

        // とりあえず先頭品詞のテーマを代表に使う
        let primary = parts.first ?? .noun
        let title: String
        if parts.count >= 2 {
            title = "\(primary.jaTitle)＋\(parts[1].jaTitle) 24語レッスン"
        } else {
            title = "24語レッスン"
        }

        let animal = primary.animalName(forCycle: hw.variantIndex(for: primary))

        return POSFlashcardView(
            title: title,
            cards: cards,
            accent: primary.accent,
            background: primary.backgroundColor,
            animalName: animal,
            reversed: false,
            onEdit: { _ in }
        )
    }

    // 2品詞ぶんの「今週の24語」をまとめて表示するページ
    private func combinedWordcardPage(for parts: [PartOfSpeech]) -> some View {
        // 例: [.noun, .adj] や [.verb, .adv]
        let firstPos  = parts[0]
        let secondPos = parts[1]

        // このサイクルで決まった宿題セット（12語＋12語）
        let cardsA = hw.homeworkWords(for: firstPos)
        let cardsB = hw.homeworkWords(for: secondPos)
        let allCards = cardsA + cardsB

        // 🎨 24語ページは「中立テーマ」にする（品詞色は使わない）
        let background = Color(.systemGray6)   // やわらかいグレー
        let accent     = Color.primary
        let mixAnimal  = "index_racoon_stand" 

        return POSFlashcardView(
            title: "今週の24語レッスン",
            cards: allCards,
            accent: accent,
            background: background,
            animalName: mixAnimal,
            reversed: false,
            onEdit: { _ in }   // ここでは編集はしない
        )
    }
}
