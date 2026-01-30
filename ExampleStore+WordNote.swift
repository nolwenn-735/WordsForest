//
//  ExampleStore+WordNote.swift
//  WordsForest
//
//  Created by Nami .T on 2026/01/31.
//

import Foundation

extension ExampleStore {

    // 単語ノート（全体）を保存するキー
    private func wordNoteKey(pos: PartOfSpeech, word: String) -> String {
        let w = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return "example_store.word_note.v1.\(pos.rawValue).\(w)"
    }

    /// 単語ノート（全体）を読む
    func wordNote(pos: PartOfSpeech, word: String) -> String? {
        let key = wordNoteKey(pos: pos, word: word)
        let s = UserDefaults.standard.string(forKey: key)
        let t = (s ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    /// 単語ノート（全体）を保存（nil/空なら削除）
    func saveWordNote(pos: PartOfSpeech, word: String, note: String?) {
        let key = wordNoteKey(pos: pos, word: word)
        let t = (note ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if t.isEmpty {
            UserDefaults.standard.removeObject(forKey: key)
        } else {
            UserDefaults.standard.set(t, forKey: key)
        }
    }
}
