import SwiftUI
// Wordcardpage.swift のどこか（import SwiftUI の下あたり）に
struct WordItem: Identifiable, Hashable { let id = UUID(); let text: String }

struct WordCardPage: View {
    let pos: PartOfSpeech
    let baseVariantIndex: Int
    let items: [WordItem]

    var body: some View {
        // とりあえずの仮実装（あとで本実装に差し替え）
        List(items) { it in Text(it.text) }
            .navigationTitle("🐻\(pos.rawValue) レッスン")
    }
}
struct POSFlashcardListView: View {
    let pos: PartOfSpeech
    let accent: Color
    let animalName: String

    var body: some View {
        // ここで List や VStack の余白を作らず、目的の画面をそのまま表示
        let limited = Array(SampleDeck.filtered(by: pos).prefix(4))
        POSFlashcardView(
            title: "🐻 \(pos.rawValue) レッスン",
            cards: limited,
            accent: accent,
            animalName: animalName
        )
        // 余白や枠になる修飾子（.padding など）は絶対につけない！
    }
}
// 単語カード画面（縦スクロール・右下に動物PNG）
// 単語カード1画面（縦スクロール＋右下にマスコット固定）
struct POSFlashcardView: View {
    let title: String
    let cards: [WordCard]      // 既存の型名。ここは使ってなくてもOK
    let accent: Color          // 画面のテーマ色（ピンクなど）
    let animalName: String     // 例: "noun_bear_brown"

    var body: some View {
        ZStack(alignment: .bottomTrailing) {

            // ① 背景（端まで）
            accent.ignoresSafeArea()

            // ② 中央の内容（いまは空でもOK）
            ScrollView {
                VStack(spacing: 16) {
                    // TODO: カードUIや見出しを置く
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 120) // ← クマさん分の余白
            }
            .scrollContentBackground(.hidden) // ScrollViewの白地を隠す
            .background(Color.clear)
            .scrollIndicators(.hidden)

            // ③ 右下マスコット（タップは透過）
            Image(animalName)
                .resizable()
                .scaledToFit()
                .frame(width: 180)
                .shadow(radius: 6, y: 6)
                .padding(24)
                .allowsHitTesting(false)
        }
        
        .navigationTitle(Text(" \(title) レッスン")) // ④ ナビの見た目を同色に
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(accent, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
