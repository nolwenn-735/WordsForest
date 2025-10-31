//
//  ColumnData.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/30.
//

import Foundation

struct ColumnArticle: Identifiable, Hashable {
    let id: Int
    let title: String
    let body: String
    let tags: [String]
}

enum ColumnData {
    static let all: [ColumnArticle] = [
        ColumnArticle(
            id: 25,
            title: "on の感覚",
            body: """
        英語の前置詞 on は、ただ「〜の上に」という意味だけではありません。
        基本にあるのは「接している」「支えられている」という感覚です。

        たとえば、
        The cup is on the table.
        は「カップがテーブルの上にある」ですが、
        「触れている・乗っている」という物理的な接触のイメージが中心にあります。

        しかし、
        I'm on the phone.
        のように使うと、「通信という“回線”に接している」という抽象的なつながりに変わります。
        on は物理的にも、概念的にも「何かに接して関わっている」状態を表す言葉なんです。

        ですから、
        on は “in” や “at” との違いを、
        「中にいる」でも「点で位置している」でもなく、
        「面に触れて支えられている」と覚えると、とても自然に感じられます。
        """,
            tags: ["前置詞", "感覚で覚える"]
        ),
        ColumnArticle(
            id: 24,
            title: "いちばん心に残る前置詞の話",
            body: "ここに本文を書きます…",
            tags: ["前置詞", "感覚で覚える"]
        ),
        ColumnArticle(
            id: 23,
            title: "th の発音、ふわっとでいい",
            body: "ここに本文を書きます…",
            tags: ["発音"]
        ),
        ColumnArticle(
            id: 1,
            title: "5文型（ざっくり速習）",
            body: """
英語の基本的な文の型は S, V, O, C で考えます…
""",
            tags: ["文型", "基礎"]
        )
    ]
}
