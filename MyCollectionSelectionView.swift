//
//  MyCollectionSelectionView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/11/04.
//

import SwiftUI

struct MyCollectionSelectionView: View {
    let collection: [WordCard]
    @Binding var selectedDifficulty: SpellingDifficulty
    @Environment(\.dismiss) private var dismiss
    @State private var goGame = false
    @State private var gameWords: [SpellingWord] = []
    @State private var selected = Set<UUID>()   // 選択中のWordCard.id
    private let maxPick = 5

    var body: some View {
        VStack(spacing: 12) {
            // ヘッダ
            VStack(spacing: 4) {
                Text("💗 My Collection から 5つ選んでね")
                    .font(.title3).bold()
                Text("選択中：\(selected.count) / \(maxPick)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)

            // 単語リスト
            List(collection) { card in
                Button { toggle(card.id) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(card.word).font(.headline)
                            Text("\(card.pos.jaTitle)　\(card.meaning)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: selected.contains(card.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selected.contains(card.id) ? Color.pink : Color.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)

            // 難易度（選び直しOK）
            VStack(spacing: 6) {
                Text("問題の難易度")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    difficultyChip(.easy, "⭐️ 使う文字だけ")
                    difficultyChip(.hard, "⭐️⭐️ いらない文字1つあり")
                }
            }
            .padding(.vertical, 4)

            // 開始ボタン
            Button {
                // ちょうど5つ選ばれている前提（ボタンは count != 5 で無効化済み）
                let chosen = collection.filter { selected.contains($0.id) }
                // WordCard -> SpellingWord に変換
                gameWords = chosen.map(SpellingWord.init(card:))
                // ナビ遷移フラグON
                goGame = true
            } label: {
                Text("✅ スペリングチャレンジ開始！")
            }
            .buttonStyle(.borderedProminent)
            .disabled(selected.count != maxPick)
            // キャンセル
            Button("キャンセル") { dismiss() }
                .padding(.bottom, 8)
        }
        .padding(.horizontal)
        .navigationTitle("💗 My Collection")         // ★ タイトル（戻るの横）
        .navigationBarTitleDisplayMode(.inline)
        .tint(.blue)                                  // ★ 戻る矢印やリンクを青に統一
        .navigationBarBackButtonHidden(true)   // デフォルトの戻るを隠す
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                    }
                }
                .tint(.blue)  // ← これで青に統一！
            }
        }
        .navigationDestination(isPresented: $goGame) {
            SpellingChallengeGameView(
                words: gameWords,
                difficulty: selectedDifficulty
            )
        }
    }

    private func toggle(_ id: UUID) {
        if selected.contains(id) {
            selected.remove(id)
        } else if selected.count < maxPick {
            selected.insert(id)
        }
    }

    @ViewBuilder
    private func difficultyChip(_ value: SpellingDifficulty, _ title: String) -> some View {
        Button { selectedDifficulty = value } label: {
            HStack(spacing: 6) {
                Image(systemName: selectedDifficulty == value ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selectedDifficulty == value ? Color.blue : Color.secondary)
                Text(title)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedDifficulty == value ? Color(.systemGray6) : .clear)
            )
        }
        .buttonStyle(.plain)
    }
}
