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
        // HomeworkState 側で：
        //  1) HomeworkStore.savedHomeworkSet(for:) があればそれを使う
        //  2) なければ pickHomeworkWords(...) で生成し保存
        let cards = hw.homeworkWords(for: pos)

        // 動物アイコンは HomeworkState の variantIndex と PartOfSpeech のテーマに依存
        let animal = pos.animalName(forCycle: hw.variantIndex(for: pos))

        return POSFlashcardView(
            title: pos.jaTitle,
            cards: cards,
            accent: pos.accent,
            background: pos.backgroundColor,
            animalName: animal,
            reversed: false,
            onEdit: { _ in }
        )
    }

    // 2品詞ぶんの「今週の24語」をまとめて表示するページ
    private func combinedWordcardPage(for parts: [PartOfSpeech]) -> some View {
        // 例: [.noun, .adj] や [.verb, .adv]
        guard parts.count >= 2 else {
            return AnyView(Text("設定に誤りがあります"))
        }

        let firstPos  = parts[0]
        let secondPos = parts[1]

        // このサイクルで決まった宿題セット（12語＋12語）
        let cardsA = hw.homeworkWords(for: firstPos)
        let cardsB = hw.homeworkWords(for: secondPos)
        let allCards = cardsA + cardsB

        // タイトル
        let title = "\(firstPos.jaTitle)＋\(secondPos.jaTitle) 24語"

        // 🎨 24語ページは「中立テーマ」にする（品詞色は使わない）
        let background = Color(.systemGray6)   // やわらかいグレー
        let accent     = Color.primary

        // 24語ページ用のマスコット（インデックス的なアライグマ）
        let mixAnimal  = "index_raccoon_flower"

        return POSFlashcardView(
            title: title,
            cards: allCards,
            accent: accent,
            background: background,
            animalName: mixAnimal,
            reversed: false,
            onEdit: { _ in }   // ここでは編集はしない
        )
        .eraseToAnyView()
    }
}

// 小さなヘルパー（型消去）
private extension View {
    func eraseToAnyView() -> AnyView { AnyView(self) }
}
