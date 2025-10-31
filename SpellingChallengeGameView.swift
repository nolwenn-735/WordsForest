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
    // ← ここがさっき消えちゃってた
    let words: [SpellingWord]
    let difficulty: SpellingDifficulty

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var showHeart = false

    var body: some View {
        // ① まず安全確認（0件で落ちないように）
        if words.isEmpty {
            VStack(spacing: 16) {
                Text("出題できる単語がありません")
                Button("閉じる") { dismiss() }
            }
            .padding()
        } else {
            ZStack {
                // ===== メインの問題エリア =====
                VStack(spacing: 6) {

                    Spacer().frame(height: 36)

                    // ② 毎回この問題を決める
                    let current = words[currentIndex]
                    let letters = tiles(for: current.text)

                    // 見出し
                    Text("問題 \(currentIndex + 1) / \(words.count)")
                        .font(.title2)
                        .fontWeight(.semibold)

                    // 日本語＋品詞（←さっきのやつ）
                    Text("\(current.pos.jaTitle)  \(current.meaningJa)")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 12)

                    // タイル
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

                    // 仮のボタン
                    Button("正解したことにする（仮）") {
                        handleCorrect()
                    }
                    .padding(.top, 12)

                    // ハスキーぶんの空き
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
        // 難しいモードのときだけ1文字混ぜる
        if difficulty == .hard, let extra = word.misleadingLetter() {
            letters.append(String(extra).uppercased())
        }
        return letters.shuffled()
    }

    private func handleCorrect() {
        withAnimation(.spring) {
            showHeart = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showHeart = false
            }
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
