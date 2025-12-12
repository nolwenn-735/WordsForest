//
//  WordsForest
//
//  Created by Nami .T on 2025/09/30.
//
//  SampleDeck.swift

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
                
                //week1
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
                //week2
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
                //week3
                WordCard(word: "kitchen", meaning: "台所", pos: .noun),
                WordCard(word: "pencil", meaning: "鉛筆", pos: .noun),
                WordCard(word: "street", meaning: "通り", pos: .noun),
                WordCard(word: "dog", meaning: "犬", pos: .noun),
                WordCard(word: "food", meaning: "食べ物", pos: .noun),
                WordCard(word: "phone", meaning: "電話", pos: .noun),
                WordCard(word: "bag", meaning: "かばん", pos: .noun),
                WordCard(word: "chair", meaning: "椅子", pos: .noun),
                WordCard(word: "table", meaning: "テーブル", pos: .noun),
                WordCard(word: "cup", meaning: "コップ", pos: .noun),
                WordCard(word: "bed", meaning: "ベッド", pos: .noun),
                WordCard(word: "shirt", meaning: "シャツ", pos: .noun),
                //week4
                WordCard(word: "shoes", meaning: "靴", pos: .noun),
                WordCard(word: "hat", meaning: "帽子", pos: .noun),
                WordCard(word: "water", meaning: "水", pos: .noun),
                WordCard(word: "juice", meaning: "ジュース", pos: .noun),
                WordCard(word: "butter", meaning: "バター", pos: .noun),
                WordCard(word: "bread", meaning: "パン", pos: .noun),
                WordCard(word: "milk", meaning: "牛乳", pos: .noun),
                WordCard(word: "egg", meaning: "卵", pos: .noun),
                WordCard(word: "car", meaning: "車", pos: .noun),
                WordCard(word: "train", meaning: "電車", pos: .noun),
                WordCard(word: "bus", meaning: "バス", pos: .noun),
                WordCard(word: "key", meaning: "鍵", pos: .noun),
                //week5
                WordCard(word: "door", meaning: "ドア", pos: .noun),
                WordCard(word: "house", meaning: "家", pos: .noun),
                WordCard(word: "mirror", meaning: "鏡", pos: .noun),
                WordCard(word: "clock", meaning: "時計", pos: .noun),
                WordCard(word: "watch", meaning: "腕時計", pos: .noun),
                WordCard(word: "soap", meaning: "石けん", pos: .noun),
                WordCard(word: "towel", meaning: "タオル", pos: .noun),
                WordCard(word: "toothbrush", meaning: "歯ブラシ", pos: .noun),
                WordCard(word: "windowpane", meaning: "窓ガラス", pos: .noun),
                WordCard(word: "notebook", meaning: "ノート", pos: .noun),
                WordCard(word: "letter", meaning: "手紙", pos: .noun),
                WordCard(word: "photo", meaning: "写真", pos: .noun),
            ]
        case .verb:
            return [
                //week1
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
                //week2
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
                //week3
                WordCard(word: "sell", meaning: "売る", pos: .verb),
                 WordCard(word: "use", meaning: "使う", pos: .verb),
                 WordCard(word: "carry", meaning: "運ぶ", pos: .verb),
                 WordCard(word: "drive", meaning: "運転する", pos: .verb),
                 WordCard(word: "ride", meaning: "乗る", pos: .verb),
                 WordCard(word: "wash", meaning: "洗う", pos: .verb),
                 WordCard(word: "clean", meaning: "掃除する", pos: .verb),
                 WordCard(word: "talk", meaning: "話す", pos: .verb),
                 WordCard(word: "call", meaning: "電話する", pos: .verb),
                 WordCard(word: "meet", meaning: "会う", pos: .verb),
                 WordCard(word: "study", meaning: "勉強する", pos: .verb),
                 WordCard(word: "play", meaning: "遊ぶ", pos: .verb),
                //week4
                 WordCard(word: "paint", meaning: "塗る", pos: .verb),
                 WordCard(word: "dance", meaning: "踊る", pos: .verb),
                 WordCard(word: "drink", meaning: "飲む", pos: .verb),
                 WordCard(word: "look", meaning: "見る", pos: .verb),
                 WordCard(word: "see", meaning: "見える", pos: .verb),
                 WordCard(word: "throw", meaning: "投げる", pos: .verb),
                 WordCard(word: "catch", meaning: "捕まえる", pos: .verb),
                 WordCard(word: "pick", meaning: "拾う", pos: .verb),
                 WordCard(word: "put", meaning: "置く", pos: .verb),
                 WordCard(word: "bring", meaning: "持ってくる", pos: .verb),
                 WordCard(word: "take", meaning: "持っていく", pos: .verb),
                 WordCard(word: "show", meaning: "見せる", pos: .verb),
                //week5
                 WordCard(word: "teach", meaning: "教える", pos: .verb),
                 WordCard(word: "love", meaning: "愛する", pos: .verb),
                 WordCard(word: "like", meaning: "好き", pos: .verb),
                 WordCard(word: "hate", meaning: "嫌う", pos: .verb),
                 WordCard(word: "jump", meaning: "跳ぶ", pos: .verb),
                 WordCard(word: "sit", meaning: "座る", pos: .verb),
                 WordCard(word: "stand", meaning: "立つ", pos: .verb),
                 WordCard(word: "hug", meaning: "抱きしめる", pos: .verb),
                 WordCard(word: "want", meaning: "欲しい", pos: .verb),
                 WordCard(word: "bake", meaning: "焼く", pos: .verb),
                WordCard(word: "play", meaning: "遊ぶ", pos: .verb),
                WordCard(word: "pay", meaning: "支払う", pos: .verb),                
            ]
        case .adj:
            return [
                //week1
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
                //week2
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
                // week3
                WordCard(word: "tall", meaning: "背の高い", pos: .adj),
                WordCard(word: "short", meaning: "背の低い", pos: .adj),
                WordCard(word: "warm", meaning: "暖かい", pos: .adj),
                WordCard(word: "cool", meaning: "涼しい", pos: .adj),
                WordCard(word: "dark", meaning: "暗い", pos: .adj),
                WordCard(word: "light", meaning: "明るい・軽い", pos: .adj),
                WordCard(word: "sweet", meaning: "甘い", pos: .adj),
                WordCard(word: "sour", meaning: "酸っぱい", pos: .adj),
                WordCard(word: "bitter", meaning: "苦い", pos: .adj),
                WordCard(word: "salty", meaning: "しょっぱい", pos: .adj),
                WordCard(word: "tired", meaning: "疲れた", pos: .adj),
                WordCard(word: "sleepy", meaning: "眠い", pos: .adj),
                //week4
                WordCard(word: "hungry", meaning: "お腹が空いた", pos: .adj),
                WordCard(word: "thirsty", meaning: "喉が渇いた", pos: .adj),
                WordCard(word: "busy", meaning: "忙しい", pos: .adj),
                WordCard(word: "free", meaning: "暇な", pos: .adj),
                WordCard(word: "fun", meaning: "楽しい", pos: .adj),
                WordCard(word: "boring", meaning: "退屈な", pos: .adj),
                WordCard(word: "noisy", meaning: "うるさい", pos: .adj),
                WordCard(word: "beautiful", meaning: "美しい", pos: .adj),
                WordCard(word: "ugly", meaning: "醜い", pos: .adj),
                WordCard(word: "thin", meaning: "細い", pos: .adj),
                WordCard(word: "fat", meaning: "太った", pos: .adj),
                WordCard(word: "young", meaning: "若い", pos: .adj),
                //week5
                WordCard(word: "angry", meaning: "怒っている", pos: .adj),
                WordCard(word: "easy", meaning: "簡単な", pos: .adj),
                WordCard(word: "difficult", meaning: "難しい", pos: .adj),
                WordCard(word: "rich", meaning: "裕福な", pos: .adj),
                WordCard(word: "poor", meaning: "貧しい", pos: .adj),
                WordCard(word: "important", meaning: "大事な", pos: .adj),
                WordCard(word: "interesting", meaning: "面白い", pos: .adj),
                WordCard(word: "warm", meaning: "あたたかい", pos: .adj),
                WordCard(word: "dark", meaning: "暗い", pos: .adj),
                WordCard(word: "friendly", meaning: "親しみやすい", pos: .adj),
                WordCard(word: "busy", meaning: "忙しい", pos: .adj),
                WordCard(word: "safe", meaning: "安全な", pos: .adj),
            ]
        case .adv:
            return [
                //week1
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
                //week2
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
                //week3
                WordCard(word: "slowly",    meaning: "ゆっくり",       pos: .adv),
                WordCard(word: "quickly",   meaning: "素早く",         pos: .adv),
                WordCard(word: "carefully", meaning: "注意深く",       pos: .adv),
                WordCard(word: "often",     meaning: "しばしば",       pos: .adv),
                WordCard(word: "happily",   meaning: "幸せそうに",     pos: .adv),
                WordCard(word: "sadly",     meaning: "悲しそうに",     pos: .adv),
                WordCard(word: "neatly",    meaning: "きちんと",       pos: .adv),
                WordCard(word: "loudly",    meaning: "大声で",         pos: .adv),
                WordCard(word: "silently",  meaning: "静かに",         pos: .adv),
                WordCard(word: "eagerly",   meaning: "熱心に",         pos: .adv),
                WordCard(word: "gently",    meaning: "優しく",         pos: .adv),
                WordCard(word: "bravely",   meaning: "勇敢に",         pos: .adv),
                //week4
                WordCard(word: "brightly",  meaning: "明るく",         pos: .adv),
                WordCard(word: "calmly",    meaning: "落ち着いて",     pos: .adv),
                WordCard(word: "early",     meaning: "早く",           pos: .adv),
                WordCard(word: "late",      meaning: "遅く",           pos: .adv),
                WordCard(word: "rarely",    meaning: "めったに〜ない", pos: .adv),
                WordCard(word: "daily",     meaning: "毎日",           pos: .adv),
                WordCard(word: "never",     meaning: "決して〜ない",   pos: .adv),
                WordCard(word: "together",  meaning: "一緒に",         pos: .adv),
                WordCard(word: "apart",     meaning: "離れて",         pos: .adv),
                WordCard(word: "somewhere", meaning: "どこかで",       pos: .adv),
                WordCard(word: "outside",   meaning: "外で",           pos: .adv),
                WordCard(word: "inside",    meaning: "中で",           pos: .adv),
                //week5
                WordCard(word: "easily",    meaning: "簡単に",         pos: .adv),
                WordCard(word: "really",    meaning: "本当に",         pos: .adv),
                WordCard(word: "maybe",     meaning: "たぶん",         pos: .adv),
                WordCard(word: "again",     meaning: "もう一度",       pos: .adv),
                WordCard(word: "safely",    meaning: "安全に",         pos: .adv),
                WordCard(word: "kindly",    meaning: "親切に",         pos: .adv),
                WordCard(word: "gracefully",meaning: "優雅に",         pos: .adv),
                WordCard(word: "angrily",   meaning: "怒って",         pos: .adv),
                WordCard(word: "fortunately",meaning: "幸運にも",     pos: .adv),
                WordCard(word: "unfortunately", meaning: "不運にも",   pos: .adv),
                WordCard(word: "exactly",   meaning: "正確に",         pos: .adv),
                WordCard(word: "anywhere",  meaning: "どこでも",       pos: .adv),
            ]
        case .others:
            return [
                WordCard(word: "the",  meaning: "定冠詞　その〜、例の", pos: .others),
                WordCard(word: "a",    meaning: "不定冠詞　ある〜、ひとつの", pos: .others),
                WordCard(word: "in",   meaning: "前置詞　〜の中で",   pos: .others),
                WordCard(word: "on",   meaning: "前置詞　〜の上に",   pos: .others),
                WordCard(word: "to",   meaning: "前置詞/不定詞　到達点を示す/〜すること",  pos: .others),
                WordCard(word: "and",  meaning: "接続詞　〜と、そして",   pos: .others),
                WordCard(word: "but",  meaning: "接続詞　しかし",   pos: .others),
                WordCard(word: "can",  meaning: "助動詞　〜できる",   pos: .others),
                WordCard(word: "at",   meaning: "前置詞　〜で",   pos: .others),
                WordCard(word: "is", meaning: "be動詞　〜である", pos: .others),
                WordCard(word: "are", meaning: "be動詞　〜である", pos: .others),
                WordCard(word: "was", meaning: "be動詞　amとisの過去形", pos: .others),
                WordCard(word: "were", meaning: "be動詞　areの過去形", pos: .others),
                WordCard(word: "do", meaning: "助動詞/動詞　する", pos: .others),
                WordCard(word: "does", meaning: "助動詞/動詞　〜する(3単現)", pos: .others),
                WordCard(word: "did", meaning: "助動詞/動詞　〜した", pos: .others),
                WordCard(word: "will", meaning: "助動詞　〜するだろう", pos: .others),
                WordCard(word: "if", meaning: "接続詞　もし〜ならば", pos: .others),
                WordCard(word: "because", meaning: "接続詞　なぜなら/〜なので", pos: .others),
                WordCard(word: "with", meaning: "前置詞　〜と一緒に", pos: .others),
                WordCard(word: "without", meaning: "前置詞　〜なしで", pos: .others),
                WordCard(word: "under", meaning: "前置詞　〜の下に", pos: .others),
                WordCard(word: "over", meaning: "前置詞　〜の上を", pos: .others),
                WordCard(word: "before", meaning: "前置詞　〜の前に", pos: .others),
                WordCard(word: "after", meaning: "前置詞　〜の後で", pos: .others),
                WordCard(word: "as", meaning: "前置詞　〜として", pos: .others),
                WordCard(word: "while", meaning: "前置詞　〜の間に", pos: .others),
                WordCard(word: "oh", meaning: "間投詞　おおっ", pos: .others),
                WordCard(word: "hey", meaning: "間投詞　ねえ", pos: .others),
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
