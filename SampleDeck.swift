//
//  SampleDeck.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/30.
//

import Foundation

enum SampleDeck {
    static func filtered(by pos: PartOfSpeech) -> [WordCard] {
        if let all = loadCSV(), !all.isEmpty {
            return all.filter { $0.pos == pos }
        }
        return builtin(by: pos) // ← いまのハードコードにフォールバック
    }

    // ここに“いまの配列”をそのまま移植
    private static func builtin(by pos: PartOfSpeech) -> [WordCard] {
        switch pos {
        case .noun:
            return [
                WordCard(word: "apple",  meaning: "りんご", pos: .noun),
                WordCard(word: "river",  meaning: "川",    pos: .noun),
                WordCard(word: "forest", meaning: "森",    pos: .noun),
                WordCard(word: "music",  meaning: "音楽",  pos: .noun),
            ]
        case .verb:
            return [
                WordCard(word: "run",   meaning: "走る", pos: .verb),
                WordCard(word: "fly",   meaning: "飛ぶ", pos: .verb),
                WordCard(word: "write", meaning: "書く", pos: .verb),
                WordCard(word: "think", meaning: "考える", pos: .verb),
            ]
        case .adj:
            return [
                WordCard(word: "gentle", meaning: "優しい",   pos: .adj),
                WordCard(word: "quiet",  meaning: "静かな",   pos: .adj),
                WordCard(word: "bright", meaning: "明るい",   pos: .adj),
                WordCard(word: "mossy",  meaning: "苔むした", pos: .adj),
            ]
        case .adv:
            return [
                WordCard(word: "slowly",   meaning: "ゆっくり", pos: .adv),
                WordCard(word: "quickly",  meaning: "素早く",   pos: .adv),
                WordCard(word: "carefully",meaning: "注意深く", pos: .adv),
                WordCard(word: "often",    meaning: "しばしば", pos: .adv),
            ]
        case .others:
            return [
                WordCard(word: "the",  meaning: "定冠詞",           pos: .others),
                WordCard(word: "a",    meaning: "不定冠詞",         pos: .others),
                WordCard(word: "in",   meaning: "前置詞 〜の中で",   pos: .others),
                WordCard(word: "on",   meaning: "前置詞 〜の上に",   pos: .others),
                WordCard(word: "to",   meaning: "不定詞/前置詞 to",  pos: .others),
                WordCard(word: "and",  meaning: "接続詞 〜と",       pos: .others),
                WordCard(word: "but",  meaning: "接続詞 しかし",     pos: .others),
                WordCard(word: "can",  meaning: "助動詞 〜できる",   pos: .others)
            ]

        }
    }

    // ===== CSV読込 =====
    private static func loadCSV() -> [WordCard]? {
        guard let url = Bundle.main.url(forResource: "SampleDeck", withExtension: "csv"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { return nil }

        var rows = text.split(whereSeparator: \.isNewline).map(String.init)
        if let first = rows.first, first.lowercased().contains("word,") {
            rows.removeFirst() // ヘッダ行を除去
        }

        var result: [WordCard] = []
        for line in rows {
            let cols = parseCSVLine(line)
            guard cols.count >= 3,
                  let p = PartOfSpeech.parse(cols[2]) else { continue }
            let w = cols[0].trimmingCharacters(in: .whitespaces)
            let m = cols[1].trimmingCharacters(in: .whitespaces)
            result.append(.init(word: w, meaning: m, pos: p))
        }
        return result
    }

    // ダブルクオート対応の簡易CSVパーサ
    private static func parseCSVLine(_ s: String) -> [String] {
        var res:[String] = []
        var field = ""
        var inQuotes = false
        var i = s.startIndex
        while i < s.endIndex {
            let ch = s[i]
            if ch == "\"" {
                let next = s.index(after: i)
                if inQuotes && next < s.endIndex && s[next] == "\"" {
                    field.append("\""); i = s.index(after: next); continue // 連続""はエスケープ
                }
                inQuotes.toggle()
            } else if ch == "," && !inQuotes {
                res.append(field); field = ""
            } else {
                field.append(ch)
            }
            i = s.index(after: i)
        }
        res.append(field)
        return res
    }
}

extension PartOfSpeech {
    static func parse(_ s: String) -> PartOfSpeech? {
        switch s.lowercased() {
        case "noun","名詞","n": return .noun
        case "verb","動詞","v": return .verb
        case "adjective","形容詞","adj","a": return .adj
        case "adverb","副詞","adv","r": return .adv
        default: return nil
        }
    }
}
