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
                WordCard(word: "mountain", meaning: "山", pos: .noun),
                WordCard(word: "ocean", meaning: "海", pos: .noun),
                WordCard(word: "flower", meaning: "花", pos: .noun),
                WordCard(word: "friend", meaning: "友達", pos: .noun),
                WordCard(word: "sun", meaning: "太陽", pos: .noun),
                WordCard(word: "moon", meaning: "月", pos: .noun),
                WordCard(word: "tree", meaning: "木", pos: .noun),
                WordCard(word: "cloud", meaning: "雲", pos: .noun),
                WordCard(word: "book", meaning: "本", pos: .noun),
                WordCard(word: "school", meaning: "学校", pos: .noun),
                WordCard(word: "bird", meaning: "鳥", pos: .noun),
                WordCard(word: "snow", meaning: "雪", pos: .noun),
                WordCard(word: "star", meaning: "星", pos: .noun),
                WordCard(word: "animal", meaning: "動物", pos: .noun),
                WordCard(word: "city", meaning: "都市", pos: .noun),
                WordCard(word: "flowerpot", meaning: "植木鉢", pos: .noun),
                WordCard(word: "dream", meaning: "夢", pos: .noun),
                WordCard(word: "story", meaning: "物語", pos: .noun),
                WordCard(word: "window", meaning: "窓", pos: .noun),
                WordCard(word: "garden", meaning: "庭", pos: .noun),
            ]
        case .verb:
            return [
                WordCard(word: "run",   meaning: "走る", pos: .verb),
                WordCard(word: "fly",   meaning: "飛ぶ", pos: .verb),
                WordCard(word: "write", meaning: "書く", pos: .verb),
                WordCard(word: "think", meaning: "考える", pos: .verb),
                WordCard(word: "read", meaning: "読む", pos: .verb),
                WordCard(word: "eat", meaning: "食べる", pos: .verb),
                WordCard(word: "sleep", meaning: "眠る", pos: .verb),
                WordCard(word: "sing", meaning: "歌う", pos: .verb),
                WordCard(word: "listen", meaning: "聞く", pos: .verb),
                WordCard(word: "watch", meaning: "見る", pos: .verb),
                WordCard(word: "draw", meaning: "描く", pos: .verb),
                WordCard(word: "build", meaning: "作る", pos: .verb),
                WordCard(word: "swim", meaning: "泳ぐ", pos: .verb),
                WordCard(word: "walk", meaning: "歩く", pos: .verb),
                WordCard(word: "smile", meaning: "微笑む", pos: .verb),
                WordCard(word: "laugh", meaning: "笑う", pos: .verb),
                WordCard(word: "open", meaning: "開ける", pos: .verb),
                WordCard(word: "close", meaning: "閉じる", pos: .verb),
                WordCard(word: "help", meaning: "助ける", pos: .verb),
                WordCard(word: "cook", meaning: "料理する", pos: .verb),
                WordCard(word: "climb", meaning: "登る", pos: .verb),
                WordCard(word: "wait", meaning: "待つ", pos: .verb),
                WordCard(word: "hope", meaning: "望む", pos: .verb),
                WordCard(word: "learn", meaning: "学ぶ", pos: .verb),
            ]
        case .adj:
            return [
                WordCard(word: "gentle", meaning: "優しい",   pos: .adj),
                WordCard(word: "quiet",  meaning: "静かな",   pos: .adj),
                WordCard(word: "bright", meaning: "明るい",   pos: .adj),
                WordCard(word: "mossy",  meaning: "苔むした", pos: .adj),
                WordCard(word: "happy", meaning: "幸せな", pos: .adj),
                WordCard(word: "sad", meaning: "悲しい", pos: .adj),
                WordCard(word: "cold", meaning: "寒い", pos: .adj),
                WordCard(word: "hot", meaning: "暑い", pos: .adj),
                WordCard(word: "small", meaning: "小さい", pos: .adj),
                WordCard(word: "large", meaning: "大きい", pos: .adj),
                WordCard(word: "fast", meaning: "速い", pos: .adj),
                WordCard(word: "slow", meaning: "遅い", pos: .adj),
                WordCard(word: "old", meaning: "古い", pos: .adj),
                WordCard(word: "new", meaning: "新しい", pos: .adj),
                WordCard(word: "kind", meaning: "親切な", pos: .adj),
                WordCard(word: "funny", meaning: "おかしな", pos: .adj),
                WordCard(word: "scary", meaning: "怖い", pos: .adj),
                WordCard(word: "blue", meaning: "青い", pos: .adj),
                WordCard(word: "green", meaning: "緑の", pos: .adj),
                WordCard(word: "clean", meaning: "きれいな", pos: .adj),
                WordCard(word: "dirty", meaning: "汚れた", pos: .adj),
                WordCard(word: "sharp", meaning: "鋭い", pos: .adj),
                WordCard(word: "soft", meaning: "柔らかい", pos: .adj),
                WordCard(word: "strong", meaning: "強い", pos: .adj),
            ]
        case .adv:
            return [
                WordCard(word: "slowly",   meaning: "ゆっくり", pos: .adv),
                WordCard(word: "quickly",  meaning: "素早く",   pos: .adv),
                WordCard(word: "carefully",meaning: "注意深く", pos: .adv),
                WordCard(word: "often",    meaning: "しばしば", pos: .adv),
                WordCard(word: "happily", meaning: "幸せそうに", pos: .adv),
                WordCard(word: "sadly", meaning: "悲しそうに", pos: .adv),
                WordCard(word: "neatly", meaning: "きちんと", pos: .adv),
                WordCard(word: "loudly", meaning: "大声で", pos: .adv),
                WordCard(word: "silently", meaning: "静かに", pos: .adv),
                WordCard(word: "eagerly", meaning: "熱心に", pos: .adv),
                WordCard(word: "gently", meaning: "優しく", pos: .adv),
                WordCard(word: "bravely", meaning: "勇敢に", pos: .adv),
                WordCard(word: "brightly", meaning: "明るく", pos: .adv),
                WordCard(word: "calmly", meaning: "落ち着いて", pos: .adv),
                WordCard(word: "early", meaning: "早く", pos: .adv),
                WordCard(word: "late", meaning: "遅く", pos: .adv),
                WordCard(word: "rarely", meaning: "めったに〜ない", pos: .adv),
                WordCard(word: "daily", meaning: "毎日", pos: .adv),
                WordCard(word: "never", meaning: "決して〜ない", pos: .adv),
                WordCard(word: "together", meaning: "一緒に", pos: .adv),
                WordCard(word: "apart", meaning: "離れて", pos: .adv),
                WordCard(word: "somewhere", meaning: "どこかで", pos: .adv),
                WordCard(word: "outside", meaning: "外で", pos: .adv),
                WordCard(word: "inside", meaning: "中で", pos: .adv),
            ]
        case .others:
            return [
                WordCard(word: "the",  meaning: "定冠詞　その〜、例の", pos: .others),
                WordCard(word: "a",    meaning: "不定冠詞 ある〜、ひとつの", pos: .others),
                WordCard(word: "in",   meaning: "前置詞 〜の中で",   pos: .others),
                WordCard(word: "on",   meaning: "前置詞 〜の上に",   pos: .others),
                WordCard(word: "to",   meaning: "前置詞/不定詞 to",  pos: .others),
                WordCard(word: "and",  meaning: "接続詞 〜と、そして",       pos: .others),
                WordCard(word: "but",  meaning: "接続詞 しかし",     pos: .others),
                WordCard(word: "can",  meaning: "助動詞 〜できる",   pos: .others),
                WordCard(word: "at",   meaning: "〜で",        pos: .others),
                WordCard(word: "is", meaning: "be動詞（〜である）", pos: .others),
                WordCard(word: "are", meaning: "be動詞（〜である）", pos: .others),
                WordCard(word: "was", meaning: "be動詞（過去形）", pos: .others),
                WordCard(word: "were", meaning: "be動詞（過去形）", pos: .others),
                WordCard(word: "do", meaning: "助動詞/動詞する", pos: .others),
                WordCard(word: "does", meaning: "助動詞/〜する", pos: .others),
                WordCard(word: "will", meaning: "助動詞 〜するだろう", pos: .others),
                WordCard(word: "if", meaning: "接続詞 もし〜ならば", pos: .others),
                WordCard(word: "because", meaning: "〜なので", pos: .others),
                WordCard(word: "with", meaning: "〜と一緒に", pos: .others),
                WordCard(word: "without", meaning: "〜なしで", pos: .others),
                WordCard(word: "under", meaning: "〜の下に", pos: .others),
                WordCard(word: "over", meaning: "〜の上を", pos: .others),
                WordCard(word: "before", meaning: "〜の前に", pos: .others),
                WordCard(word: "after", meaning: "〜の後で", pos: .others),
                WordCard(word: "as", meaning: "〜として", pos: .others),
                WordCard(word: "while", meaning: "〜の間に", pos: .others),
                WordCard(word: "butter", meaning: "（名詞）バター", pos: .others),
                WordCard(word: "oh", meaning: "間投詞 おおっ", pos: .others),
                WordCard(word: "hey", meaning: "間投詞 ねえ", pos: .others),
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
        case "others","other","misc","その他","他":  return .others   // ← 追加
        default: return nil
        }
    }
}
