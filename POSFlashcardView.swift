//
//11/27版 Wordcardpage.swift の UI デザインを共通ビューに移植した版 (12/17 .json)→2026/01/24不規則動詞、履歴対応版
//
//  POSFlashcardView.swift
//  WordsForest
//
// POSFlashcardView.swift
//

import SwiftUI
import AVFoundation

final class SpeechManager: ObservableObject {
    let synthesizer: AVSpeechSynthesizer

    init() {
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.usesApplicationAudioSession = false
        self.synthesizer = synthesizer
    }
}

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

    // 複数品詞をまとめて表示するとき、品詞の境目に見出しを出す
    let showPOSSectionHeaders: Bool

    // 宿題モードなどで、✅したものは行を隠したい画面で true
    let hideLearned: Bool

    // 品詞ページだけ、タイトルから A〜Z 頭文字ジャンプを使う
    let alphabetJumpEnabled: Bool
    
    // すでにあればそのまま
    @ObservedObject private var store = HomeworkStore.shared
    
    // 表示設定：動物マスコット

    @AppStorage(DefaultsKeys.showMascots) private var showMascots: Bool = true
    
    /// ページ単位の英⇄日トグル
    @State private var reversed: Bool
    
    /// 音声関連
    @StateObject private var speech = SpeechManager()
    @State private var speechFast = false      // ゆっくり
    @State private var speakBoth  = true       // 英＋日
    
    /// 展開中のカード index（nil なら全て表面）
    @State private var expandedIndex: Int? = nil
    
    /// A〜Z 頭文字ジャンプ
    @State private var showingAlphabetJump = false
    
    /// 例文編集シート用
    @State private var editingCard: WordCard? = nil
    
    /// 親側に渡すコールバック
    var onEdit: (WordCard) -> Void
    var onDataChanged: () -> Void
    var onBack: (() -> Void)?
    var onAdd: (() -> Void)?
    var onHome: (() -> Void)?
    
    /// レイアウト定数（11/27版と同じ思想）
    private let rowsPerScreen: CGFloat = 4

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
        onBack: (() -> Void)? = nil,
        onAdd: (() -> Void)? = nil,
        onHome: (() -> Void)? = nil,
        perRowAccent: Bool = false,
        showPOSSectionHeaders: Bool = false,
        hideLearned: Bool = false,
        alphabetJumpEnabled: Bool = false
    ) {
        self.title = title
        self.cards = cards
        self.accent = accent
        self.background = background
        self.animalName = animalName
        self.onEdit = onEdit
        self.onDataChanged = onDataChanged
        self.onBack = onBack
        self.onAdd = onAdd
        self.onHome = onHome
        self.perRowAccent = perRowAccent
        self.showPOSSectionHeaders = showPOSSectionHeaders
        self.hideLearned = hideLearned
        self.alphabetJumpEnabled = alphabetJumpEnabled
        _reversed = State(initialValue: reversed)
        
    }
    
    // MARK: - body
    
    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                GeometryReader { outer in
                    let rowH = max(88, (outer.size.height - 140) / rowsPerScreen)

                    ScrollView {
                        LazyVStack(spacing: 16) {

                            if title == "検索結果" && cards.isEmpty {
                                VStack(spacing: 14) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 34))
                                        .foregroundStyle(.secondary)

                                    Text("この単語は現在登録されていません")
                                        .font(.headline)

                                    Text("必要な場合は、＋（単語カードの追加）\nまたは宿題編集から登録できます。")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top, 80)
                                .frame(maxWidth: .infinity)
                            } else if cards.isEmpty {
                                ContentUnavailableView("まだありません", systemImage: "book")
                                    .padding(.top, 80)
                                    .frame(maxWidth: .infinity)
                            } else {
                                rows(rowHeight: rowH)
                            }

                            Spacer(minLength: 80)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 140)
                    }

                    // 右下マスコット（固定）
                    if showMascots {
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
                                    .offset(x: -32)
                            }
                        }
                    }
                }
            }
            .background(background.ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .toolbarBackground(background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarBackButtonHidden(alphabetJumpEnabled)
            .toolbar(alphabetJumpEnabled ? .hidden : .visible, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                if alphabetJumpEnabled {
                    posControlHeader(proxy: proxy)
                }
            }
            .toolbar {
                if !alphabetJumpEnabled {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 8) {
                            Text(title)
                                .font(.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)

                            Button {
                                reversed.toggle()
                            } label: {
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(accent)
                                        .frame(width: 11, height: 11)
                                        .overlay(
                                            Circle().stroke(Color(.separator), lineWidth: 0.8)
                                        )

                                    Text("英↔︎日")
                                        .font(.subheadline)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("英語と日本語を反転")
                        }
                    }
                }
            }
            .sheet(item: $editingCard) { card in
                ExampleEditorView(pos: card.pos, word: card.word)
            }
        }
    }

    // MARK: - 品詞ページ上部コントロール

    @ViewBuilder
    private func posControlHeader(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 4) {
            // 左端の移動／追加は、タップ領域を保ったまま少し寄せる
            HStack(spacing: 1) {
                if let onBack {
                    Button {
                        onBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 22, height: 22)
                    }
                    .modifier(CompactGlassCircleButton())
                    .frame(width: 44, height: 44)
                    .accessibilityLabel("戻る")
                }

                if let onAdd {
                    GuardedButton {
                        onAdd()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .frame(width: 22, height: 22)
                    }
                    .modifier(CompactGlassCircleButton())
                    .frame(width: 44, height: 44)
                    .accessibilityLabel("単語カードを追加")
                }
            }

            // 英⇄日は品詞名の左へ。A–Zとの押し分けも明確にする。
            Button {
                reversed.toggle()
            } label: {
                HStack(spacing: 3) {
                    Circle()
                        .fill(accent)
                        .frame(width: 9, height: 9)
                        .overlay(
                            Circle().stroke(Color(.separator), lineWidth: 0.7)
                        )

                    Text("英↔︎日")
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.88)
                }
            }
            .modifier(CompactGlassCapsuleButton())
            .frame(height: 44)
            .accessibilityLabel("英語と日本語を反転")

            // 品詞名は操作ではなく見出し。3文字分の席を必ず確保する。
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(10)
                .frame(minWidth: 46)

            Button {
                showingAlphabetJump.toggle()
            } label: {
                Text("A–Z")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }
            .modifier(CompactGlassCapsuleButton())
            .frame(height: 44)
            .accessibilityLabel("頭文字へ移動")
            .popover(isPresented: $showingAlphabetJump) {
                alphabetJumpPopover(proxy: proxy)
                    .presentationCompactAdaptation(.popover)
            }

            Spacer(minLength: 0)

            if let onHome {
                Button {
                    onHome()
                } label: {
                    Text("ホームへ🏠")
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                .modifier(CompactGlassCapsuleButton())
                .frame(height: 44)
                .accessibilityLabel("ホームへ")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(background)
    }

    // MARK: - A〜Z 頭文字ジャンプ

    private let alphabetLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map(String.init)

    private var visibleCardsForJump: [WordCard] {
        hideLearned
            ? cards.filter { !store.isLearned($0) }
            : cards
    }

    private var availableInitialLetters: Set<String> {
        Set(visibleCardsForJump.compactMap { initialLetter(of: $0.word) })
    }

    private func initialLetter(of word: String) -> String? {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.uppercased().first else { return nil }

        let letter = String(first)
        return alphabetLetters.contains(letter) ? letter : nil
    }

    private func jumpToInitial(_ letter: String, proxy: ScrollViewProxy) {
        guard let index = visibleCardsForJump.firstIndex(where: {
            initialLetter(of: $0.word) == letter
        }) else { return }

        showingAlphabetJump = false

        // A〜Zジャンプは一回だけ。
        // スクロール位置をStateで追跡し続けず、ジャンプ後は通常の手動スクロールへ戻す。
        DispatchQueue.main.async {
            proxy.scrollTo(index, anchor: .top)
        }
    }

    private func alphabetJumpPopover(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("頭文字へ移動")
                .font(.headline)

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 6),
                    count: 6
                ),
                spacing: 8
            ) {
                ForEach(alphabetLetters, id: \.self) { letter in
                    let available = availableInitialLetters.contains(letter)

                    Button(letter) {
                        jumpToInitial(letter, proxy: proxy)
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 34)
                    .buttonStyle(.bordered)
                    .disabled(!available)
                    .opacity(available ? 1.0 : 0.28)
                }
            }
        }
        .padding(16)
        .frame(width: 286)
    }

    // MARK: - 行の並び
    
    @ViewBuilder
    private func rows(rowHeight: CGFloat) -> some View {
        // 表示対象は A〜Z ジャンプと同じ一覧を使う
        let visibleCards = visibleCardsForJump

        // enumerate して index を作る
        let enumerated = Array(visibleCards.enumerated())
        
        ForEach(enumerated, id: \.offset) { pair in
            let i = pair.offset
            let c = pair.element

            if showPOSSectionHeaders &&
                (i == 0 || visibleCards[i - 1].pos != c.pos) {

                posSectionHeader(for: c.pos)
            }

            row(for: c, index: i, rowHeight: rowHeight)
                .id(i)
        }
    }
    @ViewBuilder
    private func posSectionHeader(for pos: PartOfSpeech) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(pos.accent)
                .frame(width: 12, height: 12)

            Text(pos.jaTitle)
                .font(.headline)
                .foregroundStyle(pos.accent)

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }
    // MARK: - 1 行
    @ViewBuilder
    private func row(for c: WordCard, index i: Int, rowHeight: CGFloat) -> some View {

        let ex = ExampleStore.shared.firstExample(
            pos: c.pos,
            word: c.word
        )

        let examples: [ExampleEntry] = ex.map { [$0] } ?? []

        let note = ExampleStore.shared.displayWordNote(
            pos: c.pos,
            word: c.word
        )
        
        // 不規則動詞なら 3 形を表示＆読み上げ対象に
        let isVerb = (c.pos == .verb)
        let irregularForms: [String] = isVerb ? (IrregularVerbBank.forms(from: c.word) ?? []) : []

        // 表示用：英面のときだけ3形を表示
        let displayWord = (isVerb && !irregularForms.isEmpty)
            ? irregularForms.joined(separator: " ・ ")
            : c.word

        // 読み上げ用：3形あれば全部読む
        let speakForms = (isVerb && !irregularForms.isEmpty) ? irregularForms : [c.word]

        // meanings は [String] なので、表の文字は先頭だけ大きく表示
        let meanings = c.meanings

        // 学習状態
        let isChecked = HomeworkStore.shared.isLearned(c)
        let isFav = HomeworkStore.shared.isFavorite(c)

        // プリインストール原本かどうか
        let isBundled = HomeworkStore.shared.isBundledCard(c)

        // 行カラー
        let rowAccent = perRowAccent ? c.pos.accent : accent
        POSCardRow(
            pos: c.pos,
            baseWord: c.word,
            displayWord: displayWord,
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
            isBundled: isBundled,
            onEditFromMenu: {
                onEdit(c)
            },
            onEditExamplesFromMenu: {
                editingCard = c
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
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        
        let u = AVSpeechUtterance(string: t)
        u.voice = AVSpeechSynthesisVoice(language: lang)
        u.rate = speechFast ? 0.65 : 0.45
        speech.synthesizer.speak(u)
    }
    
    // MARK: - 1 行のカード（11/27 CardRow の UI を移植）
    /// Wordcardpage.swift 内の CardRow と同じ見た目にするための専用 Row
    private struct POSCardRow: View {
        
        @EnvironmentObject private var teacher: TeacherMode
        @AppStorage(DefaultsKeys.usageMode)
        private var usageMode: UsageMode = .classroom
        
        // ==== 一時的なダミー変数（旧コード踏襲）====
        var posLabel: String = ""
        var isTutor: Bool = true
        
        @State private var inCollectionLocal: Bool = false
        @State private var learnedLocal: Bool = false
        
        // 入力（新データモデル対応）
        let pos: PartOfSpeech
        let baseWord: String
        let displayWord: String
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
        let isBundled: Bool

        // … メニュー用（カード編集／例文ノート編集／削除はここから）
        let onEditFromMenu: () -> Void
        let onEditExamplesFromMenu: () -> Void
        let onDeleteFromMenu: () -> Void
        
        private func runProtected(_ action: @escaping () -> Void) {
            if usageMode == .individual || teacher.unlocked {
                action()
            } else {
                teacher.requestUnlock(runAfterUnlock: action)
            }
        }

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
                Text(displayWord)
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
                        word: baseWord,
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
            .background(Color(.secondarySystemBackground))
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
                            Button {
                                runProtected(onEditExamplesFromMenu)
                            } label: {
                                Label(
                                    "例文・ノートを編集",
                                    systemImage: "text.bubble"
                                )
                            }

                            if !isBundled {
                                Button {
                                    runProtected(onEditFromMenu)
                                } label: {
                                    Label(
                                        "単語・意味を修正",
                                        systemImage: "square.and.pencil"
                                    )
                                }

                                Button(role: .destructive) {
                                    runProtected(onDeleteFromMenu)
                                } label: {
                                    Label(
                                        "このカードを削除",
                                        systemImage: "trash"
                                    )
                                }
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


// MARK: - Compact Liquid Glass controls

private struct CompactGlassCircleButton: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .controlSize(.small)
        } else {
            content
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .controlSize(.small)
        }
    }
}

private struct CompactGlassCapsuleButton: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
        } else {
            content
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
        }
    }
}
