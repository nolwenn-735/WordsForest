import SwiftUI

struct HomePage: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var hw: HomeworkState
    
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool
    @State private var showBannerAlert = false
    @State private var showRecent = false
    @State private var favCount     = HomeworkStore.shared.favoritesCount
    @State private var learnedCount = HomeworkStore.shared.learnedCount 
    @State private var showSpellingMenu = false
    
    private var favBadgeText: String { favCount > 99 ? "99+" : "\(favCount)" }
    private var learnedBadgeText: String { learnedCount > 99 ? "99+" : "\(learnedCount)" }
    
    // 栞は今は非表示（必要になったら true）
    private let showBookmarks = false
    private let bookmarkColors: [Color] = [.red, .blue, .green, .orange, .purple]
   
    var body: some View {
        ZStack {
            Color.homeIvory.ignoresSafeArea()
            //           Color(.systemGroupedBackground)
            //                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    
                    // ① タイトル（ナビタイトルは使わない）
                    HStack(spacing: 8) {
                        Spacer()
                        Text("Home Page")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.primary)
                        Text("🏡")
                            .font(.system(size: 34))
                            .accessibilityLabel("ホーム")
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    
                    // ② 検索
                    HStack(spacing: 8) {
                        TextField("単語を検索（英語・日本語）", text: $searchText)
                            .keyboardType(.default)//(.asciiCapable)//英数、かなの問題
                        
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)   // ← 先頭が勝手に大文字にならない
                            .autocorrectionDisabled()              // ← 自動修正オフ
                            .textContentType(.none)                // ← 「Auto Fill」候補を出さない
                            .focused($searchFocused)
                            .submitLabel(.search)
                            .onAppear { searchText = "" }
                        
                        NavigationLink {
                            // 入力文字列を整える
                            let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                            let isEmpty = q.isEmpty

                            // 検索対象（先生の登録 + サンプル）を統合＆重複除去
                            let searchPOS: [PartOfSpeech] = PartOfSpeech.homeworkCases + [.others]

                            let userCards: [WordCard] = searchPOS.flatMap { HomeworkStore.shared.list(for: $0) }
                            let sampleCards: [WordCard] = searchPOS.flatMap { SampleDeck.filtered(by: $0) }
                            let all: [WordCard] = (userCards + sampleCards)
                                .uniqued(by: { "\($0.pos)|\($0.word.lowercased())|\($0.meaning)" })
                            // 条件：英単語 / 日本語 / 不規則動詞の形
                            let cards: [WordCard] = all.filter { c in
                                guard !isEmpty else { return false }
                                if c.word.localizedCaseInsensitiveContains(q) { return true }
                                if c.meaning.localizedCaseInsensitiveContains(q) { return true }
                                let forms = IrregularVerbBank.forms(for: c.word) ?? []
                                return forms.contains { $0.localizedCaseInsensitiveContains(q) }
                            }

                            POSFlashcardView(
                                title: "検索結果",
                                cards: cards,
                                accent: .gray.opacity(0.6),
                                background: Color(.systemGray6),
                                animalName: "index_raccoon",                                
                                reversed: false,
                                onEdit: { _ in },
                                perRowAccent: true
                            )
                        } label: {
                            Text("検索")
                        }
    
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                    .buttonStyle(.automatic)
                    .onAppear { searchFocused = false }
                    .scrollDismissesKeyboard(.interactively)
                        
                        // ③ 今サイクル / 新着（既存のウィジェットをそのまま）
                    Group {
                        HomeworkBanner()
                            .overlay(alignment: .topTrailing) {
                                WeeklySetMiniButton()              // ← 右上に重ねる
                                    .padding(.top, 8)
                                    .padding(.trailing, 8)
                            }
                    }
                    // 🆕 新着情報（直近8件）
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("🆕 新着情報（直近8件）")
                                .font(.headline)

                            Button(showRecent ? "隠す" : "表示") {
                                withAnimation(.snappy) { showRecent.toggle() }
                            }
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.blue)

                            Spacer()   // ← Spacer をここに移動
                        }

                        if showRecent {
                            HomeworkRecentWidget()
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                     
                            // ここから次のセクション（別の VStack でOK）
                            // ④ 『単語カード学習』各品詞へ（push方式）
                            VStack(alignment: .leading, spacing: 8) {
                                Text("『単語カード学習』各品詞へ").font(.headline)
                                
                                posRow(PartOfSpeech.noun, title: "🐻名詞",  color: .pink)
                                posRow(PartOfSpeech.verb, title: "🐈動詞",  color: .blue)
                                posRow(PartOfSpeech.adj,  title: "🐇形容詞", color: .green)
                                posRow(PartOfSpeech.adv,  title: "🦙副詞",  color: .orange)
                            }
                            
                            // ⑤ 栞（今は非表示）
                            if showBookmarks {
                                HStack(spacing: 10) {
                                    Text("🔖 栞へ").font(.subheadline)
                                    ForEach(bookmarkColors, id: \.self) { color in
                                        BookmarkColorItem(color: color)
                                    }
                                }
                            }
                            // （中略）VStack(spacing: 8) {

                            

                            Button {
                                showSpellingMenu = true
                            } label: {
                                Text("✏️ スペリング・チャレンジ")
                            }
                            .buttonStyle(ColoredPillButtonStyle(color: .purple, size: .compact, alpha: 0.20))
                            .sheet(isPresented: $showSpellingMenu) {
                                SpellingChallengeMenuView()
                            }
                            // My Collection
                            NavigationLink("💗  My Collection（覚えにくい単語）") {
                                MyCollectionView()
                            }
                            .buttonStyle(ColoredPillButtonStyle(color: .pink, size: .compact, alpha: 0.20))
                            .overlay(alignment: .topTrailing) {
                                if favCount > 0 {
                                    Text(favBadgeText)
                                        .font(.caption2).bold()
                                        .padding(6)
                                        .background(Circle().fill(.red))
                                        .foregroundColor(.white)
                                        .padding(.top, 6)                  // ← 内側へ寄せる（上）
                                        .padding(.trailing, 10)
                                }
                            }

                            // 覚えたBOX
                            NavigationLink {
                                LearnedBoxView()
                            } label: {
                                Text("📦  覚えたBOX")
                            }
                            .buttonStyle(ColoredPillButtonStyle(color: .green, size: .compact, alpha: 0.20))
                            .overlay(alignment: .topTrailing) {
                                if learnedCount > 0 {
                                    Text(learnedBadgeText)
                                        .font(.caption2).bold()
                                        .padding(6)
                                        .background(Circle().fill(.green))
                                        .foregroundColor(.white)
                                        .padding(.top, 6)                  // ← 内側へ寄せる（上）
                                        .padding(.trailing, 10)
                                }
                            }

                            // コラムページはそのまま
                    HStack(spacing: 8) {
                        // 🐺 コラム（薄い indigo、左下マスコット想定）
                        NavigationLink("🐺 コラム ") {
                            ColumnIndexView()
                                .background(Color.indigo.opacity(0.10))
                        }
                        .buttonStyle(ColoredPillButtonStyle(color: .indigo, size: .compact, alpha: 0.20))

                        // 🦌 その他品詞（薄い紫、右下マスコット）
                        NavigationLink("🦌 その他品詞") {
                            let pos = PartOfSpeech.others
                            let accent = pos.accentColor
                            let animal = pos.animalName(forCycle: hw.history.count)

                            POSFlashcardListView(
                                pos: .others,
                                accent: accent,
                                animalName: animal
                            )
                        }
                        .buttonStyle(ColoredPillButtonStyle(color: .orange, size: .compact, alpha: 0.20))
                    }

                            // } // VSTack 終わり
                                Spacer(minLength: 8)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 2)
                        .padding(.bottom,8)
                    }
        .onAppear {
            // 初期同期
            favCount     = HomeworkStore.shared.favoritesCount
            learnedCount = HomeworkStore.shared.learnedCount
        }

        // ▼ここを置き換え
        .onReceive(NotificationCenter.default.publisher(for: .favoritesDidChange)) { _ in
            favCount = HomeworkStore.shared.favoritesCount
        }
        .onReceive(NotificationCenter.default.publisher(for: .learnedDidChange)) { _ in
            learnedCount = HomeworkStore.shared.learnedCount
        }
        // iPhone のホームインジケータに被らないための“下マージン”
                    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 12) }
                }
                // ← .navigationTitle は付けない（表紙と重複防止）
}
        
    

    // ===== body の外に出す箱 =====
    extension HomePage {
        // MARK: - Row helper（push 方式）
        @ViewBuilder
        private func posRow(_ pos: PartOfSpeech, title: String, color: Color) -> some View {
            Button { router.push(pos) } label: {
                HStack {
                    Text(title).foregroundStyle(color)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        
        // MARK: - 小物（栞アイコン）
        private struct BookmarkColorItem: View {
            let color: Color
            var body: some View {
                Circle().fill(color).frame(width: 24, height: 24)
            }
        }
        
        // MARK: - Stub 画面（本物ができたら差し替え）
        private struct SpellingChallengeView: View {
            var body: some View { Text("Spelling Challenge stub") }
        }
        
        // My Collection 一覧
        private struct MyCollectionView: View {
            @State private var refreshID = UUID()

            var body: some View {
                let cards = HomeworkStore.shared.favoriteList()
                Group {
                    if cards.isEmpty {
                        ContentUnavailableView("まだありません", systemImage: "heart")
                    } else {
                        POSFlashcardView(
                            title: "My Collection",
                            cards: cards,
                            accent: .pink,
                            background: Color(.systemBackground),
                            animalName: "mycol_flowers",
                            reversed: false,
                            onEdit: { _ in },
                            onDataChanged: { refreshID = UUID() },   // ← これ重要！
                            perRowAccent: true                       // 行ごと品詞色
                        )
                        .id(refreshID)                               // ← 再評価のキー
                    }
                }
                .navigationTitle("My Collection")
            }
        }

        // 覚えたBOX 一覧
        private struct LearnedBoxView: View {
            @State private var refreshID = UUID()

            var body: some View {
                let cards = HomeworkStore.shared.learnedList()
                Group {
                    if cards.isEmpty {
                        ContentUnavailableView("まだありません", systemImage: "checkmark.circle")
                    } else {
                        POSFlashcardView(
                            title: "覚えたBOX",
                            cards: cards,
                            accent: .green,
                            background: Color(.systemBackground),
                            animalName: "mycol_berry",
                            reversed: false,
                            onEdit: { _ in },
                            onDataChanged: { refreshID = UUID() },     // ← 重要！
                            perRowAccent: true
                        )
                        .id(refreshID)
                    }
                }
                .navigationTitle("覚えたBOX")
            }
        }
        
        private struct ColumnPage: View {
            var body: some View { Text("Column Page stub") }
        }
        
        // 🗂 宿題の履歴 一覧（新しい順）
        // 🆕 履歴一覧（本番）
        private struct HistoryAllView: View {
            @EnvironmentObject var hw: HomeworkState

            // 日付表示用フォーマッタ（上の方に static で用意）
            private static let dateFormatter: DateFormatter = {
                let df = DateFormatter()
                df.dateFormat = "yyyy/MM/dd"
                return df
            }()

            var body: some View {
                // ★ 最新から最大8件だけ取り出し
                let entries = Array(hw.history.prefix(8))

                List(entries) { entry in
                    HStack(alignment: .top, spacing: 12) {
                        // 左の🟩アイコン部分
                        Image(systemName: "square.fill")
                            .foregroundStyle(.gray)

                        // 右側の本文
                        VStack(alignment: .leading, spacing: 4) {
                            // 上段：日付
                            Text(Self.dateFormatter.string(from: entry.date))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            // 下段：宿題の内容
                            Text(entry.titleLine)
                                .font(.body)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .navigationTitle("宿題の履歴")
            }
        }
        // 🆕 新着情報（直近8件）カード
        private struct HomeworkRecentWidget: View {
            @EnvironmentObject var hw: HomeworkState
            
            // 日付表示用
            private static let df: DateFormatter = {
                let f = DateFormatter()
                f.dateFormat = "yyyy/MM/dd"
                return f
            }()
            
            var body: some View {
                // history は新しい順に先頭に入っているので、先頭4件だけ取り出す
                let items = Array(hw.history.prefix(4))
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items) { entry in
                        HStack(alignment: .top, spacing: 8) {
                            // 左のステータス色（🟩 ⏸️ ⛔️）
                            Text(entry.statusIcon)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Self.df.string(from: entry.date))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text("宿題：\(entry.pairLabel)（\(entry.wordsCount)語）")
                                    .font(.subheadline)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // 白い小ウィンドウの中にある「履歴をすべて見る」
                    NavigationLink("履歴をすべて見る") {
                        HistoryAllView()
                            .environmentObject(hw)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 4)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
            }
        }
    }
    
private struct WeeklySetMiniButton: View {
    @EnvironmentObject var hw: HomeworkState

    var body: some View {
        let p = hw.currentPair

        NavigationLink {
            WeeklySetView(pair: p)
                .environmentObject(hw)
        } label: {
            Text("🗓️ 今回分へ →")
                .font(.system(size: 16, weight: .semibold))   // ← フォント大きめに
                .foregroundColor(.blue)                       // ← 青文字に強制
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.thinMaterial, in: Capsule())      // ← カプセル形ボタン
        }
        .buttonStyle(.plain)
    }
}
  
 
