//
//  BackupFolderPicker.swift
//  WordsForest
//
//  Created by Nami .T on 2026/09/24.
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

// MARK: - バックアップ保存先フォルダ選択

struct BackupFolderPicker: UIViewControllerRepresentable {

    let onPick: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(
        context: Context
    ) -> UIDocumentPickerViewController {

        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.folder],
            asCopy: false
        )

        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false

        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIDocumentPickerViewController,
        context: Context
    ) {
        // 更新処理なし
    }


    // MARK: - Coordinator

    final class Coordinator: NSObject, UIDocumentPickerDelegate {

        let parent: BackupFolderPicker

        init(parent: BackupFolderPicker) {
            self.parent = parent
        }

        func documentPicker(
            _ controller: UIDocumentPickerViewController,
            didPickDocumentsAt urls: [URL]
        ) {
            guard let folderURL = urls.first else {
                return
            }

            parent.onPick(folderURL)
        }
    }
}
