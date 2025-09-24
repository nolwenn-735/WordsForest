//
//  SwiftUIView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/24.
//

import SwiftUI

struct AddWordView: View {
    let pos: PartOfSpeech                      // ← 受け取った品詞
    @Environment(\.dismiss) private var dismiss
    @State private var word = ""
    @State private var meaning = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("英単語") {
                    TextField("wander", text: $word)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section("日本語の意味") {
                    TextField("さまよう", text: $meaning)
                }
            }
            .navigationTitle("単語を追加")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        let w = word.trimmingCharacters(in: .whitespacesAndNewlines)
                        let m = meaning.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !w.isEmpty, !m.isEmpty else { return }

                        HomeworkStore.shared.add(word: w, meaning: m, pos: pos) // ← 保存！
                        dismiss() // sheet を閉じる（これで一覧が再描画されます）
                    }
                }
            }
        }
    }
}
