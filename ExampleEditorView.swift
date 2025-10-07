//
//  ExampleEditorView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/23.
//


// ExampleEditorView.swift
import SwiftUI

struct ExampleEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State var english: String
    @State var japanese: String
    var onSave: (_ en: String, _ ja: String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("英語") {
                    TextField("English sentence", text: $english, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                }
                Section("日本語") {
                    TextField("日本語訳", text: $japanese, axis: .vertical)
                }
            }
            .navigationTitle("例文を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("← return") {
                        onSave(english, japanese)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        onSave(english, japanese)
                        dismiss()
                    }
                }
            }
        }
    }
}
