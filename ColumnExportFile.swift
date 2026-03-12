//
//  ColumnExportFile.swift
//  WordsForest
//
//  Created by Nami .T on 2026/03/13.
//

import Foundation
import SwiftUI

enum ColumnExportFile {

    /// JSONファイル名（例: 2026-03-14-column-25.json）
    static func makeFileName(for payload: ColumnExportPayload) -> String {
        "\(payload.id).json"
    }

    /// payload → pretty JSON(Data)
    static func makePrettyJSONData(_ payload: ColumnExportPayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(payload)
    }

    /// 1本の記事を payload 化
    static func makePayload(for article: ColumnArticle, now: Date = Date()) -> ColumnExportPayload {
        let iso = ISO8601DateFormatter()
        let day = dayString(from: now)

        return ColumnExportPayload(
            id: "\(day)-column-\(article.id)",
            createdAt: iso.string(from: now),
            items: [article]
        )
    }

    /// UI(fileExporter)用：article → payload → pretty JSON → JSONTextDocument
    static func makeExportDocument(
        for article: ColumnArticle,
        now: Date = Date()
    ) throws -> (doc: JSONTextDocument, fileName: String, payload: ColumnExportPayload) {

        let payload = makePayload(for: article, now: now)
        let data = try makePrettyJSONData(payload)
        let json = String(data: data, encoding: .utf8) ?? "{}"

        let doc = JSONTextDocument(text: json)
        let fileName = makeFileName(for: payload)

        return (doc: doc, fileName: fileName, payload: payload)
    }

    // MARK: - Helpers

    private static func dayString(from date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
