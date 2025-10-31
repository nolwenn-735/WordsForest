//
//  ColumnIndexView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/30.
//

import SwiftUI

struct ColumnIndexView: View {
    @State private var searchText = ""
    @State private var showNewestFirst = true

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
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "コラムを検索")
            .navigationTitle("🐺 コラム一覧")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(showNewestFirst ? "最新→古い" : "古い→最新") {
                        withAnimation { showNewestFirst.toggle() }
                    }
                }
            }

            // 左下のハスキー
            Image("tutor_husky_down")
                .resizable()
                .scaledToFit()
                .frame(width: 120)
                .padding(.leading, 16)
                .padding(.bottom, 12)
        }
    }

    private func filteredArticles() -> [ColumnArticle] {
        var base = ColumnData.all
        if showNewestFirst {
            base.sort { $0.id > $1.id }
        } else {
            base.sort { $0.id < $1.id }
        }

        if searchText.isEmpty {
            return base
        } else {
            return base.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.body.localizedCaseInsensitiveContains(searchText)
                || $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }
    }
}

#Preview {
    NavigationStack {
        ColumnIndexView()
    }
}
