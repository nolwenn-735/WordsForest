//
//  SwiftUIView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/24.
//

import SwiftUI

struct AddWordView: View {
    let pos: PartOfSpeech
    var editing: WordCard? = nil   // ← 既存なら渡す（新規は nil）

    @Environment(\.dismiss) private var dismiss
    @State private var word: String = ""
    @State private var meaning: String = ""
    @State private var dupWord = false
    @State private var dupExact = false

    private var trimmedWord: String { word.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedMeaning: String { meaning.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedWord.isEmpty && !trimmedMeaning.isEmpty }

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
            
            .onChange(of: word,    initial: true) { _, _ in
                updateDupFlags()
            }
            .onChange(of: meaning) { _, _ in
                updateDupFlags()
            }
            .navigationTitle(editing == nil ? "単語を追加" : "単語を編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editing == nil ? "追加" : "更新") {
                        save()
                    }
                    .disabled(!canSave || dupExact)
                }
            }
            // 編集時だけフッターに「削除」を表示
            .safeAreaInset(edge: .bottom) {
                if editing != nil {
                    Button("このカードを削除", role: .destructive) {
                        deleteCard()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .onAppear {
            if let c = editing {
                word = c.word
                meaning = c.meaning
            }
        }
    }

    private func save() {
        if let c = editing {
            // 既存カードを更新（メソッド名はプロジェクトに合わせて）
            HomeworkStore.shared.update(c, word: trimmedWord, meaning: trimmedMeaning)
        } else {
            // 新規追加
            HomeworkStore.shared.add(word: trimmedWord, meaning: trimmedMeaning, pos: pos)
        }
        dismiss()
    }

    private func updateDupFlags() {
        let w = trimmedWord
            let m = trimmedMeaning
            guard !w.isEmpty else {
                dupWord = false
                dupExact = false
                return
            }
            dupWord  = HomeworkStore.shared.exists(word: w, pos: pos)
            dupExact = HomeworkStore.shared.exists(word: w, meaning: m, pos: pos)
    }
    
    private func deleteCard() {
        if let c = editing {
            HomeworkStore.shared.delete(c)
            dismiss()
        }
    }
}
