import SwiftUI

// 品詞ごとのフラッシュカード一覧に遷移する薄いラッパー
struct POSFlashcardListView: View {
    let pos: PartOfSpeech
    let accent: Color

    var body: some View {
        // ここで5件に絞る（必要なら数字を変えるだけ）
        let limited = Array(SampleDeck.filtered(by: pos).prefix(5))
        POSFlashcardView(
            title: "\(pos.rawValue) レッスン",
            cards: limited,
            accent: accent
        )
    }
}
// 単語カード画面（縦スクロール・右下に動物PNG）
struct POSFlashcardView: View {
    let title: String
    let cards: [WordCard]
    let accent: Color
    // 画面内だけの♡トグル用（仮）
    @State private var tempPicked: Set<String> = []

    // とりあえず固定。後で品詞に合わせて差し替えます
    private let animalName = "rabbit_white"

    var body: some View {
        ZStack {
            // 1) 背景は単色（パステル）
            accent.ignoresSafeArea()

            // 2) 中身（縦スクロール）
            ScrollView {
                VStack(spacing: 16) {

                    // タイトル不要ならこの行は残しても非表示でOK
                    // Text(title).font(.system(size: 28, weight: .bold)).opacity(0)

                    ForEach(cards) { card in
                        cardView(card)
                    }

                    // 右下の動物とかぶらない逃げ
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }

            // 3) 右下固定の動物PNG
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(animalName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140)     // 好みで 120〜160
                        .opacity(0.95)
                        .padding(.trailing, 16)
                        .padding(.bottom, 12)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // 1枚のカード
    @ViewBuilder
    private func cardView(_ card: WordCard) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(card.word).font(.system(size: 22, weight: .semibold))
                Text(card.meaning).foregroundColor(.secondary)
            }
            Spacer()
            Button {
                if tempPicked.contains(card.id) { tempPicked.remove(card.id) }
                else { tempPicked.insert(card.id) }
            } label: {
                Image(systemName: tempPicked.contains(card.id) ? "heart.fill" : "heart")
            }
            .buttonStyle(.borderless)
            .foregroundColor(.pink)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}
