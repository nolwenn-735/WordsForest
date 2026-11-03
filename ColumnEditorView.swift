//
//Created by Nami .T on 2025/12/21.
//
//  ColumnEditorView.swift
//  WordsForest
//

import SwiftUI

struct ColumnEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let initial: ColumnArticle
    let isNew: Bool
    let onSave: (ColumnArticle) -> Void
    let onDelete: ((ColumnArticle) -> Void)?

    @State private var title: String
    @State private var bodyText: String
    @State private var tagsText: String
    @State private var exportDoc: JSONTextDocument? = nil
    @State private var exportFileName: String = "column.json"
    @State private var showingExporter = false
    @State private var exportErrorMessage: String? = nil
    @State private var showingDeleteConfirm = false
    @State private var pendingNoticeManifest: DeliveryManifest? = nil
    @State private var showNoticeExportConfirm = false
    @AppStorage("notice_lastColumnID") private var lastExportedColumnID: Int = 0
    @State private var pendingExportedColumnID: Int? = nil
    @State private var hasExportedCurrentColumn = false
    @AppStorage("notice_lastHomeworkPayloadID") private var lastExportedHomeworkPayloadID: String = ""
    @AppStorage("notice_lastHomeworkDateText") private var lastExportedHomeworkDateText: String = ""
    @AppStorage("notice_lastHomeworkLabel") private var lastExportedHomeworkLabel: String = ""
    @AppStorage("notice_lastHomeworkCount") private var lastExportedHomeworkCount: Int = 0

    init(
        initial: ColumnArticle,
        isNew: Bool,
        onSave: @escaping (ColumnArticle) -> Void,
        onDelete: ((ColumnArticle) -> Void)? = nil
    ) {
        self.initial = initial
        self.isNew = isNew
        self.onSave = onSave
        self.onDelete = onDelete
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
                Section {
                    Button {
                        do {
                            let tags = tagsText
                                .split(separator: ",")
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty }

                            let articleForExport = ColumnArticle(
                                id: initial.id,
                                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                body: bodyText,
                                tags: tags
                            )

                            let result = try ColumnExportFile.makeExportDocument(for: articleForExport)
                            exportDoc = result.doc
                            exportFileName = result.fileName
                            pendingExportedColumnID = articleForExport.id
                            exportErrorMessage = nil
                            showingExporter = true
                        } catch {
                            exportErrorMessage = "コラムJSON生成失敗: \(error.localizedDescription)"
                            print("❌ column export error:", error)
                        }
                    } label: {
                        HStack {
                            Text("コラムを書き出す")
                        }
                        .foregroundStyle(.blue)
                    }

                    if !isNew {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Text("削除")
                        }
                    }
                }
                
                Section {
                    NavigationLink {
                        NoticeFileEditorView(
                            initialHomeworkPayloadID: lastExportedHomeworkPayloadID,
                            initialHomeworkDateText: lastExportedHomeworkDateText,
                            initialHomeworkLabel: lastExportedHomeworkLabel,
                            initialHomeworkCount:
                                lastExportedHomeworkCount == 0
                                    ? nil
                                    : lastExportedHomeworkCount,
                            initialLatestColumnID: initial.id,
                            entryContext: .column,
                            onConfirm: { manifest in
                                pendingNoticeManifest = manifest
                                showNoticeExportConfirm = true
                            }
                        )
                    } label: {
                        HStack {
                            Text("🔔")
                            Text("通知内容を確認")
                        }
                        .foregroundStyle(.blue)
                    }
                    .disabled(!hasExportedCurrentColumn)

                    Text("コラムを配布するときは、コラムを書き出したあと、通知内容を確認して通知ファイルも書き出します。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
            }
            .navigationTitle(isNew ? "コラム追加" : "コラム編集")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: title) {
                hasExportedCurrentColumn = false
            }
            .onChange(of: bodyText) {
                hasExportedCurrentColumn = false
            }
            .onChange(of: tagsText) {
                hasExportedCurrentColumn = false
            }
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
            .fileExporter(
                isPresented: $showingExporter,
                document: exportDoc ?? JSONTextDocument(text: "{}"),
                contentType: .json,
                defaultFilename: exportFileName
            ) { result in
                switch result {
                case .success(let url):
                    if let id = pendingExportedColumnID {
                        lastExportedColumnID = id
                        hasExportedCurrentColumn = true
                    }
                    pendingExportedColumnID = nil
                    exportErrorMessage = nil
                    print("✅ column exported:", url)
                case .failure(let err):
                    pendingExportedColumnID = nil
                    exportErrorMessage = err.localizedDescription
                    print("❌ column export error:", err)
                }
            }
            .alert(
                "書き出しエラー",
                isPresented: Binding(
                    get: { exportErrorMessage != nil },
                    set: { if !$0 { exportErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    exportErrorMessage = nil
                }
            } message: {
                Text(exportErrorMessage ?? "")
            }
            .confirmationDialog(
                "通知ファイルを書き出しますか？",
                isPresented: $showNoticeExportConfirm,
                titleVisibility: .visible
            ) {
                Button("書き出す") {
                    exportPendingNoticeFile()
                }

                Button("キャンセル") {
                    pendingNoticeManifest = nil
                    showNoticeExportConfirm = false
                }
            } message: {
                Text("現在設定している通知内容を書き出します。")
            }
            .confirmationDialog(
                "このコラムを削除しますか？",
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    let tags = tagsText
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }

                    let articleToDelete = ColumnArticle(
                        id: initial.id,
                        title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                        body: bodyText,
                        tags: tags
                    )

                    onDelete?(articleToDelete)
                    dismiss()
                }

                Button("キャンセル", role: .cancel) { }
            }
        }
    }
    private func exportPendingNoticeFile() {
        guard let manifest = pendingNoticeManifest else {
            return
        }

        do {
            let result =
                try DeliveryManifestFile.makeExportDocument(
                    manifest
                )

            exportDoc = result.doc
            exportFileName = result.fileName
            exportErrorMessage = nil
            pendingNoticeManifest = nil
            showingExporter = true

        } catch {
            exportErrorMessage =
                "通知ファイルを作れませんでした: \(error.localizedDescription)"
        }
    }
}
