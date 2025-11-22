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
    let accent: Color
    let animalName: String
    
    @State private var showingAdd = false
    @Environment(\.dismiss) private var dismiss
    @State private var reversed = false
    
    // 追加：編集対象カード
    @State private var editingWord: WordCard? = nil
    @State private var refreshID = UUID()
    
    var body: some View {
        let raw = HomeworkStore.shared.list(for: pos)
        let home = raw.filter {
            !$0.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !$0.meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let cards: [WordCard] = home.isEmpty
            ? Array(SampleDeck.filtered(by: pos).prefix(40))
            : home
        
            // 一覧ラッパー
            POSFlashcardView(
                title: pos.jaTitle,
                cards: cards,
                accent: accent,
                background: pos.backgroundColor.opacity(0.50),          // 既存どおり
                animalName: animalName,
                reversed: reversed,
                onEdit: { c in editingWord = c },
                onDataChanged: { refreshID = UUID() },    // ★ 変化でリフレッシュ
                perRowAccent: true
            )
            .id(refreshID)// ★ これも必須
            .onReceive(NotificationCenter.default.publisher(for: .favoritesDidChange)) { _ in
                refreshID = UUID()
            }
            .onReceive(NotificationCenter.default.publisher(for: .learnedDidChange)) { _ in
                refreshID = UUID()
            }
            .onReceive(NotificationCenter.default.publisher(for: .storeDidChange)) { _ in   // ★ 追加
                refreshID = UUID()
            }
                // ★ 追加：例文が保存/削除されたら一覧を再描画
            .onReceive(NotificationCenter.default.publisher(for: .examplesDidChange)) { _ in
                refreshID = UUID()
            }
            .navigationTitle(pos.jaTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 左：メニュー（others でも「単語を追加」は出す）
                ToolbarItemGroup(placement: .topBarLeading) {
                    Menu {
                        Button("単語を追加") { showingAdd = true }
                        // ← 自動補充だけ others の時は隠す
                        if pos != .others {
                            Button("不足分を自動追加（24まで）") {
                                HomeworkStore.shared.autofill(for: pos, target: 24)
                                refreshID = UUID()
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.secondary)  // 薄いグレー
                            .opacity(0.45)
                    }
                }

                // 中央タイトル（「名詞/動詞…」＋ 品詞色● = 英⇄日トグル）
/*                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Text(pos.jaTitle)                 // 「名詞」「動詞」など（レッスンは外すならここをそのまま）
                            .font(.headline)
                        Button {
                            reversed.toggle()             // ページ単位で英⇄日切替
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(accent)         // 品詞色の●
                                    .frame(width: 12, height: 12)
                                    .overlay(Circle().stroke(.black.opacity(0.15), lineWidth: 0.5))
                                Text("英日")               // ラベル
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
*/
                // 右：「ホームへ」は常に出す（既存を統合）
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Text("ホームへ🏠")
                    }
                    .foregroundStyle(.blue)
                    .buttonStyle(.plain)
                    .background(.ultraThinMaterial, in: Capsule())
                }
            }
            // 追加シート（others でも出す）
            .sheet(isPresented: $showingAdd, onDismiss: { refreshID = UUID() }) {
                AddWordView(pos: pos)
            }
            // 既存の編集シート（editingWord）もこの下で OK
            // 新規：編集用（ここ！）
                .sheet(item: $editingWord, onDismiss: { refreshID = UUID() }) { c in
                    AddWordView(pos: pos, editing: c)
                }
        }
    }
    // MARK: - 単語カード 1 画面（縦スクロール＋右下マスコット固定）
    struct POSFlashcardView: View {
        let title: String
        let cards: [WordCard]
        let accent: Color           // アイコン青
        let background: Color       // 画面背景
        let animalName: String
        @State private var reversed: Bool
        let onEdit: (WordCard) -> Void
        var onDataChanged: () -> Void = { }
        var perRowAccent: Bool = false
        // レイアウト定数
        private let rowsPerScreen: CGFloat = 4
        private let screensPerVariant: CGFloat = 3
        private let actionBandTailRatio: CGFloat = 0.15
        
        // 状態
        @State private var speechFast = false     // ゆっくり（🐢）
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
                
                GeometryReader { outer in
                    let rowH   = max(88, (outer.size.height - 140) / rowsPerScreen)
                    let blockH = outer.size.height * screensPerVariant
                    // let blockH = outer.size.height * screensPerVariant
                    // ↑ 将来、ページング風のアニメーションを入れる時に使う候補値
                    
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
                                .offset(x: -32)   // ← 左へ -ptを上げる
                        }
                    }
                                       
                }
            }
            // ZStack の外側にチェーン
            .scrollContentBackground(.hidden)
            .background(background)
            .toolbarBackground(background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)

            // 🆕 英⇄日トグル付きツールバー
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Text(title)                // ← ここで title を使う
                            .font(.headline)

                        Button {
                            reversed.toggle()      // ← @State だから toggle できる
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(accent)  // 品詞色の●
                                    .frame(width: 12, height: 12)
                                    .overlay(
                                        Circle()
                                            .stroke(.black.opacity(0.45), lineWidth: 1.0)
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

            // 編集シート
            .sheet(item: $editingCard) { card in
                ExampleEditorView(word: card.word)
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
            // 不規則動詞なら 3 形を表示＆読み上げ対象に
            let isVerb = (c.pos == .verb)
            let forms: [String] = isVerb ? (IrregularVerbBank.forms(for: c.word) ?? []) : []
            
            // 表示用（英面のときだけ3形を表示）
            let displayWord = (isVerb && !forms.isEmpty) ? forms.joined(separator: " · ") : c.word
            // 読み上げ用（3形あれば全部読む）
            let speakForms = (isVerb && !forms.isEmpty) ? forms : [c.word]
            // ← 追加：保存済み状態をストアから読む
            let isChecked = HomeworkStore.shared.isLearned(c)
            let isFav     = HomeworkStore.shared.isFavorite(c)
            let canDelete = HomeworkStore.shared.exists(word: c.word, meaning: c.meaning, pos: c.pos)
            
            CardRow(
                word: displayWord,
                meaning: c.meaning,
                exampleEn: exEn,
                exampleJa: exJa,
                note: note,
                reversed: reversed,
                isChecked: isChecked,
                isFav:     isFav,
                expanded: expanded == i,
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
                        expanded = (expanded == i ? nil : i)
                    }
                },
                speakWordTapped: {
                    speakForms.forEach{ speakWord($0)}},
                speakExampleTapped: { speakExample(en: exEn, ja: exJa) },
                addExampleTapped: { addExample(for: c) },
                toggleSpeechSpeed: { speechFast.toggle() },
                speechFast: speechFast,
                toggleSpeakBoth: { speakBoth.toggle() },
                speakBoth: speakBoth,
                accent: (perRowAccent ? c.pos.accent : accent)
            )
            // CardRow( … ) のすぐ後ろに付ける
            .overlay(alignment: .bottomLeading) {
                ZStack {
                    // ここが「長押しでメニュー」の当たり判定
                    Color.clear
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                        .contextMenu {
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
                        }
                    
                    // 見た目の“ … ”インジケーター（薄いグレー）
                    Image(systemName: "ellipsis")
                        .font(.caption2)                  // 小さめ
                        .foregroundStyle(.secondary)      // 薄いグレー
                        .opacity(0.7)
                }
                .padding(.leading, 6)                     // 角に寄せる量はお好みで調整
                .padding(.bottom, 4)
                .opacity(expanded == i ? 0 : 1)
                .allowsHitTesting(expanded != i)
            }
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
    // ==== 一時的なダミー変数（後で本配線に差し替え）====
    var posLabel: String = ""
    var hasDolphin: Bool = false
    var hasGold: Bool = false
    var isTutor: Bool = true

    @State private var inCollectionLocal: Bool = false
    @State private var learnedLocal: Bool = false
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

                        // 中央：語 or 意味（中央タップで反転）
                        Text(reversed ? meaning : word)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.primary)
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

                    // 右上：「…」メニュー（表だけ／薄いグレー）
                  
                }

            } else {
                // ===== 裏 =====
                // ※ 裏には「…」を置かない。タップで反転させない。
                CardBackView(
                    word: word,
                    posLabel: posLabel,
                    meaning: meaning,
                    exampleEn: exampleEn,
                    exampleJa: exampleJa,
                    hasDolphin: hasDolphin,
                    hasGold: hasGold,
                    inCollection: $inCollectionLocal,   // ← ここをローカルStateに
                    learned: $learnedLocal,             // ← 同上
                    canEditExamples: isTutor,
                    onEditExample: { addExampleTapped() }
                )
                // 裏では大きな minHeight / contentShape / onTapGesture を付けない
                .contentShape(Rectangle())
                    .onTapGesture(perform: centerTapped)                
            }
        }
        // ← この3つは if/else の“外側”（表裏どちらにも効く）
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
