//
//  StudentMemoListView.swift
//  WordsForest
//
//  Created by Nami .T on 2026/09/19.
//

import SwiftUI

struct StudentMemoListView: View {

    @ObservedObject var store: StudentMemoStore
    
    @State private var pendingDeleteID: UUID?
    @State private var showDeleteConfirmation = false
    @State private var newlyCreatedPageID: UUID?
    @State private var showBackupExporter = false
    @State private var backupFile = StudentMemoBackupFile(data: Data())
    @State private var backupErrorMessage: String?

    var body: some View {
        List {
            if store.pages.isEmpty {
                ContentUnavailableView(
                    "まだメモがありません",
                    systemImage: "note.text",
                    description: Text("右上の＋から新しいページを作れます。")
                )
            } else {
                ForEach(store.pages) { page in
                    NavigationLink {
                        StudentMemoEditorView(
                            pageID: page.id,
                            store: store
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {

                            Text(displayTitle(for: page))
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text(page.updatedAt, format: .dateTime
                                .year()
                                .month()
                                .day()
                                .hour()
                                .minute()
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            if !page.body
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                .isEmpty {

                                Text(page.body)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .swipeActions(
                        edge: .trailing,
                        allowsFullSwipe: false
                    ) {
                        Button(role: .destructive) {
                            pendingDeleteID = page.id
                            showDeleteConfirmation = true
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("📝 メモ")
        .navigationDestination(item: $newlyCreatedPageID) { pageID in
            StudentMemoEditorView(
                pageID: pageID,
                store: store
            )
        }
        .alert(
            "このメモを削除しますか？",
            isPresented: $showDeleteConfirmation
        ) {
            Button("キャンセル", role: .cancel) {
                pendingDeleteID = nil
            }

            Button("削除", role: .destructive) {
                if let id = pendingDeleteID {
                    store.deletePage(id: id)
                }

                pendingDeleteID = nil
            }
        } message: {
            Text("削除したメモは元に戻せません。")
        }
        .toolbar {

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        exportBackup()
                    } label: {
                        Label(
                            "メモをバックアップ",
                            systemImage: "externaldrive"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("メモのその他の操作")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    createNewPage()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("新しいメモ")
            }
        }
        .fileExporter(
            isPresented: $showBackupExporter,
            document: backupFile,
            contentType: .json,
            defaultFilename: backupFileName
        ) { result in
            switch result {
            case .success:
                break

            case .failure(let error):
                backupErrorMessage = error.localizedDescription
            }
        }
        .alert(
            "バックアップできませんでした",
            isPresented: Binding(
                get: { backupErrorMessage != nil },
                set: { newValue in
                    if !newValue {
                        backupErrorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                backupErrorMessage = nil
            }
        } message: {
            Text(backupErrorMessage ?? "")
        }
    }


    // MARK: - 表示用タイトル

    private func displayTitle(for page: StudentMemoPage) -> String {
        let trimmed = page.title
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmed.isEmpty ? "無題のメモ" : trimmed
    }


    // MARK: - 新規ページ

    private func createNewPage() {
        newlyCreatedPageID = store.createPage()
    }
    // MARK: - メモのバックアップ

    private func exportBackup() {
        do {
            let data = try store.makeBackupData()

            backupFile = StudentMemoBackupFile(
                data: data
            )

            showBackupExporter = true

        } catch {
            backupErrorMessage = error.localizedDescription
        }
    }


    private var backupFileName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        let dateText = formatter.string(from: Date())

        return "WordsForest-Memo-Backup-\(dateText)"
    }
}
