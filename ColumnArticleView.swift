//
//  ColumnArticleView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/24.
//
import SwiftUI

/// 🐺 コラム記事 用テンプレ
struct ColumnArticleView: View {
    let title: String
    let content: String
    private let huskyImages = ["tutor_husky_stand","tutor_husky_sit","tutor_husky_down"]
    @State private var mascotName = "tutor_husky_stand"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 背景
            Color("othersPurple")
                .opacity(0.15)
                .ignoresSafeArea()

            let mascotHeight: CGFloat = 140
            let bottomMargin: CGFloat = 40 // ハスキー上の余白
            // 本文
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // 🖋️(🙃) 紫タイトルをちょっと小さくして上に寄せる
                    Text(title)
                        .font(.system(size: 22, weight: .semibold))   // ← 28 → 22 に
                        .foregroundStyle(.indigo)
                        .padding(.bottom, 4)

                    Text(content)
                        .font(.body)                  // ← ここは本文だからそのまま
                        .foregroundStyle(.primary)
                        .lineSpacing(4)               // ← 6 だったのを 4 にして詰める
                }
                .padding(.horizontal, 20)
                .padding(.top, 0)          //ハスキー下げる
                .padding(.bottom, mascotHeight + bottomMargin)  // ←ここで使う！
            }

            // 🐺 左下ハスキー
            Image(mascotName)
                .resizable()
                .scaledToFit()
                .frame(width: 140)
                .shadow(radius: 8, y: 6)
                .padding(.leading, 16)
                .padding(.bottom, 0)     // ← 20 → 40 にして「5mm下げる」イメージ
                .accessibilityHidden(true)
        }
        // 上のカスタムヘッダー
        .safeAreaInset(edge: .top) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                Spacer()
                HStack(spacing: 8) {
                    Text("🐺")
                    Text("Column")
                        .font(.system(size: 28, weight: .bold))
                }
                .accessibilityAddTraits(.isHeader)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 2)
            .padding(.bottom, 8)
            .background(.clear)
        }
        .onAppear {
            if let pick = huskyImages.randomElement() {
                mascotName = pick
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - プレビュー
#Preview {
    NavigationStack {
        ColumnArticleView(
            title: "No.1 ５文型（ざっくり速習）",
            content: """
英語の基本的な文の型は S, V, O, C の並びで考えます。
S=主語, V=動詞, O=目的語, C=補語…

（ここに本文をどんどん書いていけます）
"""
        )
    }
}
