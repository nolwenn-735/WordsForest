//
//  StudentMemoCardFormatter.swift
//  WordsForest
//
//  Created by Nami .T on 2026/09/20.
//

import Foundation

enum StudentMemoCardFormatter {

    static func makeText(
        pos: PartOfSpeech,
        word: String,
        meanings: [String]
    ) -> String {

        var parts: [String] = []

        // 単語見出し
        parts.append("【\(word)】")

        // 意味
        let cleanMeanings = meanings
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !cleanMeanings.isEmpty {
            var meaningLines: [String] = ["【意味】"]

            for meaning in cleanMeanings {
                meaningLines.append("・\(meaning)")
            }

            parts.append(meaningLines.joined(separator: "\n"))
        }

        // 例文
        var exampleLines: [String] = []

        for meaning in cleanMeanings {

            guard let example = ExampleStore.shared.firstExample(
                pos: pos,
                word: word,
                meaning: meaning
            ) else {
                continue
            }

            let en = example.en
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let ja = example.ja?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !en.isEmpty else {
                continue
            }

            if exampleLines.isEmpty {
                exampleLines.append("【例文】")
            }

            if cleanMeanings.count > 1 {
                exampleLines.append("〈\(meaning)〉")
            }

            exampleLines.append(en)

            if let ja, !ja.isEmpty {
                exampleLines.append(ja)
            }

            exampleLines.append("")
        }

        if !exampleLines.isEmpty {
            while exampleLines.last == "" {
                exampleLines.removeLast()
            }

            parts.append(exampleLines.joined(separator: "\n"))
        }

        // Word Note
        let note = ExampleStore.shared.wordNote(
            pos: pos,
            word: word
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)

        if !note.isEmpty {
            parts.append("""
            【Note】
            \(note)
            """)
        }

        return parts.joined(separator: "\n\n")
    }
}
