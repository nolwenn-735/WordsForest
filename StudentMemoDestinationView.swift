//
//  StudentMemoDestinationView.swift
//  WordsForest
//
//  Created by Nami .T on 2026/09/20.
//

import SwiftUI

struct StudentMemoDestinationView: View {

    let memoTitle: String
    let memoText: String

    @ObservedObject var store: StudentMemoStore

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {

                // MARK: - 新しいメモを作る
                Section {
                    Button {
                        createNewMemo()
                    } label: {
                        Label(
                            "新しいメモを作る",
                            systemImage: "plus.circle.fill"
                        )
                    }
                }

                // MARK: - 既存メモへ追加
                if !store.pages.isEmpty {
                    Section("既存のメモに追加") {
                        ForEach(store.pages) { page in
                            Button {
                                appendToMemo(page.id)
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {

                                    Text(displayTitle(for: page))
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    Text(
                                        page.updatedAt,
                                        format: .dateTime
                                            .year()
                                            .month()
                                            .day()
                                            .hour()
                                            .minute()
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("📝 メモへ送る")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }


    // MARK: - 新規メモ

    private func createNewMemo() {
        _ = store.createPage(
            title: memoTitle,
            body: memoText
        )

        dismiss()
    }


    // MARK: - 既存メモへ追加

    private func appendToMemo(_ id: UUID) {
        store.appendToPage(
            id: id,
            text: memoText
        )

        dismiss()
    }


    // MARK: - 表示用タイトル

    private func displayTitle(for page: StudentMemoPage) -> String {
        let trimmed = page.title
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmed.isEmpty ? "無題のメモ" : trimmed
    }
}
