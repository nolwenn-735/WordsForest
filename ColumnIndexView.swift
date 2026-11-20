//  Created by Nami .T on 2025/10/30.→2026/3/12 TeacherLock対応
//
//
//  ColumnIndexView.swift
//  WordsForest
//

import SwiftUI

struct ColumnIndexView: View {
    @StateObject private var store = ColumnStore.shared
    @EnvironmentObject private var teacher: TeacherMode

    @AppStorage(DefaultsKeys.showMascots)
    private var showMascots: Bool = true

    @AppStorage(DefaultsKeys.usageMode)
    private var usageMode: UsageMode = .classroom

    @AppStorage("notice_lastHomeworkPayloadID")
    private var lastExportedHomeworkPayloadID: String = ""

    @AppStorage("notice_lastHomeworkDateText")
    private var lastExportedHomeworkDateText: String = ""

    @AppStorage("notice_lastHomeworkLabel")
    private var lastExportedHomeworkLabel: String = ""

    @AppStorage("notice_lastHomeworkCount")
    private var lastExportedHomeworkCount: Int = 0

    @State private var searchText = ""
    @State private var showNewestFirst = true

    // MARK: - コラム管理入口

    @State private var showingManagementMenu = false
    @State private var pendingCreate = false
    @State private var pendingReeditSelection = false

    @State private var showingReeditPicker = false
    @State private var selectedReeditArticle: ColumnArticle? = nil

    @State private var editingArticle: ColumnArticle? = nil
    @State private var editorIsNew = false

    // MARK: - 削除結果

    @State private var pendingDeleteResult: ColumnDeleteResult? = nil
    @State private var pendingDeletedArticleID: Int? = nil

    @State private var statusAlertTitle: String = ""
    @State private var statusAlertMessage: String = ""
    @State private var showingStatusAlert = false

    // MARK: - 削除済みコラム配布

    private enum ExportPurpose {
        case deletedColumnJSON
        case deletionManifest
    }

    @State private var exportDoc: JSONTextDocument? = nil
    @State private var exportFileName: String = "column.json"
    @State private var showingExporter = false
    @State private var exportErrorMessage: String? = nil
    @State private var exportPurpose: ExportPurpose = .deletedColumnJSON

    @State private var deletionArticleForNotice: ColumnArticle? = nil
    @State private var showingDeletionExportConfirm = false

    @State private var showingDeletionNoticeSheet = false
    @State private var pendingDeletionManifest: DeliveryManifest? = nil
    @State private var showingDeletionManifestConfirm = false

    // MARK: - コラム取得

    @State private var showingImporter = false
    @State private var importErrorMessage: String? = nil

    private var filtered: [ColumnArticle] {
        filteredArticles()
    }

    private var editableTeacherArticles: [ColumnArticle] {
        store.articles
            .filter {
                $0.id > 0 &&
                !$0.isDeleted
            }
            .sorted {
                $0.id > $1.id
            }
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color("othersLavender")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if usageMode == .classroom {
                    importHeader
                }

                List {
                    ForEach(filtered) { article in
                        articleRow(article)
                    }
                }
                .listStyle(.plain)
                .searchable(
                    text: $searchText,
                    prompt: "コラムを検索"
                )
            }

            if showMascots {
                Image("tutor_husky_stand")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                    .padding(.leading, 16)
                    .padding(.bottom, 12)
                    .accessibilityHidden(true)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 10) {
                    Text("🐺 コラム一覧")
                        .font(.headline)
                        .lineLimit(1)

                    Button(
                        showNewestFirst
                            ? "最新→古い"
                            : "古い→最新"
                    ) {
                        withAnimation {
                            showNewestFirst.toggle()
                        }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .modifier(
                        ColumnSortGlassCapsuleButton()
                    )
                }
            }

            if usageMode == .classroom {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingManagementMenu = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("コラムを作成・編集")
                    .modifier(
                        ColumnManagementGlassButton()
                    )
                }
            }
        }

        // MARK: コラム管理メニュー

        .confirmationDialog(
            "コラムを作成・編集",
            isPresented: $showingManagementMenu,
            titleVisibility: .visible
        ) {
            Button("新規コラム作成") {
                pendingCreate = true
            }

            Button("既にあるコラムを再編集") {
                pendingReeditSelection = true
            }

            Button("キャンセル") {
                showingManagementMenu = false
            }
        }
        
        // MARK: 削除JSON書き出し確認

        .confirmationDialog(
            deletionExportConfirmationTitle,
            isPresented: $showingDeletionExportConfirm,
            titleVisibility: .visible
        ) {
            Button("書き出す") {
                exportDeletedColumnJSON()
            }

            Button("キャンセル", role: .cancel) { }
        } message: {
            Text(
                "削除済み状態を生徒端末へ反映するため、削除版のコラムJSONを書き出します。その後、通知ファイルを作成します。"
            )
        }

        // MARK: 削除通知manifest書き出し確認

        .confirmationDialog(
            "通知ファイルを書き出しますか？",
            isPresented: $showingDeletionManifestConfirm,
            titleVisibility: .visible
        ) {
            Button("書き出す") {
                exportPendingDeletionManifest()
            }

            Button("キャンセル", role: .cancel) {
                pendingDeletionManifest = nil
            }
        } message: {
            Text(
                "削除したコラムのNo.・revision・変更内容を通知ファイルへ書き出します。"
            )
        }

        // MARK: 教師ロック

        .onAppear {
            if usageMode == .classroom {
                store.markAsSeen()
            }
        }
        .onChange(of: pendingCreate) { _, newValue in
            guard newValue else {
                return
            }

            teacher.requestUnlock {
                let nextID = store.nextID()

                editorIsNew = true

                editingArticle = ColumnArticle(
                    id: nextID,
                    title: "",
                    body: "",
                    tags: []
                )
            }

            pendingCreate = false
        }
        .onChange(of: pendingReeditSelection) { _, newValue in
            guard newValue else {
                return
            }

            teacher.requestUnlock {
                showingReeditPicker = true
            }

            pendingReeditSelection = false
        }

        // MARK: 再編集するコラムを選択

        .sheet(
            isPresented: $showingReeditPicker,
            onDismiss: {
                guard let article = selectedReeditArticle else {
                    return
                }

                selectedReeditArticle = nil
                editorIsNew = false
                editingArticle = article
            }
        ) {
            NavigationStack {
                List {
                    if editableTeacherArticles.isEmpty {
                        Text("再編集できる先生作成コラムはありません。")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(editableTeacherArticles) { article in
                            Button {
                                selectedReeditArticle = article
                                showingReeditPicker = false
                            } label: {
                                VStack(
                                    alignment: .leading,
                                    spacing: 5
                                ) {
                                    HStack {
                                        Text("No.\(article.id)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        Spacer()

                                        if article.hasBeenDistributed {
                                            Text("配布済み")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        } else {
                                            Text("未配布")
                                                .font(.caption2)
                                                .foregroundStyle(.orange)
                                        }
                                    }

                                    Text(article.title)
                                        .foregroundStyle(.primary)

                                    if article.revision > 1 {
                                        Text(
                                            "revision \(article.revision)"
                                        )
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .navigationTitle("再編集するコラム")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(
                        placement: .cancellationAction
                    ) {
                        Button("閉じる") {
                            selectedReeditArticle = nil
                            showingReeditPicker = false
                        }
                    }
                }
            }
        }

        // MARK: コラムEditor

        .sheet(
            item: $editingArticle,
            onDismiss: {
                handlePendingDeleteResultAfterEditorDismiss()
            }
        ) { article in
            ColumnEditorView(
                initial: article,
                isNew: editorIsNew,
                onSave: { updated in
                    store.upsert(updated)
                },
                onDelete: { target in
                    pendingDeletedArticleID = target.id
                    pendingDeleteResult = store.delete(target)
                }
            )
        }

        // MARK: 削除通知内容

        .sheet(
            isPresented: $showingDeletionNoticeSheet,
            onDismiss: {
                if pendingDeletionManifest != nil {
                    showingDeletionManifestConfirm = true
                }
            }
        ) {
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
                    deletionArticleForNotice?.id,
                initialLatestColumnRevision:
                    deletionArticleForNotice?.revision,
                initialLatestColumnChange:
                    .deleted,
                entryContext:
                    .column,
                onConfirm: { manifest in
                    pendingDeletionManifest = manifest
                }
            )
        }

        // MARK: コラムJSON取得

        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else {
                    return
                }

                importSelectedColumnFile(
                    from: url
                )

            case .failure(let error):
                importErrorMessage =
                    "コラム取得失敗: \(error.localizedDescription)"

                print(
                    "❌ column import picker error:",
                    error
                )
            }
        }

        // MARK: 削除JSON / manifest 書き出し

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

        // MARK: Alerts

        .alert(
            statusAlertTitle,
            isPresented: $showingStatusAlert
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(statusAlertMessage)
        }

        .alert(
            "取得エラー",
            isPresented: Binding(
                get: {
                    importErrorMessage != nil
                },
                set: {
                    if !$0 {
                        importErrorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                importErrorMessage = nil
            }
        } message: {
            Text(
                importErrorMessage
                ?? ""
            )
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
    }

    // =======================================================
    // MARK: - コラム行
    // =======================================================

    @ViewBuilder
    private func articleRow(
        _ article: ColumnArticle
    ) -> some View {

        if article.isDeleted {
            deletedArticleRow(article)
        } else {
            normalArticleRow(article)
        }
    }

    private func normalArticleRow(
        _ article: ColumnArticle
    ) -> some View {

        let placeholder =
            isPlaceholder(article)

        return NavigationLink {
            ColumnArticleView(
                title:
                    "\(articleNumberLabel(article))  \(article.title)",
                content:
                    article.body
            )
        } label: {
            VStack(
                alignment: .leading,
                spacing: 6
            ) {
                HStack(spacing: 8) {
                    Text(
                        articleNumberLabel(article)
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if placeholder {
                        Text("準備中")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                .gray.opacity(0.18)
                            )
                            .clipShape(Capsule())
                            .foregroundStyle(.secondary)
                    }
                }

                Text(article.title)
                    .foregroundColor(
                        placeholder
                            ? .secondary
                            : .blue
                    )

                if !article.tags.isEmpty {
                    Text(
                        article.tags.joined(
                            separator: "・"
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func deletedArticleRow(
        _ article: ColumnArticle
    ) -> some View {

        let needsDistribution =
            article.revision >
            article.distributedRevision

        if needsDistribution &&
            usageMode == .classroom {

            Button {
                teacher.requestUnlock {
                    deletionArticleForNotice =
                        article

                    showingDeletionExportConfirm =
                        true
                }
            } label: {
                deletedArticleLabel(
                    article,
                    needsDistribution:
                        true
                )
            }
            .buttonStyle(.plain)

        } else {
            deletedArticleLabel(
                article,
                needsDistribution:
                    false
            )
        }
    }

    private func deletedArticleLabel(
        _ article: ColumnArticle,
        needsDistribution: Bool
    ) -> some View {

        HStack {
            VStack(
                alignment: .leading,
                spacing: 6
            ) {
                Text(
                    articleNumberLabel(article)
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(article.title)
                    .foregroundStyle(.secondary)

                Text(
                    needsDistribution
                        ? "削除通知待ち"
                        : "削除済み"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if needsDistribution {
                Image(
                    systemName: "arrow.up.doc"
                )
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .opacity(0.55)
        .contentShape(Rectangle())
    }

    // =======================================================
    // MARK: - 削除結果
    // =======================================================

    private func handlePendingDeleteResultAfterEditorDismiss() {

        guard let result =
                pendingDeleteResult
        else {
            pendingDeletedArticleID = nil
            return
        }

        let deletedID =
            pendingDeletedArticleID

        pendingDeleteResult = nil
        pendingDeletedArticleID = nil

        switch result {

        case .permanentlyDeletedUndistributed:
            guard let deletedID else {
                return
            }

            showStatus(
                title: "削除しました",
                message:
                    "このコラムはまだ配布されていなかったため完全に削除しました。次に新規コラムを作成するとNo.\(deletedID)が再利用されます。"
            )

        case .blockedUndistributedNonLatest:
            showStatus(
                title: "このコラムは削除できません",
                message:
                    "このコラムはまだ配布されていません。No.の連続性を保つため、削除せず内容を編集してください。"
            )

        case .markedDeletedNeedsDistribution:
            guard let deletedID,
                  let deletedArticle =
                    store.article(
                        id: deletedID
                    )
            else {
                showStatus(
                    title: "削除エラー",
                    message:
                        "削除済みコラムの情報を確認できませんでした。"
                )
                return
            }

            deletionArticleForNotice =
                deletedArticle

            showingDeletionExportConfirm =
                true

        case .alreadyDeleted:
            showStatus(
                title: "削除済みです",
                message:
                    "このコラムはすでに削除済みです。"
            )

        case .ignoredBundled:
            showStatus(
                title: "削除できません",
                message:
                    "プリインストールされた基礎コラムは削除できません。"
            )

        case .notFound:
            showStatus(
                title: "削除エラー",
                message:
                    "削除するコラムを確認できませんでした。"
            )
        }
    }

    private var deletionExportConfirmationTitle: String {
        guard let article =
                deletionArticleForNotice
        else {
            return "削除通知を書き出しますか？"
        }

        return "No.\(article.id)の削除通知を書き出しますか？"
    }

    // =======================================================
    // MARK: - 削除JSON書き出し
    // =======================================================

    private func exportDeletedColumnJSON() {

        guard let article =
                deletionArticleForNotice
        else {
            showStatus(
                title: "書き出しエラー",
                message:
                    "削除通知の対象コラムを確認できませんでした。"
            )
            return
        }

        do {
            let result =
                try ColumnExportFile
                    .makeExportDocument(
                        for: article
                    )

            exportDoc =
                result.doc

            exportFileName =
                result.fileName

            exportPurpose =
                .deletedColumnJSON

            exportErrorMessage =
                nil

            showingExporter =
                true

        } catch {
            exportErrorMessage =
                "削除版コラムJSON生成失敗: \(error.localizedDescription)"
        }
    }

    private func handleExportResult(
        _ result: Result<URL, Error>
    ) {
        switch result {

        case .success(let url):
            switch exportPurpose {

            case .deletedColumnJSON:
                print(
                    "✅ deleted column exported:",
                    url
                )

                showingDeletionNoticeSheet =
                    true

            case .deletionManifest:
                completeDeletionManifestExport(
                    url: url
                )
            }

        case .failure(let error):
            exportErrorMessage =
                error.localizedDescription

            print(
                "❌ column export error:",
                error
            )
        }
    }

    // =======================================================
    // MARK: - 削除manifest
    // =======================================================

    private func exportPendingDeletionManifest() {

        guard let manifest =
                pendingDeletionManifest
        else {
            return
        }

        do {
            let result =
                try DeliveryManifestFile
                    .makeExportDocument(
                        manifest
                    )

            exportDoc =
                result.doc

            exportFileName =
                result.fileName

            exportPurpose =
                .deletionManifest

            exportErrorMessage =
                nil

            showingExporter =
                true

        } catch {
            exportErrorMessage =
                "通知ファイルを作れませんでした: \(error.localizedDescription)"
        }
    }

    private func completeDeletionManifestExport(
        url: URL
    ) {

        guard let article =
                deletionArticleForNotice
        else {
            exportErrorMessage =
                "削除通知の対象コラムを確認できませんでした。"
            return
        }

        let marked =
            store.markDistributed(
                articleID:
                    article.id,
                revision:
                    article.revision
            )

        guard marked else {
            exportErrorMessage =
                "コラムの配布済み状態を更新できませんでした。"
            return
        }

        print(
            "✅ deletion manifest exported:",
            url,
            "No.=",
            article.id,
            "revision=",
            article.revision
        )

        pendingDeletionManifest =
            nil

        deletionArticleForNotice =
            nil

        showStatus(
            title: "削除通知を書き出しました",
            message:
                "コラムの削除情報を生徒端末へ配布できる状態になりました。"
        )
    }

    // =======================================================
    // MARK: - 新規取得
    // =======================================================

    private var importHeader: some View {
        HStack {
            Button {
                showingImporter = true
            } label: {
                HStack(spacing: 8) {
                    Text("🟣")

                    Text("新規取得")
                        .font(
                            .system(
                                size: 15,
                                weight: .semibold
                            )
                        )
                }
                .foregroundStyle(.purple)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(
                        cornerRadius: 14
                    )
                    .fill(
                        Color.purple.opacity(
                            0.10
                        )
                    )
                )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private func importSelectedColumnFile(
        from url: URL
    ) {
        let didStartAccessing =
            url.startAccessingSecurityScopedResource()

        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data =
                try Data(
                    contentsOf: url
                )

            let payload =
                try JSONDecoder().decode(
                    ColumnExportPayload.self,
                    from: data
                )

            try store.importPayload(
                payload
            )

            print(
                "✅ column imported payload id =",
                payload.id
            )

            print(
                "✅ imported items =",
                payload.items.count
            )

        } catch {
            importErrorMessage =
                "コラムJSONの読み込みに失敗しました: \(error.localizedDescription)"

            print(
                "❌ column import error:",
                error
            )
        }
    }

    // =======================================================
    // MARK: - 一覧
    // =======================================================

    private func filteredArticles() -> [ColumnArticle] {
        var base =
            store.articles

        if showNewestFirst {
            base.sort {
                $0.id > $1.id
            }
        } else {
            base.sort {
                $0.id < $1.id
            }
        }

        guard !searchText.isEmpty else {
            return base
        }

        return base.filter {
            $0.title
                .localizedCaseInsensitiveContains(
                    searchText
                )
            ||
            $0.body
                .localizedCaseInsensitiveContains(
                    searchText
                )
            ||
            $0.tags.contains {
                $0.localizedCaseInsensitiveContains(
                    searchText
                )
            }
        }
    }

    private func articleNumberLabel(
        _ article: ColumnArticle
    ) -> String {
        if article.id < 0 {
            return "基礎\(abs(article.id))"
        }

        return "No.\(article.id)"
    }

    private func isPlaceholder(
        _ article: ColumnArticle
    ) -> Bool {
        let trimmed =
            article.body.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty ||
            trimmed == "ここに本文を書きます…"
    }

    private func showStatus(
        title: String,
        message: String
    ) {
        statusAlertTitle =
            title

        statusAlertMessage =
            message

        showingStatusAlert =
            true
    }
}

// =======================================================
// MARK: - Liquid Glass
// =======================================================

private struct ColumnManagementGlassButton: ViewModifier {

    @ViewBuilder
    func body(
        content: Content
    ) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .controlSize(.regular)
        } else {
            content
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .controlSize(.regular)
        }
    }
}

private struct ColumnSortGlassCapsuleButton: ViewModifier {

    @ViewBuilder
    func body(
        content: Content
    ) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
        } else {
            content
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
        }
    }
}

// =======================================================
// MARK: - Preview
// =======================================================

struct ColumnIndexView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ColumnIndexView()
                .environmentObject(
                    TeacherMode.preview(
                        unlocked: true
                    )
                )
        }
    }
}
