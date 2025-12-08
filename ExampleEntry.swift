//
//  ExampleEntry.swift
//  WordsForest
//
//  Created by Nami .T on 2025/12/04.
//

import Foundation

/// 1つの例文を表すデータ
struct ExampleEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var en: String
    var ja: String?
    var note: String?

    init(id: UUID = UUID(), en: String, ja: String? = nil, note: String? = nil) {
        self.id = id
        self.en = en
        self.ja = ja
        self.note = note
    }

    var isEmpty: Bool {
        en.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (ja?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }
}
