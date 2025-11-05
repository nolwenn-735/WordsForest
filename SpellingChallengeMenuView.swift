//
//  SpellingChallengeMenuView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/31.
//

// SpellingChallengeMenuView.swift
// WordsForest


import SwiftUI

//enum SpellingDifficulty: String, Identifiable { case easy, hard; var id: String { rawValue } }

struct SpellingChallengeMenuView: View {
    // 閉じるボタン用
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDifficulty: SpellingDifficulty = .easy
    @State private var goSelect = false

    // ✅ ここを既存の「My Collection取得」に差し替えて下さい
    private var favoriteList: [WordCard] {
        HomeworkStore.shared.favoriteList()
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        goSelect = true
                    } label: {
                        HStack {
                            Text("💗 My Collection から出題")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Section("問題の難易度") {
                    difficultyRow(.easy, label: "⭐️ 使う文字だけ")
                    difficultyRow(.hard, label: "⭐️⭐️ いらない文字1つあり")
                }
            }
            .navigationTitle("✏️ スペリングチャレンジ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    }label: {
                        Text("閉じる")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                }
            }
            // ⤵️ 遷移先
                        .navigationDestination(isPresented: $goSelect) {
                            MyCollectionSelectionView(
                                collection: favoriteList,
                                selectedDifficulty: $selectedDifficulty
                            )
                        }
                    }
                    // シートっぽいインジケータ（任意）
                    .presentationDragIndicator(.visible)
                }
            
            
    @ViewBuilder
    private func difficultyRow(_ value: SpellingDifficulty, label: String) -> some View {
        Button {
            selectedDifficulty = value
        } label: {
            HStack {
                Image(systemName: selectedDifficulty == value ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selectedDifficulty == value ? Color.blue : Color.secondary) // ←青
                Text(label)
            }
        }
        .foregroundStyle(.primary)
    }
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

