//
//  SpellingChallengeMenuView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/31.
//


import SwiftUI

struct SpellingChallengeMenuView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDifficulty: SpellingDifficulty = .easy
    @State private var selectedMoveSpeed: SpellingMoveSpeed = .relaxed
    @State private var selectedIDs: Set<UUID> = []

    // シート制御
    @State private var showSelection = false      // 単語選択
    @State private var showGame = false           // ゲーム

    // ゲーム用の単語
    @State private var gameWords: [SpellingWord] = []

    // My Collection
    // My Collection（お気に入り WordCard を構築）
    private var favoriteList: [WordCard] {

        // HomeworkStore に保存されているすべての StoredWord
        let stored = HomeworkStore.shared.words

        let favIDs = HomeworkStore.shared.favoriteIDs
        let favStored = stored.filter { favIDs.contains($0.id) }
        let grouped = Dictionary(grouping: favStored, by: { "\($0.pos.rawValue)|\($0.word)" })

        // WordCard に再構成（複数意味まとめ）
        let cards: [WordCard] = grouped.values.compactMap { group in
            guard let first = group.first else { return nil }
            let meanings = group.map(\.meaning).sorted()

            return WordCard(
                id: first.id,          // ← これ大事（UUID引き継ぎ）
                pos: first.pos,
                word: first.word,
                meanings: meanings
            )
        }

        // アルファベット順で返す
        return cards.sorted { $0.word < $1.word }
    }
    var body: some View {
        NavigationStack {
            List {
                // My Collection から出題
                Section {
                    Button {
                        selectedIDs.removeAll()
                        showSelection = true
                    } label: {
                        HStack {
                            Text("💗 My Collection から出題")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                // 難易度
                Section("問題の難易度") {
                    difficultyRow(.easy, label: "⭐️ 使う文字だけ")
                    difficultyRow(.hard, label: "⭐️⭐️ いらない文字1つあり")
                }

                // 操作スピード
                Section("タイルを動かす速さ") {
                    moveSpeedRow(.relaxed, label: "🐢 ゆっくり")
                    moveSpeedRow(.quick, label: "🐇 速め")
                }
            }
            .navigationTitle("✏️ スペリングチャレンジ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showSelection) {
            MyCollectionSelectionView(
                collection: favoriteList,
                selectedDifficulty: $selectedDifficulty,
                selectedIDs: $selectedIDs
            ) { chosen in
                let words = chosen.map(SpellingWord.init(card:))
                guard !words.isEmpty else { return }

                gameWords = words
                showSelection = false

                DispatchQueue.main.async {
                    showGame = true
                }
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { showGame && !gameWords.isEmpty },
                set: { newValue in
                    if !newValue { showGame = false }
                }
            )
        ) {
            SpellingChallengeGameView(
                words: gameWords,
                difficulty: selectedDifficulty,
                moveSpeed: selectedMoveSpeed
            )
        }
    }
    // ラジオボタン風の難易度行
    @ViewBuilder
    private func difficultyRow(_ value: SpellingDifficulty,
                               label: String) -> some View {
        Button {
            selectedDifficulty = value
        } label: {
            HStack(spacing: 8) {
                Image(systemName: selectedDifficulty == value
                      ? "largecircle.fill.circle"
                      : "circle")
                    .foregroundStyle(selectedDifficulty == value ? .blue : .secondary)
                Text(label)
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func moveSpeedRow(_ value: SpellingMoveSpeed,
                              label: String) -> some View {
        Button {
            selectedMoveSpeed = value
        } label: {
            HStack(spacing: 8) {
                Image(systemName: selectedMoveSpeed == value
                      ? "largecircle.fill.circle"
                      : "circle")
                    .foregroundStyle(selectedMoveSpeed == value ? .blue : .secondary)
                Text(label)
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }    
}

