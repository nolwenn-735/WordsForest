//
//  SpellingChallengeGameView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/31.
//

// SpellingChallengeGameView.swift
// WordsForest

import SwiftUI

struct SpellingChallengeGameView: View {
    let words: [SpellingWord]
    let difficulty: SpellingDifficulty

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var showHeart = false

    var body: some View {
        // ここでまず安全確認！
        if words.isEmpty {
            VStack(spacing: 16) {
                Text("出題できる単語がありません")
                Button("閉じる") { dismiss() }
            }
            .padding()
        } else {
            ZStack {
                // ===== メインの問題エリア =====
                VStack(spacing: 20) {

                    Spacer().frame(height: 28)

                    Text("問題 \(currentIndex + 1) / \(words.count)")
                        .font(.headline)

                    let current = words[currentIndex]
                    let letters = tiles(for: current.text)

                    HStack(spacing: 8) {
                        ForEach(letters, id: \.self) { ch in
                            Text(ch)
                                .font(.title2)
                                .frame(width: 42, height: 42)
                                .background(current.pos.tileColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 16)

                    Button("正解したことにする（仮）") {
                        handleCorrect()
                    }
                    .padding(.top, 12)

                    Spacer().frame(height: 120)
                }

                // ===== 画面下の常駐ハスキー =====
                VStack {
                    Spacer()
                    ZStack {
                        Image("tutor_husky_cock")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 160)

                        if showHeart {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.pink)
                                .offset(x: 60, y: -60)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 12)
                }
            }
            .animation(.easeInOut, value: showHeart)
        }
    }

    // MARK: - ロジック

    private func tiles(for word: String) -> [String] {
        var letters = Array(word.uppercased()).map { String($0) }
        if difficulty == .hard, let extra = word.misleadingLetter() {
            letters.append(String(extra).uppercased())
        }
        return letters.shuffled()
    }

    private func handleCorrect() {
        withAnimation(.spring) { showHeart = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation { showHeart = false }
            goNext()
        }
    }

    private func goNext() {
        if currentIndex + 1 < words.count {
            currentIndex += 1
        } else {
            dismiss()
        }
    }
}
