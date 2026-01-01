//
//  HomeworkExportFile.swift
//  WordsForest
//
//  Created by Nami .T on 2025/12/20.
//

import Foundation
import SwiftUI

enum HomeworkExportFile {

    /// JSONファイル名（例: 2025-12-20-words-cycle3-pair0.json）
    static func makeFileName(for payload: HomeworkExportPayload) -> String {
        // payload.id は "YYYY-MM-DD-words-cycleX-pairY" みたいにしてある想定
        return "\(payload.id).json"
    }

    /// Files（書類フォルダ）に JSON を保存してURLを返す
    @discardableResult
    static func saveToDocuments(_ json: String, fileName: String) throws -> URL {

        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = dir.appendingPathComponent(fileName)

        guard let data = json.data(using: .utf8) else {
            throw NSError(domain: "HomeworkExportFile", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "JSONをUTF-8に変換できませんでした"
            ])
        }

        try data.write(to: url, options: [.atomic])
        return url
    }

    /// 「今サイクル」を確定→JSON生成→Filesに保存→URL返却
    static func exportCurrentHomework(
        hw: HomeworkState,
        requiredCount: Int = 10,
        totalCount: Int = 24
    ) throws -> URL {

        // ① 24語確定（既に確定済なら同じものが返る）
        let payload = HomeworkPackStore.shared.buildOrLoadFixedPack(
            hw: hw,
            requiredCount: requiredCount,
            totalCount: totalCount
        )

        // ② JSON文字列へ（pretty）
        let json = HomeworkPackStore.shared.makePrettyJSONString(payload)

        // ③ Filesへ保存
        let fileName = makeFileName(for: payload)
        let url = try saveToDocuments(json, fileName: fileName)

        return url
    }
}

