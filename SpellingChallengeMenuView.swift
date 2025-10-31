//
//  SpellingChallengeMenuView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/31.
//

// SpellingChallengeMenuView.swift
// WordsForest

import SwiftUI

struct SpellingChallengeMenuView: View {
    @Environment(\.dismiss) private var dismiss

    // ここでさっきの共通enumを使うだけ
    @State private var selectedDifficulty: SpellingDifficulty = .easy
    @State private var showGame = false
    @State private var gameWords: [SpellingWord] = []
    @State private var showNoWordsAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                Text("✏️ スペリング・チャレンジ")
                    .font(.title2)
                    .padding(.top, 12)

                Text("出題のやりかたを選んでね")
                    .foregroundStyle(.secondary)

                // MARK: - My Collection から出題
                Button {
                    loadFromMyCollection()
                } label: {
                    HStack(alignment: .center, spacing: 4) {   // ← .leadingじゃなくて.center
                        Text("My Collection から出題")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    Text("💗ハートをつけた単語からランダムで5問")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )

                // MARK: - レベルを選んでね
                VStack(alignment: .leading, spacing: 12) {
                    Text("レベルを選んでね")
                        .font(.headline)

                    levelRow(
                        icon: "star.fill",
                        iconColor: .blue,
                        title: "★ 全部必要なアルファベットだけ",
                        isSelected: selectedDifficulty == .easy
                    ) {
                        selectedDifficulty = .easy
                    }

                    levelRow(
                        icon: "star.leadinghalf.filled",
                        iconColor: .orange,
                        title: "★ 紛らわしいアルファベットを1つ混入",
                        isSelected: selectedDifficulty == .hard
                    ) {
                        selectedDifficulty = .hard
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                Button("閉じる") {
                    dismiss()
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 20)
            .alert("My Collection が空です", isPresented: $showNoWordsAlert) {
                Button("OK", role: .cancel) { }
            }
            // ゲームへ
            .sheet(isPresented: $showGame) {
                SpellingChallengeGameView(
                    words: gameWords,
                    difficulty: selectedDifficulty
                )
            }
        }
    }

    // MARK: - My Collection 読み込み
    private func loadFromMyCollection() {
        // ① Nolwennの現状コードから取ってくる
        let cards = HomeworkStore.shared.favoriteList()

        // ② なにもなかったらアラート
        guard !cards.isEmpty else {
            showNoWordsAlert = true
            return
        }

        // ③ 最大5件だけ使う
        let picked = Array(cards.prefix(5))

        // ④ WordCard → SpellingWord に変換
        gameWords = picked.map {
            SpellingWord(text: $0.word, pos: $0.pos)
        }

        // ⑤ ゲームをひらく
        showGame = true
    }

    // MARK: - レベル1行分
    private func levelRow(
        icon: String,
        iconColor: Color,
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)

                Text(title)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color(.systemGray5) : .clear)
            )
        }
    }
}
