//
//  ExampleStore.swift 2026/02/16全置換版
//  WordsForest
//
import Foundation

/// 単語＋意味ごとの例文を保存する（Teacher編集用）
final class ExampleStore: ObservableObject {

    static let shared = ExampleStore()

    /// key = "pos|word|meaning" → [ExampleEntry]
    @Published private(set) var examples: [String: [ExampleEntry]] = [:]

    /// ✅ 単語ノート（meaningに依存しない）
    /// key = "pos|word" → note
    @Published private(set) var wordNotes: [String: String] = [:]

    private let key = "example_store_v2"
    private let notesKey = "word_notes_v1"

    private init() {
        load()
        loadNotes()
    }

    // MARK: - Normalize / Key

    private func normWord(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func normMeaning(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func makeKey(pos: PartOfSpeech, word: String, meaning: String) -> String {
        "\(pos.rawValue)|\(normWord(word))|\(normMeaning(meaning))"
    }

    private func makeWordKey(pos: PartOfSpeech, word: String) -> String {
        "\(pos.rawValue)|\(normWord(word))"
    }

    // MARK: - CRUD（意味ごと）

    /// 1 meaning = 1例文（上書き）
    /// ✅ noteは「単語ノート」に寄せる（meaning分裂させない）
    func saveExample(pos: PartOfSpeech,
                     word: String,
                     meaning: String,
                     en: String,
                     ja: String?,
                     note: String?) {

        let k = makeKey(pos: pos, word: word, meaning: meaning)

        // 例文はmeaningごとに保存（ExampleEntry.noteは使わない）
        examples[k] = [ExampleEntry(en: en, ja: ja, note: nil)]
        save()

        // noteは単語単位で保存
        saveWordNote(pos: pos, word: word, note: note)
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

    // MARK: - ✅ 単語ノート（wordNotes）

    func saveWordNote(pos: PartOfSpeech, word: String, note: String?) {
        let k = makeWordKey(pos: pos, word: word)
        let trimmed = (note ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            wordNotes.removeValue(forKey: k)
        } else {
            wordNotes[k] = trimmed
        }
        saveNotes()
    }

    /// 空なら "" を返す（UI側が楽）
    func wordNote(pos: PartOfSpeech, word: String) -> String {
        wordNotes[makeWordKey(pos: pos, word: word)] ?? ""
    }

    // MARK: - Save / Load（examples）

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

    // MARK: - Save / Load（wordNotes）

    private func saveNotes() {
        if let data = try? JSONEncoder().encode(wordNotes) {
            UserDefaults.standard.set(data, forKey: notesKey)
            // 表示更新したいなら同じ通知でOK
            NotificationCenter.default.post(name: .examplesDidChange, object: nil)
        }
    }

    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: notesKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            wordNotes = decoded
        }
    }
}

extension Notification.Name {
    static let examplesDidChange = Notification.Name("examplesDidChange")
}
