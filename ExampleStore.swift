//
//  ExampleStore.swift
//  WordsForest
//
import Foundation

/// 単語＋意味ごとの例文を保存する（Teacher編集用）
final class ExampleStore: ObservableObject {

    static let shared = ExampleStore()

    /// key = "pos|word|meaning" → [ExampleEntry]
    @Published private(set) var examples: [String: [ExampleEntry]] = [:]

    private let key = "example_store_v2"

    private init() { load() }

    // MARK: - Key

    private func normWord(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func normMeaning(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func makeKey(pos: PartOfSpeech, word: String, meaning: String) -> String {
        "\(pos.rawValue)|\(normWord(word))|\(normMeaning(meaning))"
    }

    // MARK: - CRUD（意味ごと）

    /// 1 meaning = 1例文（上書き）
    func saveExample(pos: PartOfSpeech, word: String, meaning: String, en: String, ja: String?, note: String?) {
        let k = makeKey(pos: pos, word: word, meaning: meaning)
        examples[k] = [ExampleEntry(en: en, ja: ja, note: note)]
        save()
    }

    func removeExample(pos: PartOfSpeech, word: String, meaning: String) {
        let k = makeKey(pos: pos, word: word, meaning: meaning)
        examples[k] = []
        save()
    }

    func examples(pos: PartOfSpeech, word: String, meaning: String) -> [ExampleEntry] {
        let k = makeKey(pos: pos, word: word, meaning: meaning)
        return examples[k] ?? []
    }

    func firstExample(pos: PartOfSpeech, word: String, meaning: String) -> ExampleEntry? {
        examples(pos: pos, word: word, meaning: meaning).first
    }

    // ✅ 互換：meaning未指定（暫定表示/Export用に1個返す）
    func firstExample(pos: PartOfSpeech, word: String) -> ExampleEntry? {
        let prefix = "\(pos.rawValue)|\(normWord(word))|"
        let keys = examples.keys.filter { $0.hasPrefix(prefix) }.sorted()
        for k in keys {
            if let e = examples[k]?.first { return e }
        }
        return nil
    }

  
    // MARK: - Save / Load

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
