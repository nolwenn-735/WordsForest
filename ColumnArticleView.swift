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
            // 背景（ラベンダー系ならお好みで）
            Color("othersPurple").opacity(0.15).ignoresSafeArea()
            
            // 本文
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // ここでは大きな見出しは入れず、本文タイトルから
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.indigo)
                        .padding(.bottom, 8)
                    
                    Text(content)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineSpacing(6)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 160)   // マスコットと重ならない余白
                .padding(.top, 68)       // ← 上部ヘッダーのぶん少し下げる（調整可）
            }
            
            // 左下ハスキー（復活✨）
            Image(mascotName)
                .resizable()
                .scaledToFit()
                .frame(width: 180)
                .shadow(radius: 8, y: 6)
                .padding(.leading, 16)
                .padding(.bottom, 20)
                .accessibilityHidden(true)
        }
        // ここで“アイランドのすぐ下”にぴったり来る自前ヘッダーを挿入
        .safeAreaInset(edge: .top) {
            HStack {
                // 戻る（純正と同じ丸ボタン風）
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                Spacer()
                // 中央タイトル（ここが高い位置に来る）
                HStack(spacing: 8) {
                    Text("🐺")
                    Text("Column")
                        .font(.system(size: 28, weight: .bold))
                }
                .accessibilityAddTraits(.isHeader)
                Spacer()
                // 右側はダミーのスペーサー（左右バランス用）
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 2)      // ← 高さの微調整（もう少し上げたければ 0〜2）
            .padding(.bottom, 8)   // ← ヘッダー下の余白
            .background(.clear)
        }
        // 既存の onAppear（ハスキーのローテ）
        .onAppear {
            if let pick = huskyImages.randomElement() {
                mascotName = pick
            }
        }
        // 重要：デフォのナビタイトルは使わない（重複防止）
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)  // ← 純正タイトル非表示
    }
    // プレビュー
    
    struct ColumnArticleView_Previews: PreviewProvider {
        static var previews: some View {
            // 実機と近い見た目で安全にレンダリング
            NavigationStack {
                ColumnArticleView(
                    title: "5文型（ざっくり速習）",
                    content: """
    英語の基本的な文の型は S, V, O, C の並びで考えます。
    S=主語, V=動詞, O=目的語, C=補語…
    
    （ここに本文をどんどん書いていけます）
    """
                )
            }
        }
    }
    }
