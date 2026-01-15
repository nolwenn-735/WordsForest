//
//  HomeworkImportView.swift
//  WordsForest
//
//  Created by Nami .T on 2026/01/05.
//

import SwiftUI
import UniformTypeIdentifiers

struct HomeworkImportButton: View {
    @EnvironmentObject var hw: HomeworkState

    @State private var showingImporter = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert = false

    var body: some View {
        Button {
            showingImporter = true
        } label: {
            Label("宿題取得", systemImage: "tray.and.arrow.down")
        }
        .buttonStyle(.bordered)
        .tint(.blue)
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            show(title: "取り込み失敗", message: error.localizedDescription)

        case .success(let urls):
            guard let url = urls.first else { return }

            // 念のため：拡張子チェック
            if url.pathExtension.lowercased() != "json" {
                show(title: "取り込み失敗", message: "JSONファイル（.json）を選んでください")
                return
            }

            // ここを非同期にして固まりを防ぐ
            Task {
                await importFromURL(url)
            }
        }
    }

    @MainActor
    private func importFromURL(_ url: URL) async {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        do {
            // ファイル読み込み＆デコードは重くなりうるのでTask内でやってOK
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(HomeworkExportPayload.self, from: data)

            if hw.isAlreadyImported(payload: payload) {
                show(title: "取得済み", message: "最新の宿題は既に取得済みです")
                return
            }

            try HomeworkPackStore.shared.importHomeworkPayload(payload, hw: hw)

            hw.addImportedToHistory(payload: payload)
            hw.markImported(payload: payload)
            hw.resetCache()

            let date = payload.createdAt.prefix(10)
            let pairLabel = (PosPair(rawValue: payload.pair) ?? hw.currentPair).parts
                .map { $0.rawValue }
                .joined(separator: "＋")

            show(title: "取得しました", message: "\(date) の宿題（\(pairLabel)）を取得しました")

        } catch {
            show(title: "取り込み失敗", message: error.localizedDescription)
        }
    }

    @MainActor
    private func show(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
