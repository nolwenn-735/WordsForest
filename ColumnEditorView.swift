//
//  ColumnEditorView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/12/21.
//

import SwiftUI

struct ColumnEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let initial: ColumnArticle
    let isNew: Bool
    let onSave: (ColumnArticle) -> Void

    @State private var title: String
    @State private var bodyText: String
    @State private var tagsText: String

    init(initial: ColumnArticle, isNew: Bool, onSave: @escaping (ColumnArticle) -> Void) {
        self.initial = initial
        self.isNew = isNew
        self.onSave = onSave
        _title = State(initialValue: initial.title)
        _bodyText  = State(initialValue: initial.body)
        _tagsText = State(initialValue: initial.tags.joined(separator: ", "))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("タイトル") {
                    TextField("例: on の感覚", text: $title)
                }

                Section("本文") {
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 220)
                }

                Section("タグ（カンマ区切り）") {
                    TextField("例: 前置詞, 感覚", text: $tagsText)
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle(isNew ? "コラム追加" : "コラム編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("戻る") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        let tags = tagsText
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }

                        let updated = ColumnArticle(
                            id: initial.id,
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            body: bodyText,
                            tags: tags
                        )
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
