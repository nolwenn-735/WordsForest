//
//  WordsForestBackupFile.swift
//  WordsForest
//
//  Created by Nami .T on 2026/09/24.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - WordsForest統合バックアップ書き出し用ファイル

struct WordsForestBackupFile: FileDocument {

    static var readableContentTypes: [UTType] {
        [.json]
    }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let fileData = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        self.data = fileData
    }

    func fileWrapper(
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
