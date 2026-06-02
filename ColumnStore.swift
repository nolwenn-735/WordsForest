//
//  ColumnStore.swift
//  WordsForest
//
//  Created by Nami .T on 2025/12/21.
//

import Foundation
import SwiftUI

// 配布JSONの器
struct ColumnExportPayload: Codable {
    var id: String          // 例: "2025-12-21-column-pack"
    var createdAt: String   // ISO8601（目安でOK）
    var items: [ColumnArticle]
}

@MainActor
final class ColumnStore: ObservableObject {
    static let shared = ColumnStore()

    @AppStorage("column_articles_json") private var raw: String = ""
    @AppStorage("column_lastImportedPayloadID") private var lastImportedPayloadID: String = ""

    // 🆕表示フラグ + 自然消滅期限（7日）
    @AppStorage("column_hasNew") private var hasNew: Bool = false
    @AppStorage("column_newUntilISO") private var newUntilISO: String = ""

    @Published private(set) var articles: [ColumnArticle] = []

    private let iso = ISO8601DateFormatter()

    private init() {
        self.articles = loadOrSeed()
    }

    // 初回は ColumnData を seed
    private func loadOrSeed() -> [ColumnArticle] {
        if let data = raw.data(using: .utf8),
           let list = try? JSONDecoder().decode([ColumnArticle].self, from: data),
           !list.isEmpty {
            return list.sorted { $0.id > $1.id }
        }

        let seeded = ColumnData.all.sorted { $0.id > $1.id }
        persist(seeded)
        return seeded
    }

    private func persist(_ list: [ColumnArticle]) {
        let data = (try? JSONEncoder().encode(list)) ?? Data("[]".utf8)
        raw = String(data: data, encoding: .utf8) ?? "[]"
        articles = list
    }

    // ✅ HOME用：🆕バッジ出す？
    func shouldShowNewBadge(now: Date = Date()) -> Bool {
        guard hasNew else { return false }
        guard let until = iso.date(from: newUntilISO) else { return true } // 期限が壊れてたら出す
        return now < until
    }

    // ✅ 一覧を開いたら既読扱い（🆕消す）
    func markAsSeen() {
        hasNew = false
    }

    // ✅ 取り込み（JSONファイル）
    func importPayload(_ payload: ColumnExportPayload) throws {
        // 同じpayloadを2回入れたら無反応（既に取り込み済み）
        if payload.id == lastImportedPayloadID { return }

        // 既存 + 新規をidでマージ（同idは上書き＝更新）
        var dict = Dictionary(uniqueKeysWithValues: articles.map { ($0.id, $0) })
        for item in payload.items {
            dict[item.id] = item
        }

        let merged = dict.values.sorted { $0.id > $1.id }
        persist(merged)

        // 🆕を立てる（7日残す）
        lastImportedPayloadID = payload.id
        hasNew = true

        let until = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        newUntilISO = iso.string(from: until)
    }
    func nextID() -> Int {
        (articles.map { $0.id }.max() ?? 0) + 1
    }

    func upsert(_ article: ColumnArticle) {
        var dict = Dictionary(uniqueKeysWithValues: articles.map { ($0.id, $0) })
        dict[article.id] = article
        let merged = dict.values.sorted { $0.id > $1.id }
        persist(merged)
    }
    // ✅ 記事を削除
    func delete(_ article: ColumnArticle) {
        var list = articles
        list.removeAll { $0.id == article.id }
        persist(list)
    }
    
    // ✅ 開発用：コラムを ColumnData の初期状態に戻す
    func resetToSeedForDebug() {
        lastImportedPayloadID = ""
        hasNew = false
        newUntilISO = ""

        let seeded = ColumnData.all.sorted { $0.id > $1.id }
        persist(seeded)
    }
}

