//
//  DisplaySettingView.swift
//  WordsForest
//
//  Created by Nami .T on 2026/05/04.
//

import SwiftUI
import UniformTypeIdentifiers

struct DisplaySettingsView: View {
    @AppStorage(DefaultsKeys.showMascots) private var showMascots: Bool = true
    
    @State private var showBackupFolderPicker = false
    @State private var backupErrorMessage: String?
    @State private var backupSuccessMessage: String?
    @State private var showBackupImporter = false
    @State private var pendingRestoreBackup: WordsForestBackup?
    @State private var backupSuccessTitle = ""
    @State private var showRestoreConfirmation = false
    @State private var pendingRestoreFileName = ""
    
    var body: some View {
        Form {

            Section {
                Toggle("動物マスコットを表示", isOn: $showMascots)
                    .tint(.green)
            } header: {
                Text("表示")
            } footer: {
                Text(
                    "HomePage、単語カード画面に表示される動物マスコットを表示するかしないかを選べます。ライトモード、ダークモードの設定は、iPhone、iPadの⚙️設定から行えます。"
                )
            }
            // MARK: - バックアップ

            Section {
                Button {
                    showBackupFolderPicker = true
                } label: {
                    Text("🚚　バックアップを保存")
                        .foregroundStyle(.blue)
                }
                Button {
                    showBackupImporter = true
                } label: {
                    Text("📥　バックアップから復元")
                        .foregroundStyle(.blue)
                }
            } header: {
                Text("バックアップ")
            } footer: {
                Text(
                    "単語カード、例文・ノート、コラム、メモなどの学習データをバックアップできます。アプリを削除する前や、機種変更の前に保存しておくと安心です。"
                )
            }
        }
        .navigationTitle("設定")
        .sheet(isPresented: $showBackupFolderPicker) {
            BackupFolderPicker { folderURL in
                showBackupFolderPicker = false
                saveBackup(to: folderURL)
            }
        }
        .fileImporter(
            isPresented: $showBackupImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {

            case .success(let urls):
                guard let fileURL = urls.first else { return }
                prepareBackupForRestore(from: fileURL)

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
        .alert(
            backupSuccessTitle,
            isPresented: Binding(
                get: { backupSuccessMessage != nil },
                set: { newValue in
                    if !newValue {
                        backupSuccessMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                backupSuccessMessage = nil
            }
        } message: {
            Text(backupSuccessMessage ?? "")
        }

        .alert(
            "バックアップを読み込みました",
            isPresented: $showRestoreConfirmation
        ) {
            Button("キャンセル", role: .cancel) {
                pendingRestoreBackup = nil
                pendingRestoreFileName = ""
            }

            Button("復元", role: .destructive) {
                restorePendingBackup()
            }

        } message: {
            Text("""
            \(pendingRestoreFileName)

            このバックアップを復元しますか？

            単語カード、例文・ノート、コラムはバックアップ時点の内容に戻ります。
            メモは現在の内容と安全に統合されます。
            """)
        }

        }   // ← body の最後の }
    
    // MARK: - 統合バックアップ保存

    @MainActor
    private func saveBackup(to selectedFolderURL: URL) {

        // 🧸WordsForest自身のDocuments配下は
        // アプリ削除時に一緒に消えるため使用禁止
        if isInsideAppDocuments(selectedFolderURL) {
            backupErrorMessage = """
            この場所はWordsForestを削除すると一緒に消えるため、
            バックアップ先には使用できません。

            「🧸WordsForest」以外の場所を選んでください。
            """
            return
        }

        let didStartAccess =
            selectedFolderURL.startAccessingSecurityScopedResource()

        defer {
            if didStartAccess {
                selectedFolderURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            // 現在のWordsForestを1箱にまとめる
            let backup = WordsForestBackup.makeCurrentBackup()

            // JSON化
            let data = try backup.encodedData()

            // ユーザーが選んだ場所に
            // 🌳WordsForestバックアップ を用意する
            let backupFolderName = "🌳WordsForestバックアップ"

            let backupFolderURL: URL

            if selectedFolderURL.lastPathComponent == backupFolderName {

                // すでにバックアップフォルダそのものを選んだ場合
                // → その場所をそのまま使う
                backupFolderURL = selectedFolderURL

            } else {

                // 親フォルダを選んだ場合
                // → その中にバックアップフォルダを自動作成
                backupFolderURL = selectedFolderURL
                    .appendingPathComponent(
                        backupFolderName,
                        isDirectory: true
                    )

                if !FileManager.default.fileExists(
                    atPath: backupFolderURL.path
                ) {
                    try FileManager.default.createDirectory(
                        at: backupFolderURL,
                        withIntermediateDirectories: true
                    )
                }
            }

            // 日時入りJSON
            let fileURL = backupFolderURL
                .appendingPathComponent(
                    makeBackupFileName(for: backup.exportedAt)
                )

            try data.write(
                to: fileURL,
                options: .atomic
            )

            backupSuccessTitle = "バックアップを保存しました"
            
            backupSuccessMessage = """
            🌳WordsForestバックアップ に保存しました。

            \(fileURL.lastPathComponent)
            """

        } catch {
            backupErrorMessage = error.localizedDescription
        }
    }

    private func prepareBackupForRestore(from fileURL: URL) {

        let didStartAccess =
            fileURL.startAccessingSecurityScopedResource()

        defer {
            if didStartAccess {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: fileURL)

            let backup = try WordsForestBackup.decoded(
                from: data
            )

            pendingRestoreBackup = backup
            pendingRestoreFileName = fileURL.lastPathComponent

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showRestoreConfirmation = true
            }
        } catch {
            backupErrorMessage = """
            このファイルはWordsForestのバックアップとして読み込めませんでした。

            \(error.localizedDescription)
            """
        }
    }
    
    @MainActor
    private func restorePendingBackup() {

        guard let backup = pendingRestoreBackup else {
            return
        }

        let restoredFileName = pendingRestoreFileName

        // ① 単語カード・My Collection・覚えたBOX
        HomeworkStore.shared.restoreFromWordsForestBackup(
            words: backup.words,
            favoriteIDs: backup.favoriteIDs,
            learnedIDs: backup.learnedIDs
        )

        // ② 例文・和訳・Note
        ExampleStore.shared.restoreFromWordsForestBackup(
            examples: backup.examples,
            wordNotes: backup.wordNotes
        )

        // ③ コラム
        ColumnStore.shared.restoreFromWordsForestBackup(
            articles: backup.articles
        )

        // ④ メモ
        StudentMemoStore.shared.restoreFromWordsForestBackup(
            memoPages: backup.memoPages
        )

        pendingRestoreBackup = nil
        pendingRestoreFileName = ""

        DispatchQueue.main.async {
            backupSuccessTitle = "バックアップを復元しました"

            backupSuccessMessage = """
            単語カード、例文・ノート、コラム、メモを復元しました。

            \(restoredFileName)
            """
        }
    }
    // MARK: - バックアップファイル名

    private func makeBackupFileName(for date: Date) -> String {

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"

        let timestamp = formatter.string(from: date)

        return "WordsForest-Backup-\(timestamp).json"
    }


    // MARK: - 🧸WordsForest配下かチェック

    private func isInsideAppDocuments(_ selectedURL: URL) -> Bool {

        guard let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            return false
        }

        let selectedPath = selectedURL
            .resolvingSymlinksInPath()
            .standardizedFileURL
            .path

        let documentsPath = documentsURL
            .resolvingSymlinksInPath()
            .standardizedFileURL
            .path

        return selectedPath == documentsPath
            || selectedPath.hasPrefix(documentsPath + "/")
    }
}
