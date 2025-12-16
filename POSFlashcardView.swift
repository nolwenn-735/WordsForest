//
//  POSFlashcardView.swift
//  WordsForest
//
// POSFlashcardView.swift
// 11/27版 Wordcardpage.swift の UI デザインを共通ビューに移植した版 (12/17 .json)

import SwiftUI
import AVFoundation

/// 単語カード一覧（検索結果・My Collection・覚えたBOX・宿題セットで使用）
struct POSFlashcardView: View {

    // どの画面か（タイトル）
    let title: String

    // 表示するカード一覧
    let cards: [WordCard]

    // テーマ色・背景色・マスコット
    let accent: Color
    let background: Color
    let animalName: String

    // 行ごとに品詞色を使うどうか（My Collection / 覚えたBOX など）
    let perRowAccent: Bool

    // 宿題モードなどで、✅したものは行を隠したい画面で true
    let hideLearned: Bool

    // すでにあればそのまま
    @ObservedObject private var store = HomeworkStore.shared
    /// ページ単位の英⇄日トグル
    @State private var reversed: Bool

    /// 音声関連
    @State private var speechFast = false      // ゆっくり
    @State private var speakBoth  = true       // 英＋日

    /// 展開中のカード index（nil なら全て表面）
    @State private var expandedIndex: Int? = nil

    /// 例文編集シート用
    @State private var editingCard: WordCard? = nil

    /// 親側に渡すコールバック
    var onEdit: (WordCard) -> Void
    var onDataChanged: () -> Void

    /// レイアウト定数（11/27版と同じ思想）
    private let rowsPerScreen: CGFloat = 4

    // TTS
    private let synthesizer = AVSpeechSynthesizer()

    // MARK: - init

    init(
        title: String,
        cards: [WordCard],
        accent: Color,
        background: Color,
        animalName: String,
        reversed: Bool = false,
        onEdit: @escaping (WordCard) -> Void = { _ in },
        onDataChanged: @escaping () -> Void = {},
        perRowAccent: Bool = false,
        hideLearned: Bool = false
    ) {
        self.title = title
        self.cards = cards
        self.accent = accent
        self.background = background
        self.animalName = animalName
        self.onEdit = onEdit
        self.onDataChanged = onDataChanged
        self.perRowAccent = perRowAccent
        self.hideLearned = hideLearned
        _reversed = State(initialValue: reversed)
        
    }

    // MARK: - body

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            GeometryReader { outer in
                let rowH = max(88, (outer.size.height - 140) / rowsPerScreen)

                ScrollView {
                    VStack(spacing: 16) {
                        rows(rowHeight: rowH)
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 140)   // 右下マスコット分
                }

                // 右下マスコット（固定）
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(animalName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                            .allowsHitTesting(false)
                            .padding(.trailing, 12)
                            .padding(.bottom, 8)
                            .offset(x: -32)   // 少し左へ寄せる
                    }
                }
            }
        }
        // ZStack の外
        .scrollContentBackground(.hidden)
        .background(background)
        .toolbarBackground(background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)

        // 🟡 中央タイトル＋英日トグル（11/27版と同じ見た目）
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)

                    Button {
                        reversed.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(accent)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black.opacity(0.45), lineWidth: 1.0)
                                )
                            Text("英日")
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                        .fixedSize()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("英語と日本語の表示を切り替え")
                }
                .fixedSize(horizontal: true, vertical: false)
            }
        }

        // 例文編集シート（CardRow の「例文」ペンから開く）
        .sheet(item: $editingCard) { card in
            ExampleEditorView(pos: card.pos, word: card.word)
        }
    }

    // MARK: - 行の並び

        @ViewBuilder
        private func rows(rowHeight: CGFloat) -> some View {
            let store = HomeworkStore.shared

            // ① 表示対象を1行で決める（if 文にしない）
            let visibleCards: [WordCard] = hideLearned
                ? cards.filter { !store.isLearned($0) }
                : cards

            // ② enumerate して index を作る
            let enumerated = Array(visibleCards.enumerated())

            ForEach(enumerated, id: \.offset) { pair in
                let i = pair.offset
                let c = pair.element
                row(for: c, index: i, rowHeight: rowHeight)
            }
        }

    // MARK: - 1 行
    @ViewBuilder
    private func row(for c: WordCard, index i: Int, rowHeight: CGFloat) -> some View {

        // 例文（ExampleStore は [ExampleEntry] を返す）
        let ex = ExampleStore.shared.firstExample(pos: c.pos, word: c.word)
        let examples: [ExampleEntry] = ex.map { [$0] } ?? []
        let note = ex?.note ?? ""

        // 不規則動詞なら 3 形を表示＆読み上げ対象に
        let isVerb = (c.pos == .verb)
        let irregularForms: [String] = isVerb ? (IrregularVerbBank.forms(for: c.word) ?? []) : []

        // 表示用：英面のときだけ3形を表示
        let displayWord = (isVerb && !irregularForms.isEmpty)
            ? irregularForms.joined(separator: " · ")
            : c.word

        // 読み上げ用：3形あれば全部読む
        let speakForms = (isVerb && !irregularForms.isEmpty) ? irregularForms : [c.word]

        // meanings は [String] なので、表の文字は先頭だけ大きく表示
        let meanings = c.meanings

        // 学習状態
        let isChecked = HomeworkStore.shared.isLearned(c)
        let isFav     = HomeworkStore.shared.isFavorite(c)

        // 行カラー
        let rowAccent = perRowAccent ? c.pos.accent : accent

        POSCardRow(
            pos: c.pos,
            word: displayWord,
            meanings: meanings,
            examples: examples,
            note: note,
            irregularForms: irregularForms,
            reversed: reversed,
            isChecked: isChecked,
            isFav: isFav,
            expanded: expandedIndex == i,
            rowHeight: rowHeight,
            checkTapped: {
                HomeworkStore.shared.toggleLearned(c)
                onDataChanged()
            },
            heartTapped: {
                HomeworkStore.shared.toggleFavorite(c)
                onDataChanged()
            },
            centerTapped: {
                withAnimation(.spring(response: 0.25)) {
                    expandedIndex = (expandedIndex == i ? nil : i)
                }
            },
            speakWordTapped: {
                speakForms.forEach { speakWord($0) }
            },
            speakExampleTapped: {
                // 裏面の「例文」読み上げボタン
                let exEn = examples.first?.en ?? ""
                let exJa = examples.first?.ja ?? ""
                speakExample(en: exEn, ja: exJa)
            },
            addExampleTapped: {
                editingCard = c
            },
            toggleSpeechSpeed: {
                speechFast.toggle()
            },
            speechFast: speechFast,
            toggleSpeakBoth: {
                speakBoth.toggle()
            },
            speakBoth: speakBoth,
            accent: rowAccent,
            onEditFromMenu: {
                onEdit(c)
            },
            onDeleteFromMenu: {
                HomeworkStore.shared.delete(c)
                onDataChanged()
            }
        )
    }
    // MARK: - TTS helper

    private func speakWord(_ text: String) {
        speak(text, lang: "en-US")
    }

    private func speakExample(en: String, ja: String) {
        speak(en, lang: "en-US")
        if speakBoth, !ja.isEmpty {
            speak(ja, lang: "ja-JP")
        }
    }

    private func speak(_ text: String, lang: String) {
        guard !text.isEmpty else { return }

        DispatchQueue.main.async {
            let u = AVSpeechUtterance(string: text)
            u.voice = AVSpeechSynthesisVoice(language: lang)
            u.rate = speechFast ? 0.65 : 0.45
            synthesizer.speak(u)
        }
    }
}

// MARK: - 1 行のカード（11/27 CardRow の UI を移植）
/// Wordcardpage.swift 内の CardRow と同じ見た目にするための専用 Row
private struct POSCardRow: View {
    
    // ==== 一時的なダミー変数（旧コード踏襲）====
    var posLabel: String = ""
    var hasDolphin: Bool = false
    var hasGold: Bool = false
    var isTutor: Bool = true
    
    @State private var inCollectionLocal: Bool = false
    @State private var learnedLocal: Bool = false
    
    // 入力（新データモデル対応）
    let pos: PartOfSpeech
    let word: String
    let meanings: [String]             // ← [String]
    let examples: [ExampleEntry]       // ← 例文配列
    let note: String
    let irregularForms: [String]
    let reversed: Bool
    
    let isChecked: Bool
    let isFav: Bool
    let expanded: Bool
    let rowHeight: CGFloat
    
    // アクション
    let checkTapped: () -> Void
    let heartTapped: () -> Void
    let centerTapped: () -> Void
    let speakWordTapped: () -> Void
    let speakExampleTapped: () -> Void
    let addExampleTapped: () -> Void
    let toggleSpeechSpeed: () -> Void
    let speechFast: Bool
    let toggleSpeakBoth: () -> Void
    let speakBoth: Bool
    let accent: Color
    
    // … メニュー用（カード編集／削除はここから）
    let onEditFromMenu: () -> Void
    let onDeleteFromMenu: () -> Void
    
    private func splitOthers(_ s: String) -> (tag: String, body: String) {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)

        // 全角スペース（「定冠詞　その〜」）
        if let r = t.range(of: "　") {
            let tag  = String(t[..<r.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let body = String(t[r.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !tag.isEmpty, !body.isEmpty { return (tag, body) }
        }

        // 半角スペース（「前置詞 〜の上に」）
        let parts = t.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        if parts.count == 2 {
            return (String(parts[0]), String(parts[1]))
        }

        // 「（名詞）バター」
        if t.hasPrefix("（"), let r = t.range(of: "）") {
            let tag  = String(t[..<t.index(after: r.lowerBound)]) // "（名詞）"
            let body = String(t[t.index(after: r.lowerBound)...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !body.isEmpty { return (tag, body) }
        }

        return ("", t)
    }
    
    // 中央：語 or 意味（中央タップで反転）
    private var primaryMeaning: String {
        meanings.first ?? ""
    }

    @ViewBuilder
    private var frontText: some View {
        if reversed {
            if pos == .others {
                let (tag, bodyMeaning) = splitOthers(primaryMeaning)

                VStack(alignment: .leading, spacing: 4) {
                    if !tag.isEmpty {
                        Text(tag)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(bodyMeaning)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)
                }
            } else {
                Text(primaryMeaning)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)
            }
        } else {
            Text(word)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.primary)
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            if !expanded {
                // ===== 表 =====
                ZStack(alignment: .topTrailing) {
                    
                    // 本体
                    HStack(alignment: .center, spacing: 12) {
                        
                        // 左：チェック
                        Button(action: checkTapped) {
                            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .symbolRenderingMode(.monochrome)
                                .foregroundStyle(isChecked ? accent : .secondary)
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                        

                        frontText
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture(perform: centerTapped)
                        
                        // 右：ハート
                        Button(action: heartTapped) {
                            Image(systemName: isFav ? "heart.fill" : "heart")
                                .font(.title2)
                                .symbolRenderingMode(.monochrome)
                                .foregroundStyle(isFav ? accent : .secondary)
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(minHeight: rowHeight)
                }
                
            } else {
                // ===== 裏 =====
                // 裏面のUI は CardBackView.swift の現在版に合わせて呼ぶ
                CardBackView(
                    pos: pos,
                    word: word,
                    meanings: meanings,
                    examples: examples,
                    note: note,
                    irregularForms: irregularForms,
                    
                )
                .contentShape(Rectangle())
                .onTapGesture(perform: centerTapped)
            }
        }
        // 表裏どちらにも効くカードの枠
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        
        // 左下 “…“ メニュー（編集・削除）— 11/27版と同じ
        .overlay(alignment: .bottomLeading) {
            ZStack {
                // 当たり判定
                Color.clear
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button(action: onEditFromMenu) {
                            Label("このカードを編集", systemImage: "square.and.pencil")
                        }
                        Button(role: .destructive, action: onDeleteFromMenu) {
                            Label("このカードを削除", systemImage: "trash")
                        }
                    }
                
                // 見た目の “…”（薄いグレー）
                Image(systemName: "ellipsis")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .opacity(0.7)
            }
            .padding(.leading, 6)
            .padding(.bottom, 4)
            .opacity(expanded ? 0 : 1)
            .allowsHitTesting(!expanded)
        }
    }
}

extension String {
    /// "定冠詞　その〜、例の" / "前置詞 〜の上に" を (label, body) に分ける
    func splitHeadLabel() -> (label: String?, body: String) {
        let s = self.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return (nil, s) }

        // 全角スペース優先 → 半角スペース
        if let r = s.range(of: "　") ?? s.range(of: " ") {
            let head = String(s[..<r.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let rest = String(s[r.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            return (head.isEmpty ? nil : head, rest)
        }
        return (nil, s)
    }
}
