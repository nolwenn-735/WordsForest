//
//  MyCollectionSelectionView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/11/04.
//

import SwiftUI

struct MyCollectionSelectionView: View {
    let collection: [WordCard]
    @Binding var selectedDifficulty: SpellingDifficulty
    @Binding var selectedIDs: Set<UUID>
    let onStart: ([WordCard]) -> Void
    @Environment(\.dismiss) private var dismiss
    private let maxPick = 5
    
    var body: some View {
        VStack(spacing: 12) {
            // ヘッダ
            VStack(spacing: 4) {
                Text("💗 My Collection から 5つ選んでね")
                    .font(.title3).bold()
                Text("選択中：\(selectedIDs.count) / \(maxPick)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            
            // 単語リスト
            List(collection) { card in
                Button { toggle(card.id) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(card.word).font(.headline)
                            Text("\(card.pos.jaTitle)　\(card.meanings.joined(separator: " / "))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: selectedIDs.contains(card.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedIDs.contains(card.id) ? Color.pink : Color.secondary)
                    }
                    .contentShape(Rectangle())      // ← 行のどこを押しても反応
                }
                .disabled(selectedIDs.count >= maxPick && !selectedIDs.contains(card.id))
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            
            // 難易度表示（読み取り専用でOK）
            Text(
                selectedDifficulty == .easy
                    ? "難易度：⭐️ 使う文字だけ"
                    : "難易度：⭐️⭐️ いらない文字1つあり"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.bottom, 4)
                     
            // 開始ボタン
            Button {
                // ちょうど5つ選ばれている前提（ボタンは count != 5 で無効化済み）
                let chosen = collection.filter { selectedIDs.contains($0.id) }
                guard chosen.count == maxPick else { return } // 必要に応じてガード
                onStart(chosen)
            } label: {
                Text("✅ スペリングチャレンジ開始！")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedIDs.count != maxPick)
            .opacity(selectedIDs.count == maxPick ? 1 : 0.5)
            .animation(.default, value: selectedIDs.count)
            
            // キャンセル
            Button("キャンセル") { dismiss() }
                .padding(.bottom, 8)
        }
        .padding(.horizontal)
        .navigationTitle("💗 My Collection")        // ★ タイトル（戻るの横）       
        .navigationBarTitleDisplayMode(.inline)
        .tint(.blue)                                  // ★ 戻る矢印やリンクを青に統一
        .navigationBarBackButtonHidden(true)   // デフォルトの戻るを隠す
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                    }
                }
                .tint(.blue)  // ← これで青に統一！
            }
        }
    }
    
    
    private func toggle(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else if selectedIDs.count < maxPick {
            selectedIDs.insert(id)
        }
    }
}
    

