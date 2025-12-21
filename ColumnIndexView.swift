//
//  ColumnIndexView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/30.
//

import SwiftUI

struct ColumnIndexView: View {
   
    @StateObject private var store = ColumnStore.shared
    @State private var searchText = ""
    @State private var showNewestFirst = true
    
    @State private var showingEditor = false
    @State private var editingArticle: ColumnArticle? = nil
    @State private var editorIsNew = false
    
    @State private var showingDeleteConfirm = false
    @State private var deletingArticle: ColumnArticle? = nil


    var body: some View {
        let filtered = filteredArticles()

        ZStack(alignment: .bottomLeading) {
            Color("othersLavender").ignoresSafeArea()

            List {
                ForEach(filtered) { article in
                    NavigationLink {
                        ColumnArticleView(
                            title: "No.\(article.id)  \(article.title)",
                            content: article.body
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("No.\(article.id)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(article.title)
                                .foregroundStyle(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                    // ✅ 長押しメニューで編集
                    .contextMenu {
                        Button("編集…") {
                            editorIsNew = false
                            editingArticle = article
                            showingEditor = true
                        }
                        Button(role: .destructive) {
                                deletingArticle = article
                                showingDeleteConfirm = true
                            } label: {
                                Text("削除")
                            }
                    }
                }
            }
            .confirmationDialog("このコラムを削除しますか？",
                                isPresented: $showingDeleteConfirm,
                                titleVisibility: .visible) {
                Button("削除", role: .destructive) {
                    if let a = deletingArticle {
                               store.delete(a)   // ← ColumnStore に delete を作る
                    }
                    deletingArticle = nil
                }
                Button("キャンセル", role: .cancel) {
                    deletingArticle = nil
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "コラムを検索")
            .navigationTitle("🐺 コラム一覧")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {

                    // ✅ ＋：新規作成
                    Button {
                        let nextID = (store.articles.map { $0.id }.max() ?? 0) + 1
                        editorIsNew = true
                        editingArticle = ColumnArticle(id: nextID, title: "", body: "", tags: [])
                    } label: {
                        Image(systemName: "plus")
                    }

                    // ✅ 並び替え
                    Button(showNewestFirst ? "最新→古い" : "古い→最新") {
                        withAnimation { showNewestFirst.toggle() }
                    }
                }
            }
            .onAppear {
                store.markAsSeen()   // ✅ 一覧を開いたら既読扱い（🆕消す）
            }
            // ✅ これが白紙対策の本体
            .sheet(item: $editingArticle) { article in
                ColumnEditorView(
                    initial: article,
                    isNew: editorIsNew,
                    onSave: { updated in
                        store.upsert(updated)   // ✅ 保存して一覧に反映
                    }
                )
            }

            Image("tutor_husky_down")
                .resizable()
                .scaledToFit()
                .frame(width: 120)
                .padding(.leading, 16)
                .padding(.bottom, 12)
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
}

#Preview {
    NavigationStack {
        ColumnIndexView()
    }
}
