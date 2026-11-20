//
//  ColumnArticle.swift
//  WordsForest
//
//  Created by Nami .T on 2026/11/05.
//
//
//  ColumnArticle.swift
//  WordsForest
//
//

import Foundation

struct ColumnArticle: Identifiable, Hashable, Codable {
    var id: Int
    var title: String
    var body: String
    var tags: [String]

    /// このコラム内容の現在の版。
    /// 新規作成時は1。
    var revision: Int

    /// 生徒向け通知マニフェストの書き出しまで完了した最新revision。
    /// 0なら一度も配布されていない。
    var distributedRevision: Int

    /// 生徒側で本文を削除し、目次だけ残す削除済み状態。
    var isDeleted: Bool

    /// 一度でも生徒向け配布が完了しているか。
    var hasBeenDistributed: Bool {
        distributedRevision > 0
    }

    init(
        id: Int,
        title: String,
        body: String,
        tags: [String],
        revision: Int = 1,
        distributedRevision: Int = 0,
        isDeleted: Bool = false
    ) {
        let normalizedRevision = max(1, revision)

        self.id = id
        self.title = title
        self.body = body
        self.tags = tags
        self.revision = normalizedRevision
        self.distributedRevision = max(
            0,
            min(distributedRevision, normalizedRevision)
        )
        self.isDeleted = isDeleted
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case body
        case tags
        case revision
        case distributedRevision
        case isDeleted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        id = try container.decode(
            Int.self,
            forKey: .id
        )

        title = try container.decode(
            String.self,
            forKey: .title
        )

        body = try container.decode(
            String.self,
            forKey: .body
        )

        tags = try container.decode(
            [String].self,
            forKey: .tags
        )

        revision = max(
            1,
            try container.decodeIfPresent(
                Int.self,
                forKey: .revision
            ) ?? 1
        )

        if let savedDistributedRevision =
            try container.decodeIfPresent(
                Int.self,
                forKey: .distributedRevision
            ) {

            distributedRevision = max(
                0,
                min(savedDistributedRevision, revision)
            )

        } else {
            // 旧形式には配布履歴が無い。
            // 正のIDは既に配布済みだった可能性を優先し、
            // 安全側として現在revisionまで配布済み扱いにする。
            distributedRevision = id > 0
                ? revision
                : 0
        }

        isDeleted =
            try container.decodeIfPresent(
                Bool.self,
                forKey: .isDeleted
            ) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        try container.encode(
            id,
            forKey: .id
        )

        try container.encode(
            title,
            forKey: .title
        )

        try container.encode(
            body,
            forKey: .body
        )

        try container.encode(
            tags,
            forKey: .tags
        )

        try container.encode(
            revision,
            forKey: .revision
        )

        try container.encode(
            distributedRevision,
            forKey: .distributedRevision
        )

        try container.encode(
            isDeleted,
            forKey: .isDeleted
        )
    }
}
