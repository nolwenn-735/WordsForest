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

        // お気に入りキー（WordKey の集合）
        let favKeys = HomeworkStore.shared.favorites

        // Favorite に該当する StoredWord だけを残す
        let favStored = stored.filter { favKeys.contains( HomeworkStore.shared.key(for: $0) ) }

        // 単語ごとに group
        let grouped = Dictionary(grouping: favStored, by: { $0.word })

        // WordCard に再構成（複数意味まとめ）
        let cards: [WordCard] = grouped.values.compactMap { group in
            guard let first = group.first else { return nil }
            return WordCard(
                pos: first.pos,                      // ★順番1
                word: first.word,                    // ★順番2
                meanings: group.map { $0.meaning }   // ★順番3
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
                    difficultyRow(.easy,
                                  label: "⭐️ 使う文字だけ")
                    difficultyRow(.hard,
                                  label: "⭐️⭐️ いらない文字1つあり")
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

        // ===== 単語選択シート =====
        .sheet(isPresented: $showSelection) {
            MyCollectionSelectionView(
                collection: favoriteList,
                selectedDifficulty: $selectedDifficulty,
                selectedIDs: $selectedIDs
            ) { chosen in
                // 5件ちゃんと来てる前提（子ビュー側で保証済み）
                let words = chosen.map(SpellingWord.init(card:))
                guard !words.isEmpty else { return }

                gameWords = words
                showSelection = false

                // 単語が入っているときだけゲームを開く
                DispatchQueue.main.async {
                    showGame = true
                }
            }
        }

        // ===== ゲーム画面シート =====
        .sheet(
            isPresented: Binding(
                get: { showGame && !gameWords.isEmpty },
                set: { newValue in
                    if !newValue { showGame = false }
                }
            )
        ) {
            SpellingChallengeGameView(
                words: gameWords,
                difficulty: selectedDifficulty
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
}

