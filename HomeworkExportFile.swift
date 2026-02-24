//
import Foundation
import SwiftUI

enum HomeworkExportFile {

    /// JSONファイル名（例: 2025-12-20-words-cycle3-pair0.json）
    static func makeFileName(for payload: HomeworkExportPayload) -> String {
        "\(payload.id).json"
    }

    /// Files（書類フォルダ）に JSON(Data) を保存してURLを返す
    @discardableResult
    static func saveToDocuments(_ data: Data, fileName: String) throws -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = dir.appendingPathComponent(fileName)
        try data.write(to: url, options: [.atomic])
        return url
    }

    /// payload → JSON(Data)（pretty）
    static func makePrettyJSONData(_ payload: HomeworkExportPayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    /// UI(fileExporter)用：payloadを確定→pretty JSON(Data)→JSONTextDocument化して返す
    static func makeExportDocument(
        hw: HomeworkState,
        requiredCount: Int = 10,
        totalCount: Int = 24
    ) throws -> (doc: JSONTextDocument, fileName: String, payload: HomeworkExportPayload) {

        #if DEBUG
        print("✅✅ makeExportDocument ENTER")
        print("  cycleIndex =", hw.currentCycleIndex)
        print("  pair =", hw.currentPair.rawValue)
        #endif

        let payload = HomeworkPackStore.shared.buildOrLoadFixedPack(
            hw: hw,
            requiredCount: requiredCount,
            totalCount: totalCount
        )

        #if DEBUG
        print("✅✅ payload made")
        print("  payload.createdAt =", payload.createdAt)
        print("  payload.id =", payload.id)
        print("  items count =", payload.items.count)
        #endif

        let data = try makePrettyJSONData(payload)
        let json = String(data: data, encoding: .utf8) ?? "{}"

        let doc = JSONTextDocument(text: json)
        let fileName = makeFileName(for: payload)

        return (doc: doc, fileName: fileName, payload: payload)
    }
    
    /// 「今サイクル」を確定→JSON(Data)を返す（保存はしない / UIのfileExporter用）
    static func makeCurrentHomeworkJSONData(
        hw: HomeworkState,
        requiredCount: Int = 10,
        totalCount: Int = 24
    ) throws -> (payload: HomeworkExportPayload, data: Data) {

        print("✅✅ makeCurrentHomeworkJSONData ENTER")
        print("  cycleIndex =", hw.currentCycleIndex)
        print("  pair =", hw.currentPair.rawValue)

        let payload = HomeworkPackStore.shared.buildOrLoadFixedPack(
            hw: hw,
            requiredCount: requiredCount,
            totalCount: totalCount
        )

        print("✅✅ payload made")
        print("  payload.createdAt =", payload.createdAt)
        print("  payload.id =", payload.id)
        print("  items count =", payload.items.count)

        let data = try makePrettyJSONData(payload)
        return (payload, data)
    }
    
    /// 「今サイクル」を確定→JSON生成→Filesに保存→URL返却
    static func exportCurrentHomework(
        hw: HomeworkState,
        requiredCount: Int = 10,
        totalCount: Int = 24
    ) throws -> URL {

        print("✅✅ exportCurrentHomework ENTER")
        print("  cycleIndex =", hw.currentCycleIndex)
        print("  pair =", hw.currentPair.rawValue)

        let payload = HomeworkPackStore.shared.buildOrLoadFixedPack(
            hw: hw,
            requiredCount: requiredCount,
            totalCount: totalCount
        )

        print("✅✅ payload made")
        print("  payload.createdAt =", payload.createdAt)
        print("  payload.id =", payload.id)
        print("  items count =", payload.items.count)

        let data = try makePrettyJSONData(payload)
        let fileName = makeFileName(for: payload)
        let url = try saveToDocuments(data, fileName: fileName)

        print("✅ EXPORT SAVED fileName=\(fileName)")

        return url
    }
}
