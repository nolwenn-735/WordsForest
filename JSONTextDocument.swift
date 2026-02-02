//
import SwiftUI
import UniformTypeIdentifiers

struct JSONTextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var text: String

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            self.text = ""
            return
        }
        // 読み込みも一応UTF-8優先（念のためUTF-16もフォールバック）
        self.text = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .utf16)
            ?? ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // ★ここが重要：UTF-8で保存
        let data = text.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}
