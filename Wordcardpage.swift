//
//
//
//
//  WordcardPage.swift — 完全同期修正版（2025/12）
//

import SwiftUI
import AVFoundation

// MARK: スクロール位置の取得
private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - 1 行のカード（表 + 裏）
private struct CardRow: View {

    // --- 入力 ---
    let word: String
    let meaning: String
    let exampleEn: String
    let exampleJa: String
    let note: String
    let reversed: Bool

    let isChecked: Bool
    let isFav: Bool
    let expanded: Bool
    let rowHeight: CGFloat

    // --- アクション ---
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

    @State private var inCollectionLocal: Bool = false
    @State private var learnedLocal: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // MARK: 表
            if !expanded {
                ZStack(alignment: .topTrailing) {
                    HStack(alignment: .center, spacing: 12) {
                        // チェック済み
                        Button(action: checkTapped) {
                            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(isChecked ? accent : .secondary)
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                        
                        // 単語 or 意味
                        let display = reversed ? meaning : word
                        let isJa = reversed    // 意味＝日本語

                        Text(display)
                            .font(.system(size: isJa ? 22 : 28, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture(perform: centerTapped)

                        // ♡
                        Button(action: heartTapped) {
                            Image(systemName: isFav ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundStyle(isFav ? accent : .secondary)
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(minHeight: rowHeight)
                }

            // MARK: 裏
            } else {
                CardBackView(
                    word: word,
                    posLabel: "",
                    meaning: meaning,
                    exampleEn: exampleEn,
                    exampleJa: exampleJa,
                    hasDolphin: false,
                    hasGold: false,
                    inCollection: $inCollectionLocal,
                    learned: $learnedLocal,
                    canEditExamples: true,
                    onEditExample: { addExampleTapped() }
                )
                .contentShape(Rectangle())
                .onTapGesture(perform: centerTapped)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

//
// MARK: - 品詞ごとの一覧画面（Navigation先）
//
struct POSFlashcardListView: View {
    let pos: PartOfSpeech
    let accent: Color
    let animalName: String

    @Environment(\.dismiss) private var dismiss
    
    @State private var reversed = false
    @State private var showingAdd = false
    
    @State private var editingWord: WordCard? = nil
    @State private var dataVersion = 0

    // カード配列
    @State private var cards: [WordCard] = []

    var body: some View {
        POSFlashcardView(
            title: pos.jaTitle,
            cards: cards,
            accent: accent,
            background: pos.backgroundColor.opacity(0.50),
            animalName: animalName,
            reversed: reversed,
            onEdit: { c in editingWord = c },
            onDataChanged: { dataVersion &+= 1 },
            perRowAccent: true
        )
        .onAppear { loadCards() }
        .onChange(of: dataVersion) { loadCards() }

        .navigationTitle(pos.jaTitle)
        .navigationBarTitleDisplayMode(.inline)
        .tint(.blue)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                Menu {
                    Button("単語を追加") { showingAdd = true }

                    if pos != .others {
                        Button("不足分を自動追加（24まで）") {
                            HomeworkStore.shared.autofill(for: pos, target: 24)
                            dataVersion &+= 1
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.secondary)
                        .opacity(0.45)
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { dismiss() } label: {
                    Text("ホームへ🏠")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .sheet(isPresented: $showingAdd, onDismiss: { dataVersion &+= 1 }) {
            AddWordView(pos: pos)
        }
        .sheet(item: $editingWord, onDismiss: { dataVersion &+= 1 }) { c in
            AddWordView(pos: pos, editing: c)
        }
    }

    private func loadCards() {
        let raw = HomeworkStore.shared.list(for: pos)
        let home = raw.filter {
            !$0.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !$0.meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        cards = home.isEmpty
            ? Array(SampleDeck.filtered(by: pos).prefix(40))
            : home
    }
}

//
// MARK: - 1画面分のカード一覧（メイン）
//
struct POSFlashcardView: View {
    let title: String
    let cards: [WordCard]
    let accent: Color
    let background: Color
    let animalName: String

    @State private var reversed: Bool
    let onEdit: (WordCard) -> Void
    var onDataChanged: () -> Void = { }
    var perRowAccent: Bool = false

    @State private var speechFast = false
    @State private var speakBoth = true
    @State private var expandedID: UUID? = nil

    @State private var scrollOffset: CGFloat = 0
    
    // 編集画面
    @State private var editingCard: WordCard? = nil
    private func addExample(for c: WordCard) { editingCard = c }

    private let rowH: CGFloat = 110
    private let synthesizer = AVSpeechSynthesizer()

    init(
        title: String,
        cards: [WordCard],
        accent: Color,
        background: Color,
        animalName: String,
        reversed: Bool,
        onEdit: @escaping (WordCard) -> Void,
        onDataChanged: @escaping () -> Void = {},
        perRowAccent: Bool = false
    ) {
        self.title = title
        self.cards = cards
        self.accent = accent
        self.background = background
        self.animalName = animalName
        self.reversed = reversed
        self.onEdit = onEdit
        self.onDataChanged = onDataChanged
        self.perRowAccent = perRowAccent
        _reversed = State(initialValue: reversed)
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            ScrollView {
                GeometryReader { g in
                    Color.clear.preference(
                        key: ScrollOffsetKey.self,
                        value: -g.frame(in: .named("scroll")).minY
                    )
                }
                .frame(height: 0)

                VStack(spacing: 16) {
                    ForEach(cards, id: \.id) { card in
                        row(for: card, isExpanded: expandedID == card.id)
                    }
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 140)
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { v in
                scrollOffset = max(0, v)
            }

            // マスコット
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

        .toolbarBackground(background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)

                    Button { reversed.toggle() } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(accent)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(.black.opacity(0.45), lineWidth: 1)
                                )
                            Text("英日")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(item: $editingCard) { card in
            ExampleEditorView(word: card.word)
        }
    }

    // MARK: 行の生成
    @ViewBuilder
    private func row(for c: WordCard, isExpanded: Bool) -> some View {
        let saved = ExampleStore.shared.example(for: c.word)
        let exEn = saved?.en ?? ""
        let exJa = saved?.ja ?? ""
        let note = saved?.note ?? ""

        // 不規則動詞の処理
        let isVerb = (c.pos == .verb)
        let forms = isVerb ? (IrregularVerbBank.forms(for: c.word) ?? []) : []
        let displayWord = (!forms.isEmpty ? forms.joined(separator: " · ") : c.word)
        let speakForms = (!forms.isEmpty ? forms : [c.word])

        let isChecked = HomeworkStore.shared.isLearned(c)
        let isFav = HomeworkStore.shared.isFavorite(c)
        let canDelete = HomeworkStore.shared.exists(word: c.word, meaning: c.meaning, pos: c.pos)

        CardRow(
            word: displayWord,
            meaning: c.meaning,
            exampleEn: exEn,
            exampleJa: exJa,
            note: note,
            reversed: reversed,
            isChecked: isChecked,
            isFav: isFav,
            expanded: isExpanded,
            rowHeight: rowH,

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
                    expandedID = (expandedID == c.id ? nil : c.id)
                }
            },

            speakWordTapped: { speakForms.forEach { speakWord($0) } },
            speakExampleTapped: { speakExample(en: exEn, ja: exJa) },

            addExampleTapped: { addExample(for: c) },
            toggleSpeechSpeed: { speechFast.toggle() },
            speechFast: speechFast,
            toggleSpeakBoth: { speakBoth.toggle() },
            speakBoth: speakBoth,
            accent: perRowAccent ? c.pos.accent : accent
        )

        // …メニュー
        .overlay(alignment: .bottomLeading) {
            if !isExpanded {
                Menu {
                    Button { onEdit(c) } label: {
                        Label("このカードを編集", systemImage: "square.and.pencil")
                    }
                    if canDelete {
                        Button(role: .destructive) {
                            HomeworkStore.shared.delete(c)
                            onDataChanged()
                        } label: {
                            Label("このカードを削除", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .offset(x: -2, y: -4) 
            }
        }
    }

    // MARK: 音声
    private func speakWord(_ text: String) { speak(text, lang: "en-US") }

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
