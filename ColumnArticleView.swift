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
    let content: String   // ひとまずテキスト用。将来リッチ化可（見出し/画像挿入など）

    // ハスキー画像名（Assets の実名に合わせて調整してね）
    private let huskyImages = ["tutor_husky_stand", "tutor_husky_sit", "tutor_husky_down"]
    @State private var mascotName: String = "tutor_husky_stand"

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 背景：薄いネイビー
            Color.indigo.opacity(0.15).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // 黒の「🐺 Column」
                    Text("🐺 Column")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    // ネイビーの大きめ太字タイトル
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.indigo)
                        .padding(.bottom, 8)

                    // 本文（行間ちょい広め）
                    Text(content)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineSpacing(6)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 160) // マスコットにかぶらない余白
            }

            // 左下にハスキー（スクショの猫の反転位置）
            Image(mascotName)
                .resizable()
                .scaledToFit()
                .frame(width: 180)        // お好みで
                .shadow(radius: 8, y: 6)  // ほんのり立体感
                .padding(.leading, 16)
                .padding(.bottom, 20)
        }
        .onAppear {
            // 3種類をローテ（毎回ランダムでOKならこれ。固定したいなら AppStorage 等も可）
            if let pick = huskyImages.randomElement() {
                mascotName = pick
            }
        }
    }
}

// プレビュー
#Preview {
    ColumnArticleView(
        title: "5文型（ざっくり速習）",
        content: """
英語の基本的な文の型は S, V, O, C の並びで考えます。
S=主語, V=動詞, O=目的語, C=補語…

（ここに本文をどんどん書いていけます）
"""
    )
}
