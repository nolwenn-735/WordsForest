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
                }
            }
            .navigationTitle("例文を編集")
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

                        ExampleStore.shared.saveExample(
                            for: word,
                            en: enT,
                            ja: jaT.isEmpty ? nil : jaT,
                            note: noT.isEmpty ? nil : noT
                        )
                        dismiss()
                    }
                }
                // 削除
                ToolbarItem(placement: .bottomBar) {
                    Button("この例文を削除", role: .destructive) {
                        // 今は「その単語のすべての例文を削除」する簡易仕様
                        ExampleStore.shared.removeExample(for: word)
                           dismiss()
                    }
                }
            }
            .onAppear {
                let saved = ExampleStore.shared.examples(for: word).first
                en = saved?.en ?? ""
                ja = saved?.ja ?? ""
                note = saved?.note ?? ""
            }
        }
    }
}
