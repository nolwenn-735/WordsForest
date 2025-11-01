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
        // 出題できる単語がないときの安全ガード
        if words.isEmpty {
            VStack(spacing: 16) {
                Text("出題できる単語がありません")
                Button("閉じる") { dismiss() }
            }
            .padding()
        } else {
            GeometryReader { geo in
                // ここで高さ・幅と current を先に作る
                let h = geo.size.height
                let w = geo.size.width
                let current = words[currentIndex]
                

                ZStack {
                    // ===== ① 一番上のタイトル「問題 1/5」 =====
                    VStack(spacing: 4) {
                        Text("問題 \(currentIndex + 1) / \(words.count)")
                            .font(.system(size: 30, weight: .semibold))  // ←目立たせる
                        Text("\(current.pos.jaTitle)　\(current.meaningJa)")
                            .font(.title3)
                            .foregroundStyle(.primary)
                            .padding(.top, 16)
                    }
                    .frame(maxWidth: .infinity)
                    // 画面の上からだいたい 12% のところ
                    .position(x: w / 2, y: h * 0.12)

                    // ===== ② 日本語の下〜タイル〜ボタンのかたまり =====
                    VStack(spacing: 16) {

                        // タイル
                        let letters = tiles(for: current.text)
                        let tileWidth: CGFloat = min(60, 300 / CGFloat(letters.count))

                        HStack(spacing: 8) {
                            ForEach(letters, id: \.self) { ch in
                                Text(ch)
                                    .font(.title2)
                                    .frame(width: tileWidth, height: tileWidth)
                                    .background(current.pos.tileColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 16)

                        Button("正解したことにする（仮）") {
                            handleCorrect()
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    // 画面のだいたい 40% あたりに置く（＝真ん中よりちょい上）
                    .position(x: w / 2, y: h * 0.40)

                    // ===== ③ いちばん下のハスキー =====
                    VStack {
                        Spacer()
                        ZStack {
                            Image("tutor_husky_cock")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 180)

                            if showHeart {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 42))
                                    .foregroundStyle(.pink)
                                    .offset(x: 60, y: -70)
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
        withAnimation(.spring) {
            showHeart = true
        }
        // 1秒くらい表示してから次へ
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
