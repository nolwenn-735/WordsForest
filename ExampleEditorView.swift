//
//  ExampleEditorView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/23.
//

import SwiftUI

struct ExampleEditorView: View {
    let word: String
    @Environment(\.dismiss) private var dismiss

    @State private var en   = ""
    @State private var ja   = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("英語") {
                    TextField("English sentence", text: $en)
                        .textInputAutocapitalization(.sentences)
                }
                Section("日本語") {
                    TextField("日本語訳", text: $ja)
                }
                Section("備考") {
                    TextEditor(text: $note)
                        .frame(minHeight: 220)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.secondary.opacity(0.2))
                        )
                }
            }
            .navigationTitle("例文を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 戻る
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("戻る") { dismiss() }
                }
                // 保存
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        let enT = en.trimmingCharacters(in: .whitespacesAndNewlines)
                        let jaT = ja.trimmingCharacters(in: .whitespacesAndNewlines)
                        let noT = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        ExampleStore.shared.setExample(
                            for: word,
                            en: enT, ja: jaT,
                            note: noT.isEmpty ? nil : noT
                        )
                        dismiss()
                    }
                }
                // 削除（お好みで残す）
                ToolbarItem(placement: .bottomBar) {
                    Button("この例文を削除", role: .destructive) {
                        ExampleStore.shared.removeExample(for: word)
                        dismiss()
                    }
                }
            }
            .onAppear {
                let saved = ExampleStore.shared.example(for: word)
                en   = saved?.en   ?? ""
                ja   = saved?.ja   ?? ""
                note = saved?.note ?? ""
            }
        }
        // スワイプダウンで閉じる（必要なら）
        .interactiveDismissDisabled(false)
    }
}
