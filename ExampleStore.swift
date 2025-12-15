//
//  File.swift
//  WordsForest
//
import Foundation
import SwiftUI

// 例文が更新されたことを知らせる（必要なら使う）
extension Notification.Name {
    static let examplesDidChange = Notification.Name("examplesDidChange")
}

final class ExampleStore: ObservableObject {
    static let shared = ExampleStore()

    // ★ “examples” という名前にすると「関数 examples(...)」と衝突しがちなので避ける
    @Published private(set) var table: [String: [ExampleEntry]] = [:]

    private let key = "examples_v2"
    private init() { load() }

    // MARK: - Key

    private func makeKey(posRaw: String, word: String) -> String {
        let p = posRaw.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
        let w = word.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
        return "\(p)__\(w)"
    }

    private func makeKey(pos: PartOfSpeech, word: String) -> String {
        makeKey(posRaw: pos.rawValue, word: word)
    }

    // MARK: - Public API（pos付き：これが正）

    func examples(pos: PartOfSpeech, for word: String) -> [ExampleEntry] {
        table[makeKey(pos: pos, word: word)] ?? []
    }

    func firstExample(pos: PartOfSpeech, for word: String) -> ExampleEntry? {
        examples(pos: pos, for: word).first
    }

    func saveExample(pos: PartOfSpeech, for word: String, en: String, ja: String?, note: String?) {
        let k = makeKey(pos: pos, word: word)
        let entry = ExampleEntry(en: en, ja: ja, note: note)
        table[k] = [entry]
        save()
        NotificationCenter.default.post(name: .examplesDidChange, object: nil)
    }

    func removeExample(pos: PartOfSpeech, for word: String) {
        let k = makeKey(pos: pos, word: word)
        table[k] = []
        save()
        NotificationCenter.default.post(name: .examplesDidChange, object: nil)
    }

    // MARK: - 互換ラッパー（pos不明な古い呼び出しを生かす）

    // pos不明の旧データ置き場（固定）
    private let legacyPosRaw = "__word__"

    func examples(for word: String) -> [ExampleEntry] {
        table[makeKey(posRaw: legacyPosRaw, word: word)] ?? []
    }

    func firstExample(for word: String) -> ExampleEntry? {
        examples(for: word).first
    }

    func saveExample(for word: String, en: String, ja: String?, note: String?) {
        let k = makeKey(posRaw: legacyPosRaw, word: word)
        let entry = ExampleEntry(en: en, ja: ja, note: note)
        table[k] = [entry]
        save()
        NotificationCenter.default.post(name: .examplesDidChange, object: nil)
    }

    func removeExample(for word: String) {
        let k = makeKey(posRaw: legacyPosRaw, word: word)
        table[k] = []
        save()
        NotificationCenter.default.post(name: .examplesDidChange, object: nil)
    }

    // MARK: - Save / Load

    private func save() {
        if let data = try? JSONEncoder().encode(table) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: [ExampleEntry]].self, from: data)
        else { return }
        table = decoded
    }
}
