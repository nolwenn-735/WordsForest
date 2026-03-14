//
//  ColumnIndexView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/30.→2026/3/12 TeacherLock対応
//

import SwiftUI

struct ColumnIndexView: View {
    @StateObject private var store = ColumnStore.shared
    @EnvironmentObject private var teacher: TeacherMode

    @State private var searchText = ""
    @State private var showNewestFirst = true

    @State private var editingArticle: ColumnArticle? = nil
    @State private var editorIsNew = false

    @State private var showingDeleteConfirm = false
    @State private var deletingArticle: ColumnArticle? = nil
    @State private var pendingCreate = false
    @State private var pendingEditArticle: ColumnArticle? = nil
    @State private var pendingDeleteArticle: ColumnArticle? = nil
    
    @State private var exportDoc: JSONTextDocument? = nil
    @State private var exportFileName: String = "column.json"
    @State private var showingExporter = false
    @State private var exportErrorMessage: String? = nil

    @State private var pendingExportArticle: ColumnArticle? = nil
    @State private var showingImporter = false
    @State private var importErrorMessage: String? = nil

    private var filtered: [ColumnArticle] {
        filteredArticles()
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color("othersLavender").ignoresSafeArea()

            VStack(spacing: 0) {
                importHeader

                List {
                    ForEach(filtered) { article in
                        articleRow(article)
                    }
                }
                .confirmationDialog(
                    "このコラムを削除しますか？",
                    isPresented: $showingDeleteConfirm,
                    titleVisibility: .visible
                ) {
                    Button("削除", role: .destructive) {
                        if let a = deletingArticle {
                            store.delete(a)
                        }
                        deletingArticle = nil
                    }

                    Button("キャンセル", role: .cancel) {
                        deletingArticle = nil
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "コラムを検索")
            }
            .navigationTitle("🐺 コラム一覧")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        pendingCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }

                    Button(showNewestFirst ? "最新→古い" : "古い→最新") {
                        withAnimation {
                            showNewestFirst.toggle()
                        }
                    }
                }
            }
            .onAppear {
                store.markAsSeen()
            }
            .onChange(of: pendingCreate) { _, newValue in
                guard newValue else { return }
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
            .onChange(of: pendingEditArticle) { _, article in
                guard let article else { return }
                teacher.requestUnlock {
                    editorIsNew = false
                    editingArticle = article
                }
                pendingEditArticle = nil
            }
            .onChange(of: pendingDeleteArticle) { _, article in
                guard let article else { return }
                teacher.requestUnlock {
                    deletingArticle = article
                    showingDeleteConfirm = true
                }
                pendingDeleteArticle = nil
            }
            .onChange(of: pendingExportArticle) { _, article in
                guard let article else { return }
                teacher.requestUnlock {
                    do {
                        let result = try ColumnExportFile.makeExportDocument(for: article)
                        exportDoc = result.doc
                        exportFileName = result.fileName
                        exportErrorMessage = nil
                        showingExporter = true
                    } catch {
                        exportErrorMessage = "コラムJSON生成失敗: \(error.localizedDescription)"
                        print("❌ column export error:", error)
                    }
                }
                pendingExportArticle = nil
            }
            .sheet(item: $editingArticle) { article in
                ColumnEditorView(
                    initial: article,
                    isNew: editorIsNew,
                    onSave: { updated in
                        store.upsert(updated)
                    },
                    onDelete: { target in
                        store.delete(target)
                    }
                )
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importSelectedColumnFile(from: url)

                case .failure(let error):
                    importErrorMessage = "コラム取得失敗: \(error.localizedDescription)"
                    print("❌ column import picker error:", error)
                }
            }
            .alert(
                "取得エラー",
                isPresented: Binding(
                    get: { importErrorMessage != nil },
                    set: { if !$0 { importErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    importErrorMessage = nil
                }
            } message: {
                Text(importErrorMessage ?? "")
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: exportDoc ?? JSONTextDocument(text: "{}"),
                contentType: .json,
                defaultFilename: exportFileName
            ) { result in
                switch result {
                case .success(let url):
                    exportErrorMessage = nil
                    print("✅ column exported:", url)
                case .failure(let err):
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

            Image("tutor_husky_down")
                .resizable()
                .scaledToFit()
                .frame(width: 120)
                .padding(.leading, 16)
                .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private func articleRow(_ article: ColumnArticle) -> some View {
        let placeholder = isPlaceholder(article)

        NavigationLink {
            ColumnArticleView(
                title: "No.\(article.id)  \(article.title)",
                content: article.body
            )
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("No.\(article.id)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if placeholder {
                        Text("準備中")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.gray.opacity(0.18))
                            .clipShape(Capsule())
                            .foregroundStyle(.secondary)
                    }
                }

                Text(article.title)
                    .foregroundColor(placeholder ? .secondary : .blue)
                if !article.tags.isEmpty {
                    Text(article.tags.joined(separator: "・"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .contextMenu {
            Button("書き出し") {
                pendingExportArticle = article
            }

            Button("編集…") {
                pendingEditArticle = article
            }

            Button(role: .destructive) {
                pendingDeleteArticle = article
            } label: {
                Text("削除")
            }
        }
    }
    
    private var importHeader: some View {
        HStack {
            Button {
                showingImporter = true
            } label: {
                HStack(spacing: 8) {
                    Text("🟣")
                    Text("新規取得")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.purple)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.purple.opacity(0.10))
                )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
    
    private func importSelectedColumnFile(from url: URL) {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(ColumnExportPayload.self, from: data)

            try store.importPayload(payload)

            print("✅ column imported payload id =", payload.id)
            print("✅ imported items =", payload.items.count)

        } catch {
            importErrorMessage = "コラムJSONの読み込みに失敗しました: \(error.localizedDescription)"
            print("❌ column import error:", error)
        }
    }
    
    private func filteredArticles() -> [ColumnArticle] {
        var base = store.articles

        if showNewestFirst {
            base.sort { $0.id > $1.id }
        } else {
            base.sort { $0.id < $1.id }
        }

        guard !searchText.isEmpty else { return base }

        return base.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
            || $0.body.localizedCaseInsensitiveContains(searchText)
            || $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }

    private func isPlaceholder(_ article: ColumnArticle) -> Bool {
        let trimmed = article.body.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed == "ここに本文を書きます…"
    }
}

#Preview {
    NavigationStack {
        ColumnIndexView()
            .environmentObject(TeacherMode.preview(unlocked: true))
    }
}
