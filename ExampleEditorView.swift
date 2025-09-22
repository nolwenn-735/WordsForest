//
//  ExampleEditorView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/23.
//


import SwiftUI

struct ExampleEditorView: View {
    @State var english: String
    @State var japanese: String
    var onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("英語") {
                TextField("English sentence", text: $english, axis: .vertical)
                    .lineLimit(3...6)
            }
            Section("日本語") {
                TextField("日本語訳", text: $japanese, axis: .vertical)
                    .lineLimit(3...6)
            }
            Section {
                Button("保存") {
                    onSave(english, japanese)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("例文を編集")
    }
}
