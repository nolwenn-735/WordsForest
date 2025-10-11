//
//  WordcardPage.swift（統合版）
//
//
import SwiftUI
import AVFoundation

// スクロール量取得
private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - 一覧（品詞ごと → 1 画面へ遷移）
struct POSFlashcardListView: View {
    let pos: PartOfSpeech
    let accent: Color          // チェック／ハート等の青
    let animalName: String

    @State private var showingAdd = false
    @Environment(\.dismiss) private var dismiss
    @State private var reversed = false

    var body: some View {
        let home = HomeworkStore.shared.list(for: pos)
        let cards: [WordCard] = home.isEmpty
        ? Array(SampleDeck.filtered(by: pos).prefix(40))
        : home

        POSFlashcardView(
            title: "\(pos.jaTitle) レッスン",
            cards: cards,
            accent: accent,
            background: pos.backgroundColor,      // 品詞の淡色
            animalName: animalName,
            reversed: reversed
        )
        .navigationTitle("\(pos.jaTitle) レッスン")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("単語を追加")
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { dismiss() } label: { Text("ホームへ🏠") }
                    .accessibilityLabel("ホームへ")
            }
        }
        .sheet(isPresented: $showingAdd) { AddWordView(pos: pos) }
    }
}

// MARK: - 単語カード 1 画面（縦スクロール＋右下マスコット固定）
struct POSFlashcardView: View {
    let title: String
    let cards: [WordCard]
    let accent: Color           // アイコン青
    let background: Color       // 画面背景
    let animalName: String
    let reversed: Bool

    // レイアウト定数
    private let rowsPerScreen: CGFloat = 4
    private let screensPerVariant: CGFloat = 3
    private let actionBandTailRatio: CGFloat = 0.15

    // 状態
    @State private var speechFast = false     // ゆっくり（🐢/🐇）
    @State private var speakBoth  = true      // 例文を英＋日で読む
    private let tts = AVSpeechSynthesizer()

    @State private var selected = Set<Int>()  // ✅
    @State private var favored  = Set<Int>()  // ♡
    @State private var expanded: Int? = nil   // 表⇄裏 展開中の index

    @State private var scrollOffset: CGFloat = 0
    @State private var viewportH: CGFloat = 0

    // 編集シート用
    @State private var editingCard: WordCard? = nil
    private func addExample(for c: WordCard) { editingCard = c }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            GeometryReader { outer in
                let rowH   = max(88, (outer.size.height - 140) / rowsPerScreen)
                let blockH = outer.size.height * screensPerVariant

                ScrollView {
                    // スクロール量
                    GeometryReader { g in
                        Color.clear.preference(key: ScrollOffsetKey.self,
                                               value: -g.frame(in: .named("scroll")).minY)
                    }
                    .frame(height: 0)

                    VStack(spacing: 16) {
                        rows(rowH: rowH)
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 140) // 右下マスコット分の余白
                }
                .coordinateSpace(name: "scroll")
                .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 32) }
                .onPreferenceChange(ScrollOffsetKey.self) { v in
                    scrollOffset = max(0, v)
                    viewportH = outer.size.height
                }

                // 右下マスコット（固定）
                VStack { Spacer()
                    HStack { Spacer()
                        Image(animalName)
                            .resizable().scaledToFit()
                            .frame(width: 140, height: 140)
                            .allowsHitTesting(false)
                            .padding(.trailing, 12)
                            .padding(.bottom, 8)
                    }
                }

                // まとめ帯（末尾15%で出現）
                if showActionBand(blockH: blockH) {
                    actionBand
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeOut(duration: 0.25),
                                   value: showActionBand(blockH: blockH))
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
        // ZStack の外側にチェーン
        .scrollContentBackground(.hidden)
        .background(background)
        .toolbarBackground(background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)

        // 編集シート（いまの単語の既存例文を中で読み込んで編集）
        .sheet(item: $editingCard) { card in
            ExampleEditorView(word: card.word)   // ← あなたの現在の実装に合わせる
        }
    }

    // 行の並び
    @ViewBuilder
    private func rows(rowH: CGFloat) -> some View {
        let enumerated = Array(cards.enumerated())
        ForEach(enumerated, id: \.offset) { pair in
            let i = pair.offset
            let c = pair.element
            row(for: c, index: i, rowH: rowH)
        }
    }

    // 1 行
    @ViewBuilder
    private func row(for c: WordCard, index i: Int, rowH: CGFloat) -> some View {
        let saved = ExampleStore.shared.example(for: c.word)
        let exEn: String = saved?.en ?? ""
        let exJa: String = saved?.ja ?? ""
        let note = saved?.note ?? ""
        
        CardRow(
            word: c.word,
            meaning: c.meaning,
            exampleEn: exEn,
            exampleJa: exJa,
            note: note,
            reversed: reversed,
            isChecked: selected.contains(i),
            isFav: favored.contains(i),
            expanded: expanded == i,
            rowHeight: rowH,
            checkTapped: { toggle(selected: i) },
            heartTapped: { toggle(favored: i) },
            centerTapped: {
                withAnimation(.spring(response: 0.25)) {
                    expanded = (expanded == i ? nil : i)
                }
            },
            speakWordTapped: { speakWord(c.word) },
            speakExampleTapped: { speakExample(en: exEn, ja: exJa) },
            addExampleTapped: { addExample(for: c) },
            toggleSpeechSpeed: { speechFast.toggle() },
            speechFast: speechFast,
            toggleSpeakBoth: { speakBoth.toggle() },
            speakBoth: speakBoth,
            accent: accent
        )
    }

    // まとめ帯
    private var actionBand: some View {
        HStack(spacing: 10) {
            Button { selected.removeAll() } label: { bandButton("📦 覚えたBOX", filled: !selected.isEmpty) }
            Button { favored.removeAll()  } label: { bandButton("♡ MYコレ",    filled: !favored.isEmpty) }
            Spacer(minLength: 8)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.black.opacity(0.15), lineWidth: 1))
    }

    private func bandButton(_ title: String, filled: Bool) -> some View {
        Text(title)
            .font(.headline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(filled ? AnyShapeStyle(Color.primary.opacity(0.08)) : AnyShapeStyle(.thinMaterial))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func showActionBand(blockH: CGFloat) -> Bool {
        guard blockH > 0 else { return true }
        let r = (scrollOffset.truncatingRemainder(dividingBy: blockH)) / blockH
        return r >= (1.0 - actionBandTailRatio)
    }

    private func toggle(selected i: Int) {
        if selected.contains(i) { selected.remove(i) } else { selected.insert(i) }
    }
    private func toggle(favored i: Int) {
        if favored.contains(i) { favored.remove(i) } else { favored.insert(i) }
    }

    // TTS
    private func speakWord(_ text: String) { speak(text, lang: "en-US") }
    private func speakExample(en: String, ja: String) {
        speak(en, lang: "en-US")
        if speakBoth, !ja.isEmpty { speak(ja, lang: "ja-JP") }
    }
    private func speak(_ text: String, lang: String) {
        guard !text.isEmpty else { return }
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: lang)
        u.rate  = speechFast ? 0.55 : 0.45
        tts.speak(u)
    }
}

// MARK: - 1 行のカード（表／裏）
private struct CardRow: View {
    // 入力
    let word: String
    let meaning: String
    let exampleEn: String
    let exampleJa: String
    let note: String          // ← 追加
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
    let accent: Color        // チェック・ハート・操作アイコン（青）

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            if !expanded {
                // ===== 表 =====
                HStack(alignment: .center, spacing: 12) {
                    Button(action: checkTapped) {
                        Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(accent)
                    }

                    Text(reversed ? meaning : word)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: centerTapped)

                    Button(action: heartTapped) {
                        Image(systemName: isFav ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundStyle(accent)
                    }
                }
                .frame(minHeight: rowHeight)

            } else {
                // ===== 裏 =====
                VStack(alignment: .leading, spacing: 10) {

                    // 見出し行（左：日本語、右：操作アイコンを青で）
                    HStack(alignment: .center) {
                        Text(meaning)
                            .font(.system(size: 22, weight: .semibold))

                        Spacer()

                        HStack(spacing: 16) {
                            Button(action: speakWordTapped) {
                                Label("単語だけ", systemImage: "speaker.wave.2.fill")
                            }
                            Button(action: speakExampleTapped) {
                                Label("例文", systemImage: "bubble.left.and.bubble.right.fill")
                            }
                            Button(action: addExampleTapped) {
                                Image(systemName: "square.and.pencil")
                            }
                        }
                        .labelStyle(.titleAndIcon)
                        .font(.body)
                        .foregroundStyle(accent)   // ← 青
                    }

                    // 例文（英→日、日を少し大きめに）
                    if !exampleEn.isEmpty {
                        Text(exampleEn).font(.system(size: 18))
                    }
                    if !exampleJa.isEmpty {
                        Text(exampleJa).font(.system(size: 20, weight: .medium))
                    }
                    if !note.isEmpty {
                        Text(note)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 12)

                    // トグルは一番下（統一で iOS 風グリーン）
                    HStack {
                        Label("ゆっくり", systemImage: "tortoise").font(.subheadline)
                        Toggle("", isOn: .init(
                            get: { !speechFast },
                            set: { _ in toggleSpeechSpeed() }
                        ))
                        .labelsHidden()
                        .tint(.green)

                        Spacer()

                        Text("英＋日").font(.subheadline)
                        Toggle("", isOn: .init(
                            get: { speakBoth },
                            set: { _ in toggleSpeakBoth() }
                        ))
                        .labelsHidden()
                        .tint(.green)
                    }
                }
                .frame(maxWidth: .infinity,
                       minHeight: rowHeight * 2.2,
                       alignment: .topLeading)
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
