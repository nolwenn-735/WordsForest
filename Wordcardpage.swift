import SwiftUI

// 品詞ごとのフラッシュカード一覧に遷移する薄いラッパー
struct POSFlashcardListView: View {
    let pos: PartOfSpeech
    let accent: Color
    let animalName: String

    var body: some View {
        // ここで5件に絞る（数字を変えれば件数変更）
        let limited = Array(SampleDeck.filtered(by: pos).prefix(4))
        POSFlashcardView(
            title: "\(pos.rawValue) レッスン",
            cards: limited,
            accent: accent,
            animalName: animalName
        )
    }
}

// 単語カード画面（縦スクロール・右下に動物PNG）
struct POSFlashcardView: View {
    let title: String
    let cards: [WordCard]
    let accent: Color
    let animalName: String

    // ← 2) でも使うのでここに置く
    @State private var tempPicked: Set<String> = []

    var body: some View {
        ZStack {
            // 背景（単色）
            accent.ignoresSafeArea()

            // 本文
            ScrollView {
                // …カードなど（今は空でもOK）
            }

            // --- 右下の動物（少し大きめ & タップは透過）---
            GeometryReader { proxy in
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(animalName)                 // 例: "noun_bear_brown" など
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(
                                width: min(                // 画面に応じて自然に拡縮
                                    max(180, proxy.size.width * 0.35),
                                    220
                                )
                            )
                            .opacity(0.98)
                            .shadow(radius: 6, x: 0, y: 5)
                            .padding(.trailing, 18)       // ← 位置の細かい調整
                            .padding(.bottom, 14)
                            .accessibilityHidden(true)
                    }
                }
                .allowsHitTesting(false)                  // 下のスクロールやタップを邪魔しない
            }
            // --------------------------------------------
        }
        .navigationBarTitleDisplayMode(.inline)           // ← ZStack の “外”、body を閉じる前
    } // ← ここで body を閉じる（この下に関数などを続けてOK）
    
    
    
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
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

// 動物画像名のデフォルト（必要に応じて好きに変更OK）
private func animalNameFor(_ pos: PartOfSpeech) -> String {
    switch pos {
    case .noun: return "noun_bear_brown"
    case .verb: return "verb_cat_gray"
    case .adj:  return "adj_rabbit_white"
    case .adv:  return "adv_alpaca_ivory"
    }
}
