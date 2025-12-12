//WeeklySetView.swift
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
            Section("今回のセット") {
                posRow(parts[0])
                posRow(parts[1])
            }

            Section {
                NavigationLink("24語まとめて学習") {
                    combinedWordcardPage(for: parts)
                }
            }
        }
        .navigationTitle("今回のセット")
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
        let cards  = hw.homeworkWords(for: pos)
        let animal = pos.animalName(forCycle: hw.variantIndex(for: pos))

        return POSFlashcardView(
            title: pos.jaTitle,
            cards: cards,
            accent: pos.accent,
            background: pos.backgroundColor,
            animalName: animal,
            hideLearned: true   // ← 追加
            // perRowAccent はデフォルト false なので省略でOK
        )
    }

    // 2品詞ぶん 24語まとめて
    private func combinedWordcardPage(for parts: [PartOfSpeech]) -> some View {
        guard parts.count >= 2 else {
            return AnyView(Text("設定に誤りがあります"))
        }

        let firstPos  = parts[0]
        let secondPos = parts[1]

        let cardsA   = hw.homeworkWords(for: firstPos)
        let cardsB   = hw.homeworkWords(for: secondPos)
        let allCards = cardsA + cardsB

        let title      = "\(firstPos.jaTitle)+\(secondPos.jaTitle) 24語"
        let background = Color(.systemGray6)
        let accent     = Color.primary
        let mixAnimal  = "index_raccoon_flower"

        return POSFlashcardView(
            title: title,
            cards: allCards,
            accent: accent,
            background: background,
            animalName: mixAnimal
        )
        .eraseToAnyView()
    }
}

// 小さなヘルパー（型消去）
private extension View {
    func eraseToAnyView() -> AnyView { AnyView(self) }
}
