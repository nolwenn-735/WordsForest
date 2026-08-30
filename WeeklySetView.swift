
//WeeklySetView.swft 01/15.`26置き換え→01/17宿題セット不一致直しの置き換え


import SwiftUI

struct WeeklySetView: View {
    @EnvironmentObject var hw: HomeworkState
    let pair: PosPair

    var body: some View {
        let parts = pair.parts   // [.noun, .adj] など
        let totalCount =
            hw.homeworkWords(for: parts[0]).count
            + hw.homeworkWords(for: parts[1]).count

        List {
            Section("今回のセット") {
                posRow(parts[0])
                posRow(parts[1])
            }

            Section {
                NavigationLink("\(totalCount)語まとめて学習") {
                    combinedWordcardPage(for: parts)
                }
            }
        }
        .navigationTitle("今回のセット")
        .task {
            hw.requestRestoreFixedPackIfNeeded()
        }
    }

    private func posRow(_ pos: PartOfSpeech) -> some View {
        let count = hw.homeworkWords(for: pos).count

        return NavigationLink("\(pos.jaTitle) \(count)語") {
            singleWordcardPage(for: pos)
        }
        .foregroundStyle(pos.accent)
    }
    // 品詞ごとの宿題レッスン
    private func singleWordcardPage(for pos: PartOfSpeech) -> some View {
        let cards  = hw.homeworkWords(for: pos)
        let animal = pos.animalName(forCycle: hw.variantIndex(for: pos))

        return POSFlashcardView(
            title: pos.jaTitle,
            cards: cards,
            accent: pos.accent,
            background: pos.backgroundColor,
            animalName: animal,
            hideLearned: true
        )
    }

    // 2品詞ぶん まとめて
    @ViewBuilder
    private func combinedWordcardPage(for parts: [PartOfSpeech]) -> some View {
        if parts.count < 2 {
            Text("設定に誤りがあります")
        } else {
            let firstPos  = parts[0]
            let secondPos = parts[1]

            let cardsA   = hw.homeworkWords(for: firstPos)
            let cardsB   = hw.homeworkWords(for: secondPos)
            let allCards = cardsA + cardsB

            let title = "\(parts[0].jaTitle)+\(parts[1].jaTitle) \(allCards.count)語"
            let background = Color(.systemGray6)
            let accent     = Color.primary
            let mixAnimal  = "index_raccoon_flower"

            POSFlashcardView(
                title: title,
                cards: allCards,
                accent: accent,
                background: background,
                animalName: mixAnimal,
                showPOSSectionHeaders: true,
                hideLearned: true
            )
        }
    }
}
