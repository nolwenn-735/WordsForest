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
    @State private var selectedIDs: Set<UUID> = []  // ← チェック保持（新しく追加）
    @State private var goSelect = false            // ← 遷移フラグ（既存のままOK）
    
    // ✅ ここを既存の「My Collection取得」に差し替えて下さい
    private var favoriteList: [WordCard] {
        HomeworkStore.shared.favoriteList()
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        selectedIDs.removeAll()
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
            .onChange(of: goSelect) { old, new in
                if new {
                    selectedIDs.removeAll()  // ← 開く直前にチェック初期化
                }
            }
            // ⤵️ 遷移先
            .navigationDestination(isPresented: $goSelect) {
                MyCollectionSelectionView(
                    collection: favoriteList,
                    difficulty: selectedDifficulty,   // ← $なし！値を渡すだけ
                    selectedIDs: $selectedIDs,
                    onStart: { chosen in
                        let words = chosen.map(SpellingWord.init(card:))
                        // TODO: wordsとselectedDifficultyをGameVIewに渡して遷移
                    }
                )
       
            }
            
            // シートっぽいインジケータ（任意）
            .presentationDragIndicator(.visible)
        }
    }
        
    @ViewBuilder
    private func difficultyRow(_ value: SpellingDifficulty, label: String) -> some View {
        Button {
            selectedDifficulty = value
        } label: {
            HStack(spacing: 8) {
                Image(systemName: selectedDifficulty == value
                      ? "largecircle.fill.circle"
                      : "circle")
                    .foregroundStyle(selectedDifficulty == value ? Color.blue : .secondary)
                Text(label)
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
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
    

