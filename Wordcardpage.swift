//
//
//
//
//  WordcardPage.swift — 完全同期修正版（2025/12）
//

//
//
//  Wordcardpage.swift  — 12/6 完全修復版 🍊（💕複数意味対応版）
//

import SwiftUI
import AVFoundation


 
// MARK: - 1行（表 or 裏）
 struct CardRow: View {

    // 品詞
    let pos: PartOfSpeech
    // 入力
    let word: String
    let meanings: [String]
    let irregularForms: [String]

    let examples: [ExampleEntry]
    let note: String?

    let isChecked: Bool
    let isFav: Bool
    let accent: Color

    @Binding var showBack: Bool

    // アクション
    let onToggleCheck: () -> Void
    let onToggleFav: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack {
            if !showBack {

                // -----------------
                // MARK: 表カード
                // -----------------
                HStack(alignment: .center, spacing: 12) {

                    // 左チェック
                    Button(action: onToggleCheck) {
                        Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(isChecked ? accent : .secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(word)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        // ⭐ 不規則動詞（verbのときだけ表示）
                           if pos == .verb,
                              let forms = IrregularVerbBank.forms(for: word),
                              forms.count >= 3 {
                               Text("\(forms[1])・\(forms[2])")
                                   .font(.system(size: 13, weight: .semibold))
                                   .foregroundStyle(.secondary)
                           }


                        if let first = meanings.first {
                            Text(first)
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // ♡
                    Button(action: onToggleFav) {
                        Image(systemName: isFav ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundStyle(isFav ? accent : .secondary)
                    }
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
                .onTapGesture { withAnimation { showBack = true } }

            } else {

                // MARK: 裏カード
                CardBackView(
                    pos: pos,
                    word: word,
                    meanings: meanings,
                    examples: examples,
                    note: note ?? "",
                    irregularForms: irregularForms
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    // カードをタップしたら表に戻す
                    withAnimation {
                        showBack = false
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
