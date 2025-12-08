//
//
//
//
//  WordcardPage.swift — 完全同期修正版（2025/12）
//

//
//
//  Wordcardpage.swift  — 12/6 完全修復版 🍊💕
//

import SwiftUI
import AVFoundation

// MARK: - 1画面ぶち抜き：品詞ごとのカード一覧
/*struct POSFlashcardListView: View {

    let pos: PartOfSpeech
    @State private var cards: [WordCard] = []
    @State private var dataVersion = 0
    @State private var expandedID: UUID? = nil   // ← 追加（表裏切り替え用）

    var body: some View {

        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(cards) { c in
                    POSFlashcardView(
                        card: c,
                        expandedID: $expandedID
                    )
                    .id(c.id)
                }
            }
            .padding(.vertical, 16)
        }
        .navigationTitle(pos.jaTitle)
        .onAppear { loadCards() }
        .onChange(of: dataVersion) { loadCards() }
        .onReceive(NotificationCenter.default.publisher(for: .storeDidChange)) { _ in
            dataVersion += 1
        }
    }

    private func loadCards() {
        cards = HomeworkStore.shared
            .list(for: pos)
            .filter { !$0.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}
*/
 
// MARK: - POSFlashcardView（1カード＝1語）
/*struct POSFlashcardView: View {

    let card: WordCard
    @Binding var expandedID: UUID?

    var body: some View {
        row(for: card, isExpanded: expandedID == card.id)
            .padding(.horizontal)
    }

    // MARK: 行生成（CardRow）
    @ViewBuilder
    private func row(for c: WordCard, isExpanded: Bool) -> some View {

        // 例文（複数対応）
        let examples = ExampleStore.shared.examples(for: c.word)

        // 不規則動詞
        let forms = (c.pos == .verb) ? (IrregularVerbBank.forms(for: c.word) ?? []) : []
        let displayWord = forms.isEmpty ? c.word : forms.joined(separator: " · ")
        let speakForms = forms.isEmpty ? [c.word] : forms

        // 学習状態
        let isChecked = HomeworkStore.shared.isLearned(c)
        let isFav = HomeworkStore.shared.isFavorite(c)

        CardRow(
            word: displayWord,
            meanings: c.meanings,
            irregularForms: speakForms,
            examples: examples,
            note: examples.first?.note ?? "",
            isChecked: isChecked,
            isFav: isFav,
            accent: c.pos.tileColor,

            showBack: Binding(
                get: { isExpanded },
                set: { newValue in
                    withAnimation(.spring(response: 0.25)) {
                        expandedID = newValue ? c.id : nil
                    }
                }
            ),

            onToggleCheck: {
                HomeworkStore.shared.toggleLearned(c)
            },
            onToggleFav: {
                HomeworkStore.shared.toggleFavorite(c)
            },
            onDelete: {
                HomeworkStore.shared.delete(c)
            }
        )
    }
}
*/
 
// MARK: - 1行（表 or 裏）
 struct CardRow: View {

    // 入力
    let word: String
    let meanings: [String]
    let irregularForms: [String]

    let examples: [ExampleEntry]
    let note: String?

    let isChecked: Bool
    let isFav: Bool
    let accent: Color

    @Binding var showBack: Bool

    // アクション
    let onToggleCheck: () -> Void
    let onToggleFav: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack {
            if !showBack {

                // -----------------
                // MARK: 表カード
                // -----------------
                HStack(alignment: .center, spacing: 12) {

                    // 左チェック
                    Button(action: onToggleCheck) {
                        Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(isChecked ? accent : .secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(word)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.primary)

                        if let first = meanings.first {
                            Text(first)
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // ♡
                    Button(action: onToggleFav) {
                        Image(systemName: isFav ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundStyle(isFav ? accent : .secondary)
                    }
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
                .onTapGesture { withAnimation { showBack = true } }

            } else {

                // MARK: 裏カード
                CardBackView(
                    word: word,
                    meanings: meanings,
                    examples: examples,
                    note: note ?? "",
                    irregularForms: irregularForms
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    // カードをタップしたら表に戻す
                    withAnimation {
                        showBack = false
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
