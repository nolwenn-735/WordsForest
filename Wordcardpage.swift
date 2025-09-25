import SwiftUI

// Wordcardpage.swift のどこか（import SwiftUI の下あたり）に
struct WordItem: Identifiable, Hashable { let id = UUID(); let text: String }

struct WordCardPage: View {
    let pos: PartOfSpeech
    let baseVariantIndex: Int
    let items: [WordItem]

    var body: some View {
        // とりあえずの仮実装（あとで本実装に差し替え）
        List(items) { it in Text(it.text) }
            .navigationTitle("🐻\(pos.rawValue) レッスン")
    }
}

struct POSFlashcardListView: View {
    let pos: PartOfSpeech
    let accent: Color
    let animalName: String
    
    @State private var showingAdd = false
    @Environment(\.dismiss) private var dismiss
    @State private var reversed = false   // ← これあり
    
    var body: some View {
        // カード配列を用意（今のままでOKならこの2行は既存の書き方でも可）
        let hw = HomeworkStore.shared.list(for: pos)
        let cards = hw.isEmpty ? Array(SampleDeck.filtered(by: pos).prefix(4)) : hw
        
        // 返すビューはこれ（←このビューに .toolbar / .sheet を“チェイン”する）
        VStack(spacing: 0) {
            // ← ここは任意：ツールバーが出ない環境向けのインライン切替ボタン
            HStack {
                Spacer()
                Button { reversed.toggle() } label: {
                    Label(reversed ? "日→英" : "英→日", systemImage: "arrow.left.arrow.right")
                        .labelStyle(.titleAndIcon)
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
            
            POSFlashcardView(
                title: "🐻\(pos.rawValue) レッスン",
                cards: cards,
                accent: accent,
                animalName: animalName,
                reversed: reversed
            )
        }
        // ！！！ここが超重要：返すビューに“連続して”ぶら下げる！！！
        .navigationTitle("🐻\(pos.rawValue)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 左：＋
            ToolbarItem(placement: .topBarLeading) {
                Button { showingAdd = true } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("単語を追加")
            }
            // 右：🏠（とりあえず1段戻る動作）
            ToolbarItem(placement: .topBarTrailing) {
                Button { dismiss() } label: { Text("🏠") }
                    .accessibilityLabel("ホームへ")
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddWordView(pos: pos)
        }
    }
    // 単語カード1画面（縦スクロール＋右下にマスコット固定）
}
    struct POSFlashcardView: View {
        let title: String
        let cards: [WordCard]
        let accent: Color
        let animalName: String
        let reversed: Bool          // ← デフォルトは付けない

        init(title: String,
             cards: [WordCard],
             accent: Color,
             animalName: String,
             reversed: Bool = false) {   // ← ここでデフォルトを持つ
            self.title = title
            self.cards = cards
            self.accent = accent
            self.animalName = animalName
            self.reversed = reversed
        }
    
    
        // レイアウト定数
        private let rowsPerScreen: CGFloat = 4
        private let screensPerVariant: CGFloat = 3   // ← ここが「3スクリーン1セット」
        private let actionBandTailRatio: CGFloat = 0.15
        
        // 状態
        @State private var selected = Set<Int>()     // ✅選択（インデックスで管理）
        @State private var favored  = Set<Int>()     // ♡選択
        @State private var expanded: Int? = nil      // 表⇄裏
        @State private var scrollOffset: CGFloat = 0
        @State private var viewportH: CGFloat = 0
        
        var body: some View {
            ZStack {
                accent.ignoresSafeArea()
                
                GeometryReader { outer in
                    let rowH = max(88, (outer.size.height - 140) / rowsPerScreen) // ざっくり4枚入る高さ
                    let blockH = outer.size.height * screensPerVariant
                    
                    ScrollView {
                        // スクロール量取得
                        GeometryReader { g in
                            Color.clear
                                .preference(key: ScrollOffsetKey.self,
                                            value: -g.frame(in: .named("scroll")).minY)
                        }
                        .frame(height: 0)
                        
                        VStack(spacing: 16) {
                            // タイトル（遷移先だけ整形）
                            Text(title)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.primary)
                                .padding(.top, 6)
                            
                            rows(rowH: rowH)
                            
                            /*                       ForEach(cards.indices, id: \.self) { i in
                             let c = cards[i]
                             
                             CardRow(
                             word: c.word,
                             meaning: c.meaning,
                             
                             posText: c.partOfSpeechText,
                             exampleEn: (c.exampleEn ?? c.example ?? ""),
                             exampleJa: (c.exampleJa ?? c.meaning),
                             hasDolphin: c.hasDolphin ?? false,
                             hasGold: c.hasGold ?? false,
                             
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
                             }
                             )
                             }
                             */
                            Spacer(minLength: 80)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 140) // 右下動物＋帯の余白
                        .background(Color.clear)
                    }
                    .coordinateSpace(name: "scroll")
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 32)   // 好みで 24〜40
                    }
                    .onPreferenceChange(ScrollOffsetKey.self) { v in
                        scrollOffset = max(0, v)
                        viewportH   = outer.size.height
                    }
                    
                    
                    // 右下の動物（固定）
                    VStack { Spacer()
                        HStack { Spacer()
                            Image(animalName) // ← まずは固定バリアント表示
                                .resizable().scaledToFit()
                                .frame(width: 140, height: 140)
                                .allowsHitTesting(false)
                                .padding(.trailing, 12).padding(.bottom, 8)
                        }
                    }
                    
                    // まとめ操作バー：ブロック終端15%だけ表示
                    if showActionBand(blockH: blockH) {
                        actionBand
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.easeOut(duration: 0.25), value: showActionBand(blockH: blockH))
                            .padding(.horizontal, 12).padding(.bottom, 8)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(accent)
            .toolbarBackground(accent, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
        }
        @ViewBuilder
        private func rows(rowH: CGFloat) -> some View {
            // 大きい式を分解して型推論を軽くする
            let enumerated = Array(cards.enumerated())
            ForEach(enumerated, id: \.offset) { pair in
                let i = pair.offset
                let c = pair.element
                row(for: c, index: i, rowH: rowH)
            }
        }
        
        @ViewBuilder
        private func row(for c: WordCard, index i: Int, rowH: CGFloat) -> some View {
            // 先にローカル変数へ落としておくとさらに楽になる
            // 先にローカル変数へ落としておくとさらに楽になる
            let saved = ExampleStore.shared.example(for: c.word)
            let exEn: String = saved?.en ?? ""
            let exJa: String = saved?.ja ?? ""          // ← デフォルトは空
            let pos: String? = nil
            let hasD: Bool = false
            let hasG: Bool = false
            
            CardRow(
                word: c.word,
                meaning: c.meaning,
                posText: pos,
                exampleEn: exEn,
                exampleJa: exJa,
                hasDolphin: hasD,
                hasGold: hasG,
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
                }
            )
        }
        
        // --- まとめ帯 ---
        private var actionBand: some View {
            HStack(spacing: 10) {
                Button {
                    // ✅をまとめて「覚えたBOX」へ（今はダミー処理）
                    selected.removeAll()
                } label: { bandButton("📦 覚えたBOX", filled: !selected.isEmpty) }
                
                Button {
                    // ♡をまとめてコレクションへ（今はダミー処理）
                    favored.removeAll()
                } label: { bandButton("♡ MYコレ", filled: !favored.isEmpty) }
                
                Spacer(minLength: 8)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.black.opacity(0.08), lineWidth: 1))
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        }
        
        private func bandButton(_ title: String, filled: Bool) -> some View {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .padding(.vertical, 10).padding(.horizontal, 12)
                .background(filled ? Color.black.opacity(0.85) : Color.white.opacity(0.95))
                .foregroundStyle(filled ? .white : .black)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black.opacity(0.15), lineWidth: 1))
        }
        
        private func showActionBand(blockH: CGFloat) -> Bool {
            guard blockH > 0 else { return true }
            let r = (scrollOffset.truncatingRemainder(dividingBy: blockH)) / blockH
            return r >= (1.0 - actionBandTailRatio) // 終端15%
        }
        
        private func toggle(selected i: Int) {
            if selected.contains(i) { selected.remove(i) } else { selected.insert(i) }
        }
        private func toggle(favored i: Int) {
            if favored.contains(i) { favored.remove(i) } else { favored.insert(i) }
        }
    }
    
    // 1行のカード（表/裏）
    private struct CardRow: View {
        @State private var isShowingEditor = false
        @State private var exEnLocal: String? = nil
        @State private var exJaLocal: String? = nil
        
        let word: String
        let meaning: String
        let posText: String?
        let exampleEn: String
        let exampleJa: String
        let hasDolphin: Bool
        let hasGold: Bool
        let reversed: Bool
        
        let isChecked: Bool
        let isFav: Bool
        let expanded: Bool
        let rowHeight: CGFloat
        let checkTapped: () -> Void
        let heartTapped: () -> Void
        let centerTapped: () -> Void
        
        
        
        var body: some View {
            // 裏面のときは左右のボタンを隠して中央を広げる
            let spacing: CGFloat = expanded ? 0 : 12
            
            VStack(spacing: 0) {
                HStack(spacing: spacing) {
                    
                    // ✅（裏面では非表示）
                    if !expanded {
                        Button(action: checkTapped) {
                            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                                .font(.system(size: 22, weight: .semibold))
                        }
                    }
                    
                    // 中央：表／裏
                    VStack(alignment: .leading, spacing: 6) {
                        if expanded {
                            CardBackView(
                                word: word,
                                posLabel: posText,
                                meaning: meaning,
                                exampleEn: exEnLocal ?? exampleEn,   // ← ローカル優先
                                exampleJa: exJaLocal ?? exampleJa,   // ← ローカル優先
                                hasDolphin: hasDolphin,
                                hasGold: hasGold,
                                inCollection: .init(get: { isFav },     set: { _ in heartTapped() }),
                                learned:      .init(get: { isChecked }, set: { _ in checkTapped() }),
                                canEditExamples: true,                 // 鉛筆アイコンを表示
                                onEditExample: { isShowingEditor = true } // タップでシートを開く
                            )
                            // ←鉛筆で開く
                            .onAppear {   // ← ここは “引数リストの外” に置く（カッコを閉じてから）
                                // もしローカル編集用の exEnLocal / exJaLocal を使うならここで初期化
                                exEnLocal = exEnLocal ?? exampleEn
                                exJaLocal = exJaLocal ?? exampleJa
                            }
                            
                            Spacer(minLength: 0)
                        } else {
                            Text(reversed ? meaning : word)
                                .font(.system(size: 32, weight: .bold))
                        }
                    }
                    .contentShape(Rectangle())            // 余白タップでも反応
                    .onTapGesture(perform: centerTapped)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // ♡（裏面では非表示）
                    if !expanded {
                        Button(action: heartTapped) {
                            Image(systemName: isFav ? "heart.fill" : "heart")
                                .font(.system(size: 22, weight: .semibold))
                        }
                    }
                }
                // 裏面は縦に少し拡大
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .frame(minHeight: expanded ? rowHeight * 2.0 : rowHeight)
                .animation(.easeInOut(duration: 0.2), value: expanded)
                
                Divider().opacity(0.08)
            }
            .background(.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            .sheet(isPresented: $isShowingEditor) {
                ExampleEditorView(
                    english: exEnLocal ?? exampleEn,
                    japanese: exJaLocal ?? exampleJa
                ) { en, ja in
                    // ① 即反映
                    exEnLocal = en
                    exJaLocal = ja
                    // ② 永続化（単語をキーに保存）
                    ExampleStore.shared.setExample(ExamplePair(en: en, ja: ja), for: word)
                }
            }
        }
    }
    
    // スクロール量取得キー
    private struct ScrollOffsetKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
    }
    

