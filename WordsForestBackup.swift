//
//  WordsForestBackup.swift
//  WordsForest
//
//  Created by Nami .T on 2026/09/24.
//

//
//  WordsForestBackup.swift
//  WordsForest
//
//  WordsForest 全体バックアップ用データ形式
//

import Foundation

// MARK: - WordsForest 統合バックアップ v1

struct WordsForestBackup: Codable {

    // バックアップ形式そのもののバージョン
    let formatVersion: Int

    // このバックアップを作成した日時
    let exportedAt: Date

    // MARK: 単語カード本体

    /// 単語・意味・品詞・UUID
    let words: [StoredWord]

    /// My Collection
    let favoriteIDs: [UUID]

    /// 覚えたBOX
    let learnedIDs: [UUID]

    // MARK: 例文・単語ノート

    /// key = "pos|word|meaning"
    let examples: [String: [ExampleEntry]]

    /// key = "pos|word"
    let wordNotes: [String: String]

    // MARK: コラム

    let articles: [ColumnArticle]

    // MARK: 生徒メモ

    let memoPages: [StudentMemoPage]
}

// MARK: - Backup Builder

extension WordsForestBackup {

    /// 現在のWordsForestの学習データを
    /// 統合バックアップ1箱にまとめる
    @MainActor
    static func makeCurrentBackup() -> WordsForestBackup {

        let homework = HomeworkStore.shared
        let examples = ExampleStore.shared
        let columns = ColumnStore.shared
        let memos = StudentMemoStore.shared

        return WordsForestBackup(
            formatVersion: 1,
            exportedAt: Date(),

            words: homework.backupWords,
            favoriteIDs: homework.backupFavoriteIDs,
            learnedIDs: homework.backupLearnedIDs,

            examples: examples.backupExamples,
            wordNotes: examples.backupWordNotes,

            articles: columns.backupArticles,

            memoPages: memos.backupMemoPages
        )
    }
}

// MARK: - Backup Encoder

extension WordsForestBackup {

    /// 統合バックアップをJSONデータに変換する
    func encodedData() throws -> Data {

        let encoder = JSONEncoder()

        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys
        ]

        encoder.dateEncodingStrategy = .iso8601

        return try encoder.encode(self)
    }
}

// MARK: - Temporary Backup File

extension WordsForestBackup {

    /// バックアップ用の日時入りファイル名
    private var backupFileName: String {

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"

        let timestamp = formatter.string(from: exportedAt)

        return "WordsForest-Backup-\(timestamp).json"
    }


    /// iOSの保存画面へ渡すための一時JSONファイルを作る
    func makeTemporaryFile() throws -> URL {

        // ① さきほど作ったEncoderでJSON化
        let data = try encodedData()

        // ② アプリの一時領域
        let temporaryDirectory = FileManager.default.temporaryDirectory

        // ③ 日時入りファイル名を付ける
        let fileURL = temporaryDirectory
            .appendingPathComponent(backupFileName)

        // ④ 一時ファイルとして書き出す
        try data.write(
            to: fileURL,
            options: .atomic
        )

        return fileURL
    }
}

// MARK: - Backup Decoder

extension WordsForestBackup {

    /// JSONデータからWordsForest統合バックアップを読み込む
    static func decoded(from data: Data) throws -> WordsForestBackup {

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let backup = try decoder.decode(
            WordsForestBackup.self,
            from: data
        )

        guard backup.formatVersion == 1 else {
            throw WordsForestBackupError.unsupportedVersion
        }

        return backup
    }
}


// MARK: - Backup Error

enum WordsForestBackupError: LocalizedError {

    case unsupportedVersion

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion:
            return "このバックアップは現在のWordsForestでは復元できません。"
        }
    }
}
