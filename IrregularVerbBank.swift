//
//  IrregularVerbBank.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/14.→2026/01/24宿題セット編集フォーム作成対応
//

import Foundation

enum IrregularVerbBank {
    /// base -> [base, past, past participle]
    static let forms: [String: [String]] = [
        "write": ["write", "wrote", "written"],
        "go":    ["go", "went", "gone"],
        "come":  ["come", "came", "come"],
        "know":  ["know", "knew", "known"],
        "run":   ["run", "ran", "run"],
        "ride":  ["ride", "rode", "ridden"],
        "read":  ["read", "read", "read"],
        "eat":   ["eat", "ate", "eaten"],
        "drink": ["drink", "drank", "drunk"],
        "sleep": ["sleep", "slept", "slept"],
        "sing":  ["sing", "sang", "sung"],
        "swim":  ["swim", "swam", "swum"],
        "draw":  ["draw", "drew", "drawn"],
        "build": ["build", "built", "built"],
        "think": ["think", "thought", "thought"],
        "buy":   ["buy", "bought", "bought"],
        "bring": ["bring", "brought", "brought"],
        "take":  ["take", "took", "taken"],
        "give":  ["give", "gave", "given"],
        "see":   ["see", "saw", "seen"],
        "teach": ["teach", "taught", "taught"],
        "catch": ["catch", "caught", "caught"],
        "leave": ["leave", "left", "left"],
        "meet":  ["meet", "met", "met"],
        "stand": ["stand", "stood", "stood"],
        "sit":   ["sit", "sat", "sat"],
        "pay":   ["pay", "paid", "paid"],
        "sell":  ["sell", "sold", "sold"],
        "put":   ["put", "put", "put"],
        "find":  ["find", "found", "found"],
        "make":  ["make", "made", "made"],
        "do":    ["do", "did", "done"],
        "cut":   ["cut", "cut", "cut"],
        
        
        
        // ここに追加
        // MARK: - Irregular verbs 追加分

        "arise":      ["arise", "arose", "arisen"],
        "awake":      ["awake", "awoke", "awoken"],
        "be":         ["be", "was / were", "been"],
        "bear":       ["bear", "bore", "borne / born"],
        "beat":       ["beat", "beat", "beaten"],
        "become":     ["become", "became", "become"],
        "begin":      ["begin", "began", "begun"],
        "bend":       ["bend", "bent", "bent"],
        "bet":        ["bet", "bet", "bet"],
        "bind":       ["bind", "bound", "bound"],
        "bite":       ["bite", "bit", "bitten"],
        "bleed":      ["bleed", "bled", "bled"],
        "blow":       ["blow", "blew", "blown"],
        "break":      ["break", "broke", "broken"],
        "breed":      ["breed", "bred", "bred"],
        "broadcast":  ["broadcast", "broadcast", "broadcast"],
        "burn":       ["burn", "burnt / burned", "burnt / burned"],
        "burst":      ["burst", "burst", "burst"],

        "choose":     ["choose", "chose", "chosen"],
        "cost":       ["cost", "cost", "cost"],
        "creep":      ["creep", "crept", "crept"],

        "deal":       ["deal", "dealt", "dealt"],
        "dig":        ["dig", "dug", "dug"],
        "dream":      ["dream", "dreamt / dreamed", "dreamt / dreamed"],
        "drive":      ["drive", "drove", "driven"],

        "fall":       ["fall", "fell", "fallen"],
        "feed":       ["feed", "fed", "fed"],
        "feel":       ["feel", "felt", "felt"],
        "fight":      ["fight", "fought", "fought"],
        "flee":       ["flee", "fled", "fled"],
        "fly":        ["fly", "flew", "flown"],
        "forbid":     ["forbid", "forbade", "forbidden"],
        "forecast":   ["forecast", "forecast", "forecast"],
        "forget":     ["forget", "forgot", "forgotten"],
        "forgive":    ["forgive", "forgave", "forgiven"],
        "freeze":     ["freeze", "froze", "frozen"],

        "get":        ["get", "got", "got / gotten"],
        "grind":      ["grind", "ground", "ground"],
        "grow":       ["grow", "grew", "grown"],

        "hang":       ["hang", "hung", "hung"],
        "have":       ["have", "had", "had"],
        "hear":       ["hear", "heard", "heard"],
        "hide":       ["hide", "hid", "hidden"],
        "hit":        ["hit", "hit", "hit"],
        "hold":       ["hold", "held", "held"],
        "hurt":       ["hurt", "hurt", "hurt"],

        "keep":       ["keep", "kept", "kept"],

        "lay":        ["lay", "laid", "laid"],
        "lead":       ["lead", "led", "led"],
        "lean":       ["lean", "leant / leaned", "leant / leaned"],
        "leap":       ["leap", "leapt / leaped", "leapt / leaped"],
        "learn":      ["learn", "learnt / learned", "learnt / learned"],
        "lend":       ["lend", "lent", "lent"],
        "let":        ["let", "let", "let"],
        "lie":        ["lie", "lay", "lain"],
        "light":      ["light", "lit / lighted", "lit / lighted"],
        "lose":       ["lose", "lost", "lost"],

        "mean":       ["mean", "meant", "meant"],
        "mistake":    ["mistake", "mistook", "mistaken"],

        "overcome":   ["overcome", "overcame", "overcome"],

        "prove":      ["prove", "proved", "proven / proved"],

        "quit":       ["quit", "quit", "quit"],

        "ring":       ["ring", "rang", "rung"],
        "rise":       ["rise", "rose", "risen"],

        "say":        ["say", "said", "said"],
        "seek":       ["seek", "sought", "sought"],
        "send":       ["send", "sent", "sent"],
        "set":        ["set", "set", "set"],
        "shake":      ["shake", "shook", "shaken"],
        "shine":      ["shine", "shone", "shone"],
        "shoot":      ["shoot", "shot", "shot"],
        "show":       ["show", "showed", "shown"],
        "shrink":     ["shrink", "shrank", "shrunk"],
        "shut":       ["shut", "shut", "shut"],
        "sink":       ["sink", "sank", "sunk"],
        "slide":      ["slide", "slid", "slid"],
        "smell":      ["smell", "smelt / smelled", "smelt / smelled"],
        "sow":        ["sow", "sowed", "sown / sowed"],
        "speak":      ["speak", "spoke", "spoken"],
        "speed":      ["speed", "sped / speeded", "sped / speeded"],
        "spell":      ["spell", "spelt / spelled", "spelt / spelled"],
        "spend":      ["spend", "spent", "spent"],
        "spill":      ["spill", "spilt / spilled", "spilt / spilled"],
        "spin":       ["spin", "spun", "spun"],
        "spit":       ["spit", "spat / spit", "spat / spit"],
        "split":      ["split", "split", "split"],
        "spread":     ["spread", "spread", "spread"],
        "spring":     ["spring", "sprang", "sprung"],
        "steal":      ["steal", "stole", "stolen"],
        "stick":      ["stick", "stuck", "stuck"],
        "sting":      ["sting", "stung", "stung"],
        "stink":      ["stink", "stank / stunk", "stunk"],
        "strike":     ["strike", "struck", "struck"],
        "swear":      ["swear", "swore", "sworn"],
        "sweep":      ["sweep", "swept", "swept"],
        "swing":      ["swing", "swung", "swung"],

        "tear":       ["tear", "tore", "torn"],
        "tell":       ["tell", "told", "told"],
        "throw":      ["throw", "threw", "thrown"],

        "undergo":    ["undergo", "underwent", "undergone"],
        "understand": ["understand", "understood", "understood"],
        "undertake":  ["undertake", "undertook", "undertaken"],
        "upset":      ["upset", "upset", "upset"],

        "wake":       ["wake", "woke", "woken"],
        "wear":       ["wear", "wore", "worn"],
        "weave":      ["weave", "wove", "woven"],
        "win":        ["win", "won", "won"],
        "wind":       ["wind", "wound", "wound"],
        "withdraw":   ["withdraw", "withdrew", "withdrawn"],
        "withstand":  ["withstand", "withstood", "withstood"],
        
    ]

    /// "write · wrote · written" みたいなのが来ても "write" にする
        static func base(from raw: String) -> String {
            raw.lowercased()
                .split(whereSeparator: { ch in
                    ch == " " || ch == "(" || ch == "·" || ch == "•" || ch == "・"
                })
                .first
                .map(String.init) ?? raw.lowercased()
        }

    static func forms(for base: String) -> [String]? {
        forms[base.lowercased()]
    }

    /// WordCard の word を渡すだけでOKな入口
    static func forms(from word: String) -> [String]? {
        forms(for: base(from: word))
    }
}
