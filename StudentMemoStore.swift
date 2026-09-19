//
//  StudentMemoStore.swift
//  WordsForest
//
//  Created by Nami .T on 2026/09/19.
//
import Foundation
import Combine

// MARK: - 1ページ分のメモ

struct StudentMemoPage: Identifiable, Codable, Hashable {
    let id: UUID

    var title: String
    var body: String

    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        body: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}


// MARK: - メモ保存Store

@MainActor
final class StudentMemoStore: ObservableObject {

    static let shared = StudentMemoStore()

    @Published private(set) var pages: [StudentMemoPage] = []

    private let fileName = "student-memos.json"

    private init() {
        load()
    }


    // MARK: - 新しいページを作る

    @discardableResult
    func createPage() -> UUID {
        let page = StudentMemoPage()

        pages.insert(page, at: 0)
        save()

        return page.id
    }


    // MARK: - ページを取得

    func page(id: UUID) -> StudentMemoPage? {
        pages.first { $0.id == id }
    }


    // MARK: - ページを更新

    func updatePage(
        id: UUID,
        title: String,
        body: String
    ) {
        guard let index = pages.firstIndex(where: { $0.id == id }) else {
            return
        }

        pages[index].title = title
        pages[index].body = body
        pages[index].updatedAt = Date()

        save()
    }


    // MARK: - ページを削除

    func deletePage(id: UUID) {
        pages.removeAll { $0.id == id }
        save()
    }


    // MARK: - Application Support の保存先

    private var fileURL: URL? {
        do {
            let applicationSupport = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )

            let wordsForestFolder = applicationSupport
                .appendingPathComponent(
                    "WordsForest",
                    isDirectory: true
                )

            if !FileManager.default.fileExists(
                atPath: wordsForestFolder.path
            ) {
                try FileManager.default.createDirectory(
                    at: wordsForestFolder,
                    withIntermediateDirectories: true
                )
            }

            return wordsForestFolder
                .appendingPathComponent(fileName)

        } catch {
#if DEBUG
            print("🟥 StudentMemo 保存先の作成失敗: \(error)")
#endif
            return nil
        }
    }


    // MARK: - 読み込み

    private func load() {
        guard let url = fileURL else {
            return
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
#if DEBUG
            print("📝 StudentMemo: まだ保存ファイルはありません")
            print("📝 StudentMemo path = \(url.path)")
#endif
            return
        }

        do {
            let data = try Data(contentsOf: url)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            pages = try decoder.decode(
                [StudentMemoPage].self,
                from: data
            )

#if DEBUG
            print("🟩 StudentMemo 読み込み成功: \(pages.count) pages")
            print("📝 StudentMemo path = \(url.path)")
#endif

        } catch {
#if DEBUG
            print("🟥 StudentMemo 読み込み失敗: \(error)")
#endif
        }
    }


    // MARK: - 保存

    private func save() {
        guard let url = fileURL else {
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [
                .prettyPrinted,
                .sortedKeys
            ]
            encoder.dateEncodingStrategy = .iso8601

            let data = try encoder.encode(pages)

            try data.write(
                to: url,
                options: .atomic
            )

#if DEBUG
            print("📝 StudentMemo 保存: \(pages.count) pages")
#endif

        } catch {
#if DEBUG
            print("🟥 StudentMemo 保存失敗: \(error)")
#endif
        }
    }
}


