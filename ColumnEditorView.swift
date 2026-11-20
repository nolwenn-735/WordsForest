//
// Created by Nami .T on 2025/12/21.
//
//  ColumnEditorView.swift
//  WordsForest
//

import SwiftUI

struct ColumnEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = ColumnStore.shared

    let initial: ColumnArticle
    let isNew: Bool
    let onSave: (ColumnArticle) -> Void
    let onDelete: ((ColumnArticle) -> Void)?

    private enum ExportPurpose: Equatable {
        case columnJSON
        case noticeManifest
    }

    @State private var title: String
    @State private var bodyText: String
    @State private var tagsText: String

    @State private var exportDoc: JSONTextDocument? = nil
    @State private var exportFileName: String = "column.json"
    @State private var showingExporter = false
    @State private var exportErrorMessage: String? = nil
    @State private var exportPurpose: ExportPurpose = .columnJSON

    @State private var showingColumnExportConfirm = false
    @State private var showingDeleteConfirm = false

    @State private var pendingArticleForColumnExport: ColumnArticle? = nil
    @State private var exportedArticleForNotice: ColumnArticle? = nil

    @State private var pendingNoticeManifest: DeliveryManifest? = nil
    @State private var showNoticeExportConfirm = false

    @AppStorage("notice_lastColumnID") private var lastExportedColumnID: Int = 0
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
        _bodyText = State(initialValue: initial.body)
        _tagsText = State(
            initialValue: initial.tags.joined(separator: ", ")
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("タイトル") {
                    TextField(
                        "例: on の感覚",
                        text: $title
                    )
                }

                Section("本文") {
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 220)
                }

                Section("タグ（カンマ区切り）") {
                    TextField(
                        "例: 前置詞, 感覚",
                        text: $tagsText
                    )
                    .textInputAutocapitalization(.never)
                }

                Section {
                    Button {
                        showingColumnExportConfirm = true
                    } label: {
                        HStack {
                            Text("コラムを書き出す")
                        }
                        .foregroundStyle(.blue)
                    }
                    .disabled(
                        title
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
                    )

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
                            initialHomeworkPayloadID:
                                lastExportedHomeworkPayloadID,
                            initialHomeworkDateText:
                                lastExportedHomeworkDateText,
                            initialHomeworkLabel:
                                lastExportedHomeworkLabel,
                            initialHomeworkCount:
                                lastExportedHomeworkCount == 0
                                    ? nil
                                    : lastExportedHomeworkCount,
                            initialLatestColumnID:
                                exportedArticleForNotice?.id
                                    ?? initial.id,
                            initialLatestColumnRevision:
                                exportedArticleForNotice?.revision,
                            initialLatestColumnChange:
                                exportedArticleForNotice.map {
                                    columnChangeForDistribution($0)
                                },
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
            .navigationTitle(
                isNew
                    ? "コラム追加"
                    : "コラム編集"
            )
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: title) {
                invalidateCurrentColumnExport()
            }
            .onChange(of: bodyText) {
                invalidateCurrentColumnExport()
            }
            .onChange(of: tagsText) {
                invalidateCurrentColumnExport()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("戻る") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        let updated = makeDraftArticle()
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(
                        title
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
                    )
                }
            }
            .fileExporter(
                isPresented: $showingExporter,
                document:
                    exportDoc
                    ?? JSONTextDocument(text: "{}"),
                contentType: .json,
                defaultFilename: exportFileName
            ) { result in
                handleExportResult(result)
            }
            .alert(
                "書き出しエラー",
                isPresented: Binding(
                    get: {
                        exportErrorMessage != nil
                    },
                    set: {
                        if !$0 {
                            exportErrorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    exportErrorMessage = nil
                }
            } message: {
                Text(
                    exportErrorMessage
                    ?? ""
                )
            }
            .confirmationDialog(
                columnExportConfirmationTitle,
                isPresented: $showingColumnExportConfirm,
                titleVisibility: .visible
            ) {
                Button("書き出す") {
                    prepareColumnExport()
                }

                Button("キャンセル", role: .cancel) { }
            } message: {
                Text(columnExportConfirmationMessage)
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
                    let articleToDelete = makeDraftArticle()
                    onDelete?(articleToDelete)
                    dismiss()
                }

                Button("キャンセル", role: .cancel) { }
            }
        }
    }

    private var columnExportConfirmationTitle: String {
        if let current = store.article(id: initial.id),
           current.hasBeenDistributed {
            return "再編集したコラムを書き出しますか？"
        }

        return "このコラムを書き出しますか？"
    }

    private var columnExportConfirmationMessage: String {
        if let current = store.article(id: initial.id),
           current.hasBeenDistributed {
            return "現在の編集内容を保存し、改訂版のコラムJSONを書き出します。"
        }

        return "現在の内容を保存し、コラムJSONを書き出します。"
    }

    private func parsedTags() -> [String] {
        tagsText
            .split(separator: ",")
            .map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }
            .filter {
                !$0.isEmpty
            }
    }

    private func makeDraftArticle() -> ColumnArticle {
        let current = store.article(
            id: initial.id
        )

        return ColumnArticle(
            id: initial.id,
            title: title.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            body: bodyText,
            tags: parsedTags(),
            revision:
                current?.revision
                ?? initial.revision,
            distributedRevision:
                current?.distributedRevision
                ?? initial.distributedRevision,
            isDeleted: false
        )
    }

    private func makeArticleForColumnExport() -> ColumnArticle {
        let draft = makeDraftArticle()

        guard let current = store.article(
            id: initial.id
        ) else {
            return ColumnArticle(
                id: draft.id,
                title: draft.title,
                body: draft.body,
                tags: draft.tags,
                revision: 1,
                distributedRevision: 0,
                isDeleted: false
            )
        }

        let contentChanged =
            current.title != draft.title ||
            current.body != draft.body ||
            current.tags != draft.tags

        return ColumnArticle(
            id: current.id,
            title: draft.title,
            body: draft.body,
            tags: draft.tags,
            revision:
                contentChanged
                    ? current.revision + 1
                    : current.revision,
            distributedRevision:
                current.distributedRevision,
            isDeleted: false
        )
    }

    private func prepareColumnExport() {
        do {
            let articleForExport =
                makeArticleForColumnExport()

            let result =
                try ColumnExportFile.makeExportDocument(
                    for: articleForExport
                )

            exportDoc = result.doc
            exportFileName = result.fileName
            pendingArticleForColumnExport = articleForExport
            exportPurpose = .columnJSON
            exportErrorMessage = nil
            showingExporter = true

        } catch {
            pendingArticleForColumnExport = nil
            exportErrorMessage =
                "コラムJSON生成失敗: \(error.localizedDescription)"

            print(
                "❌ column export error:",
                error
            )
        }
    }

    private func handleExportResult(
        _ result: Result<URL, Error>
    ) {
        switch result {
        case .success(let url):
            switch exportPurpose {
            case .columnJSON:
                completeColumnExport(
                    url: url
                )

            case .noticeManifest:
                completeNoticeExport(
                    url: url
                )
            }

        case .failure(let error):
            exportErrorMessage =
                error.localizedDescription

            if exportPurpose == .columnJSON {
                pendingArticleForColumnExport = nil
            }

            print(
                "❌ export error:",
                error
            )
        }
    }

    private func completeColumnExport(
        url: URL
    ) {
        guard let pendingArticle =
                pendingArticleForColumnExport
        else {
            exportErrorMessage =
                "書き出したコラムの保存情報を確認できませんでした。"
            return
        }

        // A方式:
        // コラムJSONの書き出し成功時に、
        // 同じ編集内容を先生端末へ自動保存する。
        onSave(pendingArticle)

        guard let savedArticle = store.article(
            id: pendingArticle.id
        ) else {
            pendingArticleForColumnExport = nil
            exportErrorMessage =
                "書き出したコラムを先生端末へ保存できませんでした。"
            return
        }

        guard savedArticle.revision == pendingArticle.revision else {
            pendingArticleForColumnExport = nil
            exportErrorMessage =
                "コラムJSONと先生端末のrevisionが一致しませんでした。"
            return
        }

        lastExportedColumnID = savedArticle.id
        exportedArticleForNotice = savedArticle
        hasExportedCurrentColumn = true
        pendingArticleForColumnExport = nil
        exportErrorMessage = nil

        print(
            "✅ column exported:",
            url,
            "No.=",
            savedArticle.id,
            "revision=",
            savedArticle.revision
        )
    }

    private func completeNoticeExport(
        url: URL
    ) {
        guard let article =
                exportedArticleForNotice
        else {
            exportErrorMessage =
                "通知対象のコラム情報を確認できませんでした。"
            return
        }

        let marked = store.markDistributed(
            articleID: article.id,
            revision: article.revision
        )

        guard marked else {
            exportErrorMessage =
                "コラムの配布済み状態を更新できませんでした。"
            return
        }

        if let updated = store.article(
            id: article.id
        ) {
            exportedArticleForNotice = updated
        }

        pendingNoticeManifest = nil
        hasExportedCurrentColumn = false
        exportErrorMessage = nil

        print(
            "✅ notice manifest exported:",
            url,
            "No.=",
            article.id,
            "revision=",
            article.revision
        )
    }

    private func columnChangeForDistribution(
        _ article: ColumnArticle
    ) -> DeliveryColumnChange {
        if article.isDeleted {
            return .deleted
        }

        if article.distributedRevision == 0 {
            return .newArticle
        }

        return .updated
    }

    private func invalidateCurrentColumnExport() {
        hasExportedCurrentColumn = false
        exportedArticleForNotice = nil
        pendingNoticeManifest = nil
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
            exportPurpose = .noticeManifest
            exportErrorMessage = nil
            showingExporter = true

        } catch {
            exportErrorMessage =
                "通知ファイルを作れませんでした: \(error.localizedDescription)"
        }
    }
}
