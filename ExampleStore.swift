//
//  File.swift
//  WordsForest
//
// ExampleStore.swift
import Foundation

/// 単語ごとの例文を保存する
final class ExampleStore: ObservableObject {

    static let shared = ExampleStore()

    /// 単語 → [ExampleEntry]
    @Published private(set) var examples: [String: [ExampleEntry]] = [:]

    private let key = "example_store_v1"

    private init() {
        load()
    }

    // MARK: - CRUD

    func saveExample(for word: String, en: String, ja: String?, note: String?) {

        var list = examples[word] ?? []

        // 今は「1語につき1例文だけ」を想定 → 常に上書き
        let entry = ExampleEntry(en: en, ja: ja, note: note)

        list = [entry]
        examples[word] = list
        save()
    }

    func removeExample(for word: String) {
        examples[word] = []
        save()
    }

    func examples(for word: String) -> [ExampleEntry] {
        examples[word] ?? []
    }

    func firstExample(for word: String) -> ExampleEntry? {
        examples(for: word).first
    }

    // MARK: - save / load
    private func save() {
        if let data = try? JSONEncoder().encode(examples) {
            UserDefaults.standard.set(data, forKey: key)
            NotificationCenter.default.post(name: .examplesDidChange, object: nil)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: [ExampleEntry]].self, from: data) {
            examples = decoded
        }
    }
}

extension Notification.Name {
    static let examplesDidChange = Notification.Name("examplesDidChange")
}
