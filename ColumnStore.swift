//
//  Created by Nami .T on 2025/12/21.
//  ColumnStore.swift
//  WordsForest
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
    /// アプリ収録の読み取り専用コラム
    private(set) var bundledArticles: [ColumnArticle] = []

    /// 教師作成・配布で追加されたコラム
    private var distributedArticles: [ColumnArticle] = []

    private let iso = ISO8601DateFormatter()

    private init() {
        bundledArticles = ColumnData.all.sorted { $0.id > $1.id }
        distributedArticles = loadDistributedArticles()
        rebuildArticles()
    }

    /// 教師作成・配布コラムだけを端末保存から読む
    private func loadDistributedArticles() -> [ColumnArticle] {
        guard let data = raw.data(using: .utf8),
              let list = try? JSONDecoder().decode(
                [ColumnArticle].self,
                from: data
              )
        else {
            return []
        }

        return list
            .filter { $0.id > 0 }
            .sorted { $0.id > $1.id }
    }

    /// 教師作成・配布コラムだけを端末へ保存する
    private func persistDistributed(
        _ list: [ColumnArticle]
    ) {
        let cleaned = list
            .filter { $0.id > 0 }
            .sorted { $0.id > $1.id }

        let data =
            (try? JSONEncoder().encode(cleaned))
            ?? Data("[]".utf8)

        raw =
            String(data: data, encoding: .utf8)
            ?? "[]"

        distributedArticles = cleaned
        rebuildArticles()
    }

    /// 画面表示用は
    /// Bundled基礎コラム + 教師作成・配布コラム
    private func rebuildArticles() {
        articles =
            (bundledArticles + distributedArticles)
            .sorted { $0.id > $1.id }
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
        let incomingItems = payload.items
            .filter { $0.id > 0 }

        // 同じpayloadでも、記事本体が端末内に無ければ再取り込みする
        if payload.id == lastImportedPayloadID {
            let allItemsAlreadyExist = incomingItems.allSatisfy { incoming in
                distributedArticles.contains { $0.id == incoming.id }
            }

            if allItemsAlreadyExist {
                return
            }
        }

        // 教師作成・配布コラムだけをidでマージ
        var dict = Dictionary(
            uniqueKeysWithValues:
                distributedArticles.map { ($0.id, $0) }
        )

        for item in incomingItems {
            dict[item.id] = item
        }

        let merged = dict.values.sorted {
            $0.id > $1.id
        }

        persistDistributed(merged)

        // 🆕を立てる（7日残す）
        lastImportedPayloadID = payload.id
        hasNew = true

        let until =
            Calendar.current.date(
                byAdding: .day,
                value: 7,
                to: Date()
            )
            ?? Date()

        newUntilISO = iso.string(from: until)
    }

    func nextID() -> Int {
        (distributedArticles.map { $0.id }.max() ?? 0) + 1
    }

    func upsert(_ article: ColumnArticle) {
        guard article.id > 0 else {
            return
        }

        var dict = Dictionary(
            uniqueKeysWithValues:
                distributedArticles.map { ($0.id, $0) }
        )

        dict[article.id] = article

        let merged = dict.values.sorted {
            $0.id > $1.id
        }

        persistDistributed(merged)
    }

    // ✅ 教師作成・配布記事だけを削除
    func delete(_ article: ColumnArticle) {
        guard article.id > 0 else {
            return
        }

        var list = distributedArticles

        list.removeAll {
            $0.id == article.id
        }

        persistDistributed(list)
    }

    // ✅ 開発用：教師作成・配布コラムを空に戻す
    func resetToSeedForDebug() {
        lastImportedPayloadID = ""
        hasNew = false
        newUntilISO = ""

        persistDistributed([])
    }
}

// MARK: - WordsForest Backup support

extension ColumnStore {

    /// 統合バックアップへ渡す教師作成・配布コラム
    var backupArticles: [ColumnArticle] {
        distributedArticles
    }
}

// MARK: - WordsForest Backup restore support

extension ColumnStore {

    /// 統合バックアップからコラム記事を復元する
    ///
    /// ※ 🆕表示などの一時的なUI状態は復元しない
    func restoreFromWordsForestBackup(
        articles restoredArticles: [ColumnArticle]
    ) {

        let restoredDistributed = restoredArticles
            .filter { $0.id > 0 }
            .sorted { $0.id > $1.id }

        // バックアップからは教師作成・配布コラムだけ復元
        persistDistributed(restoredDistributed)

        // 🆕関連はバックアップ対象外なのでリセット
        lastImportedPayloadID = ""
        hasNew = false
        newUntilISO = ""
    }
}
