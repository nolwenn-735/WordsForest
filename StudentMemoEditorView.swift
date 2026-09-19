//
//  StudentMemoEditorView.swift
//  WordsForest
//
//  Created by Nami .T on 2026/09/19.
//

import SwiftUI

struct StudentMemoEditorView: View {

    let pageID: UUID

    @ObservedObject var store: StudentMemoStore

    @State private var title = ""
    @State private var bodyText = ""

    @State private var hasLoaded = false

    var body: some View {
        VStack(spacing: 0) {

            TextField("タイトル", text: $title)
                .font(.title2.bold())
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 10)

            Divider()

            TextEditor(text: $bodyText)
                .font(.body)
                .padding(.horizontal, 8)
                .padding(.top, 8)
        }
        .navigationTitle("📝 メモ")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadPage()
        }
        .onChange(of: title) { _ in
            savePage()
        }
        .onChange(of: bodyText) { _ in
            savePage()
        }
    }


    // MARK: - 読み込み

    private func loadPage() {
        guard let page = store.page(id: pageID) else {
            return
        }

        title = page.title
        bodyText = page.body

        hasLoaded = true
    }


    // MARK: - 自動保存

    private func savePage() {
        guard hasLoaded else {
            return
        }

        store.updatePage(
            id: pageID,
            title: title,
            body: bodyText
        )
    }
}
