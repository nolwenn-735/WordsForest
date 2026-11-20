
//
//  Created by Nami .T on 2025/12/21.
//
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

// コラム削除を要求した結果
enum ColumnDeleteResult: Equatable {

    /// 未配布かつ最新No.なので、完全削除した。
    /// 次回新規作成時に同じNo.を再利用できる。
    case permanentlyDeletedUndistributed

    /// 未配布だが、このNo.より後ろに別コラムが存在するため削除不可。
    /// UIでは「削除せず内容を編集してください」と案内する。
    case blockedUndistributedNonLatest

    /// 一度以上配布済みなので、完全削除せず削除済みレコードへ変更した。
    /// この削除版をコラムJSON + manifestで生徒へ配布する必要がある。
    case markedDeletedNeedsDistribution

    /// すでに削除済み。
    case alreadyDeleted

    /// BundledColumnsなど、正のIDではないため削除対象外。
    case ignoredBundled

    /// 対象のコラムがStore内に見つからない。
    case notFound
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

    /// 正のIDを持つコラム。
    /// 教師作成の未配布コラム、配布済みコラム、削除済みレコードを含む。
    private var distributedArticles: [ColumnArticle] = []

    private let iso = ISO8601DateFormatter()

    private init() {
        bundledArticles = loadBundledArticles()
        distributedArticles = loadDistributedArticles()
        rebuildArticles()
    }

    /// アプリに収録した基礎コラムをBundled JSONから読む
    private func loadBundledArticles() -> [ColumnArticle] {
        guard let url = Bundle.main.url(
            forResource: "BundledColumns",
            withExtension: "json"
        ) else {
            print("❌ BundledColumns.json が見つかりません")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let list = try JSONDecoder().decode(
                [ColumnArticle].self,
                from: data
            )

            return list
                .filter { $0.id < 0 }
                .sorted { $0.id > $1.id }

        } catch {
            print(
                "❌ BundledColumns.json 読み込み失敗:",
                error
            )
            return []
        }
    }

    /// 正のIDを持つコラムだけを端末保存から読む
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

    /// 正のIDを持つコラムだけを端末へ保存する
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
    /// Bundled基礎コラム + 正のIDを持つコラム
    private func rebuildArticles() {
        articles =
            (bundledArticles + distributedArticles)
            .sorted { $0.id > $1.id }
    }

    // ✅ HOME用：🆕バッジ出す？
    func shouldShowNewBadge(now: Date = Date()) -> Bool {
        guard hasNew else { return false }

        guard let until = iso.date(from: newUntilISO) else {
            return true
        }

        return now < until
    }

    // ✅ 一覧を開いたら既読扱い（🆕消す）
    func markAsSeen() {
        hasNew = false
    }

    // =======================================================
    // MARK: - コラム取得
    // =======================================================

    /// 正のIDを持つコラムをNo.で取得する
    func article(id: Int) -> ColumnArticle? {
        distributedArticles.first {
            $0.id == id
        }
    }

    // =======================================================
    // MARK: - 取り込み
    // =======================================================

    /// 配布JSONを取り込む。
    ///
    /// 新しいrevisionは同じNo.を上書きする。
    /// 古いrevisionを後から取り込んでも巻き戻さない。
    /// 削除済みrevisionを取り込んだ場合も、同じNo.を削除済みに更新する。
    func importPayload(_ payload: ColumnExportPayload) throws {
        let incomingItems = payload.items
            .filter { $0.id > 0 }

        var dict = Dictionary(
            uniqueKeysWithValues:
                distributedArticles.map { ($0.id, $0) }
        )

        var contentChanged = false
        var metadataChanged = false

        for rawIncoming in incomingItems {
            let incoming = normalizedIncomingArticle(
                rawIncoming
            )

            guard let current = dict[incoming.id] else {
                dict[incoming.id] = incoming
                contentChanged = true
                continue
            }

            if shouldReplace(
                current: current,
                with: incoming
            ) {
                dict[incoming.id] = incoming
                contentChanged = true
                continue
            }

            let sameRevision =
                incoming.revision == current.revision

            let sameDeletedState =
                incoming.isDeleted == current.isDeleted

            let sameContent =
                articleContentMatches(
                    current,
                    incoming
                )

            if sameRevision,
               sameDeletedState,
               sameContent,
               incoming.distributedRevision > current.distributedRevision {

                var updated = current
                updated.distributedRevision =
                    min(
                        incoming.distributedRevision,
                        current.revision
                    )

                dict[incoming.id] = updated
                metadataChanged = true
            }
        }

        if contentChanged || metadataChanged {
            let merged = dict.values.sorted {
                $0.id > $1.id
            }

            persistDistributed(merged)
        }

        lastImportedPayloadID = payload.id

        guard contentChanged else {
            return
        }

        // 🆕を立てる（7日残す）
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

    /// 生徒端末へ届いたコラムJSONは、
    /// そのrevisionまで配布済みの内容として扱う。
    private func normalizedIncomingArticle(
        _ article: ColumnArticle
    ) -> ColumnArticle {
        ColumnArticle(
            id: article.id,
            title: article.title,
            body: article.body,
            tags: article.tags,
            revision: article.revision,
            distributedRevision: article.revision,
            isDeleted: article.isDeleted
        )
    }

    /// incomingを現在の同一No.へ上書きしてよいか。
    private func shouldReplace(
        current: ColumnArticle,
        with incoming: ColumnArticle
    ) -> Bool {

        if incoming.revision > current.revision {
            return true
        }

        if incoming.revision < current.revision {
            return false
        }

        // 同じrevisionで削除状態が食い違う場合、
        // 削除済み側を優先して古い本文を復活させない。
        if current.isDeleted != incoming.isDeleted {
            return incoming.isDeleted
        }

        // 旧形式JSONなど、revision情報が同じまま内容だけ更新された
        // ケースにも対応する。
        return !articleContentMatches(
            current,
            incoming
        )
    }

    private func articleContentMatches(
        _ lhs: ColumnArticle,
        _ rhs: ColumnArticle
    ) -> Bool {
        lhs.title == rhs.title &&
        lhs.body == rhs.body &&
        lhs.tags == rhs.tags
    }

    // =======================================================
    // MARK: - No.発行
    // =======================================================

    func nextID() -> Int {
        (distributedArticles.map { $0.id }.max() ?? 0) + 1
    }

    // =======================================================
    // MARK: - 新規保存・再編集保存
    // =======================================================

    /// 新規コラムまたは既存コラムの編集内容を保存する。
    ///
    /// 新規:
    /// revision 1 / distributedRevision 0
    ///
    /// 既存:
    /// 内容が変わったときだけrevisionを1進める。
    /// distributedRevisionは維持する。
    func upsert(_ article: ColumnArticle) {
        guard article.id > 0 else {
            return
        }

        var dict = Dictionary(
            uniqueKeysWithValues:
                distributedArticles.map { ($0.id, $0) }
        )

        if let current = dict[article.id] {

            // 削除済みコラムは復活させない。
            guard !current.isDeleted else {
                return
            }

            let contentChanged =
                current.title != article.title ||
                current.body != article.body ||
                current.tags != article.tags

            guard contentChanged else {
                return
            }

            let updated = ColumnArticle(
                id: current.id,
                title: article.title,
                body: article.body,
                tags: article.tags,
                revision: current.revision + 1,
                distributedRevision: current.distributedRevision,
                isDeleted: false
            )

            dict[current.id] = updated

        } else {
            let created = ColumnArticle(
                id: article.id,
                title: article.title,
                body: article.body,
                tags: article.tags,
                revision: 1,
                distributedRevision: 0,
                isDeleted: false
            )

            dict[created.id] = created
        }

        let merged = dict.values.sorted {
            $0.id > $1.id
        }

        persistDistributed(merged)
    }

    // =======================================================
    // MARK: - 配布済みrevision
    // =======================================================

    /// 通知マニフェストの書き出しが正常に完了した時点で呼ぶ。
    ///
    /// ここで初めて、そのrevisionを「生徒へ配布済み」と確定する。
    @discardableResult
    func markDistributed(
        articleID: Int,
        revision: Int? = nil
    ) -> Bool {

        guard articleID > 0 else {
            return false
        }

        guard let current = distributedArticles.first(
            where: { $0.id == articleID }
        ) else {
            return false
        }

        let requestedRevision =
            revision ?? current.revision

        let targetRevision =
            min(
                max(1, requestedRevision),
                current.revision
            )

        guard targetRevision > current.distributedRevision else {
            return true
        }

        var updated = current
        updated.distributedRevision = targetRevision

        var dict = Dictionary(
            uniqueKeysWithValues:
                distributedArticles.map { ($0.id, $0) }
        )

        dict[current.id] = updated

        let merged = dict.values.sorted {
            $0.id > $1.id
        }

        persistDistributed(merged)

        return true
    }

    // =======================================================
    // MARK: - 削除
    // =======================================================

    /// コラム削除ルール
    ///
    /// 1. Bundled:
    ///    削除不可
    ///
    /// 2. 未配布 + 最新No.:
    ///    完全削除。
    ///    次回新規作成時に同じNo.を再利用できる。
    ///
    /// 3. 未配布 + 後ろに別No.あり:
    ///    削除不可。
    ///    No.の連続性を守るため編集を促す。
    ///
    /// 4. 一度でも配布済み:
    ///    完全削除しない。
    ///    同じNo.の削除済みrevisionを作る。
    @discardableResult
    func delete(
        _ article: ColumnArticle
    ) -> ColumnDeleteResult {

        guard article.id > 0 else {
            return .ignoredBundled
        }

        guard let current = distributedArticles.first(
            where: { $0.id == article.id }
        ) else {
            return .notFound
        }

        if current.isDeleted {
            return .alreadyDeleted
        }

        // 一度も配布していないコラム
        if !current.hasBeenDistributed {
            let latestID =
                distributedArticles
                    .map { $0.id }
                    .max()
                ?? 0

            guard current.id == latestID else {
                return .blockedUndistributedNonLatest
            }

            var list = distributedArticles

            list.removeAll {
                $0.id == current.id
            }

            persistDistributed(list)

            return .permanentlyDeletedUndistributed
        }

        // 一度でも配布したコラムは、
        // No.とタイトルを残した削除済みrevisionへ変更する。
        let deletedArticle = ColumnArticle(
            id: current.id,
            title: current.title,
            body: "",
            tags: [],
            revision: current.revision + 1,
            distributedRevision: current.distributedRevision,
            isDeleted: true
        )

        var dict = Dictionary(
            uniqueKeysWithValues:
                distributedArticles.map { ($0.id, $0) }
        )

        dict[current.id] = deletedArticle

        let merged = dict.values.sorted {
            $0.id > $1.id
        }

        persistDistributed(merged)

        return .markedDeletedNeedsDistribution
    }

    // =======================================================
    // MARK: - Debug
    // =======================================================

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

    /// 統合バックアップへ渡す正のIDを持つコラム
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

        // バックアップからは正のIDを持つコラムだけ復元
        persistDistributed(restoredDistributed)

        // 🆕関連はバックアップ対象外なのでリセット
        lastImportedPayloadID = ""
        hasNew = false
        newUntilISO = ""
    }
}
