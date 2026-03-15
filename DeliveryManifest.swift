//
//  DeliveryManifest.swift
//  WordsForest
//
//  Created by Nami .T on 2026/03/16.
//

import Foundation

struct DeliveryManifest: Codable, Equatable {
    /// 最新宿題の payload ID
    /// 例: "2026-03-16-words-cycle4-pair1"
    var latestHomeworkPayloadID: String?

    /// Home表示用の日付
    /// 例: "2026/03/16"
    var latestHomeworkDateText: String?

    /// Home表示用の宿題名
    /// 例: "動詞＋副詞"
    var latestHomeworkLabel: String?

    /// Home表示用の語数
    /// 例: 24
    var latestHomeworkCount: Int?

    /// 最新コラム番号
    /// 例: 25
    var latestColumnArticleID: Int?

    /// manifest 更新日時（デバッグ/表示用）
    var updatedAtISO: String

    init(
        latestHomeworkPayloadID: String? = nil,
        latestHomeworkDateText: String? = nil,
        latestHomeworkLabel: String? = nil,
        latestHomeworkCount: Int? = nil,
        latestColumnArticleID: Int? = nil,
        updatedAtISO: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.latestHomeworkPayloadID = latestHomeworkPayloadID
        self.latestHomeworkDateText = latestHomeworkDateText
        self.latestHomeworkLabel = latestHomeworkLabel
        self.latestHomeworkCount = latestHomeworkCount
        self.latestColumnArticleID = latestColumnArticleID
        self.updatedAtISO = updatedAtISO
    }
}

enum DeliveryManifestFile {

    static func makeFileName() -> String {
        "wf-manifest.json"
    }

    static func makePrettyJSONData(_ manifest: DeliveryManifest) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(manifest)
    }

    static func makeExportDocument(
        _ manifest: DeliveryManifest
    ) throws -> (doc: JSONTextDocument, fileName: String) {
        let data = try makePrettyJSONData(manifest)
        let json = String(data: data, encoding: .utf8) ?? "{}"
        return (
            doc: JSONTextDocument(text: json),
            fileName: makeFileName()
        )
    }
}
