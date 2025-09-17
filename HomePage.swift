import SwiftUI

// MARK: - モデル
struct WordCard: Identifiable, Hashable {
    let id: String
    let word: String
    let meaning: String
    let pos: PartOfSpeech
}
enum PartOfSpeech: String, CaseIterable, Identifiable,Hashable {
    case noun = "🐻 名詞", verb = "🐈 動詞", adj = "🐇 形容詞", adv = "🦙 副詞"
    var id: String { rawValue }
}

// MARK: - サンプルデータ（後でサーバ連携に置換）
struct SampleDeck {
    static let all: [WordCard] = [
        // noun
        .init(id:"forest", word:"forest", meaning:"森", pos:.noun),
        .init(id:"mushroom", word:"mushroom", meaning:"きのこ", pos:.noun),
        .init(id:"rabbit", word:"rabbit", meaning:"うさぎ", pos:.noun),
        .init(id:"stream", word:"stream", meaning:"小川", pos:.noun),
        .init(id:"leaf", word:"leaf", meaning:"葉", pos:.noun),
        .init(id:"trail", word:"trail", meaning:"小径", pos:.noun),
        // verb
        .init(id:"wander", word:"wander", meaning:"さまよう", pos:.verb),
        .init(id:"whisper", word:"whisper", meaning:"ささやく", pos:.verb),
        .init(id:"gaze", word:"gaze", meaning:"見つめる", pos:.verb),
        .init(id:"glow", word:"glow", meaning:"ほのかに光る", pos:.verb),
        .init(id:"flutter", word:"flutter", meaning:"ひらひら舞う", pos:.verb),
        .init(id:"breathe", word:"breathe", meaning:"息をする", pos:.verb),
        // adj
        .init(id:"gentle", word:"gentle", meaning:"穏やかな", pos:.adj),
        .init(id:"quiet", word:"quiet", meaning:"静かな", pos:.adj),
        .init(id:"bright", word:"bright", meaning:"明るい", pos:.adj),
        .init(id:"mossy", word:"mossy", meaning:"苔むした", pos:.adj),
        .init(id:"curious", word:"curious", meaning:"好奇心旺盛な", pos:.adj),
        .init(id:"shy", word:"shy", meaning:"恥ずかしがりの", pos:.adj),
        // adv
        .init(id:"softly", word:"softly", meaning:"やさしく", pos:.adv),
        .init(id:"slowly", word:"slowly", meaning:"ゆっくり", pos:.adv),
        .init(id:"silently", word:"silently", meaning:"静かに", pos:.adv),
        .init(id:"almost", word:"almost", meaning:"ほとんど", pos:.adv),
        .init(id:"barely", word:"barely", meaning:"かろうじて", pos:.adv),
        .init(id:"truly", word:"truly", meaning:"本当に", pos:.adv),
    ]
    static func filtered(by pos: PartOfSpeech) -> [WordCard] { all.filter { $0.pos == pos } }
}

// MARK: - My Collection 保存
final class MyCollectionStore: ObservableObject {
    @Published private(set) var ids: Set<String> = []
    private let key = "mycollection.ids"
    init() {
        if let saved = UserDefaults.standard.array(forKey: key) as? [String] {
            ids = Set(saved)
        }
    }
    func toggle(_ id: String) {
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        UserDefaults.standard.set(Array(ids), forKey: key)
    }
    func contains(_ id: String) -> Bool { ids.contains(id) }
}

// MARK: - HOME 本体
struct HomePage: View {
    @EnvironmentObject var hw: HomeworkState     // ← 追加
    @State private var showBannerAlert = false   // ← 追加
    @State private var searchText = ""
    // HomePage の struct 内（body の外）に置く
    private let bookmarkColors: [Color] = [.red, .blue, .green, .orange, .purple]
    var body: some View {
        NavigationStack{
            ZStack {
                Color.homeIvory.ignoresSafeArea()
                
                ScrollView {
                }                 // タイトル
                VStack(alignment: .leading, spacing: 4) {
                    
                    NavigationLink {
                        WordCardPage(
                            pos: .adj,
                            baseVariantIndex: hw.variantIndex(for: .adj),
                            items: itemsFor(.adj)
                        )
                    } label: {                        // ← 半角コロン ":" を必ず使用
                        Text("形容詞レッスンへ")
                            .font(.headline)
                            .padding(.vertical, 8)
                    }
                    // …この下に既存のUIが続く…
                }
                HomeworkBanner()
                HomeworkRecentWidget()
                
                HStack(spacing: 8) {
                    
                    Text("Words' Forest")
                        .font(.system(size: 34, weight: .bold))
                    Text("🏠")
                        .font(.system(size: 34))
                        .accessibilityLabel("ホーム")
                }
                Text("A gentle vocabulary journey")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            // 🔍 検索（←タイトルの直後に置く）
            HStack(spacing: 8) {
                TextField("単語を検索（英語・日本語）", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                NavigationLink("検索") {
                    POSFlashcardView(
                        title: "検索結果",
                        cards: SampleDeck.all.filter { c in
                            let q = searchText.trimmingCharacters(in: .whitespaces)
                            guard !q.isEmpty else { return false }
                            return c.word.localizedCaseInsensitiveContains(q)
                            || c.meaning.localizedCaseInsensitiveContains(q)
                        },
                        accent: .gray.opacity(0.6),
                        animalName: "adj_rabbit_gray"
                    )
                }
                .disabled(searchText.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(ColoredPillButtonStyle(color: .blue))
            }
            .padding(.top, 12)
            
            // 『単語カード学習』各品詞へ
            VStack(alignment: .leading, spacing: 8) {
                Text("『単語カード学習』各品詞へ").font(.headline)
                
                let poses = Array(PartOfSpeech.allCases)
                ForEach(poses.indices, id: \.self) { i in
                    let pos = poses[i]

                    NavigationLink {
                        // ← ここで遷移先を“直接”つくる方式（確実に動く）
                        POSFlashcardView(
                            title: pos.rawValue,                                  // 🐻は付けない
                            cards: Array(SampleDeck.filtered(by: pos).prefix(4)),
                            accent: accentFor(pos),
                            animalName: animalNameFor(pos)
                        )
                    } label: {
                        HStack {
                            Text(pos.rawValue).foregroundStyle(.blue)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
                // 🔖 栞（色四角それぞれ遷移）
                HStack(spacing: 10) {
                    Text("🔖 栞へ").font(.subheadline)
                    ForEach(bookmarkColors, id: \.self) { c in
                        BookmarkColorItem(color: c)
                    }
                }
                
                // 🍄 My Collection
                NavigationLink("🍄 My Collection（覚えにくい単語）") {
                    MyCollectionView()
                }
                .buttonStyle(ColoredPillButtonStyle(color: Color.pink))
                
                // 🐺 コラムページ
                NavigationLink("🐺 コラムページ（ColumnPage）") {
                    ColumnPage()
                }
                .buttonStyle(ColoredPillButtonStyle(color: Color.indigo))
                
                Spacer(minLength: 8) // …既存のセクションたち…
            }
            .padding()// ← VStackへのパディング
            
        } // ← NavigationStack の閉じカッコ
        
        .navigationDestination(for: PartOfSpeech.self) { pos in
            POSFlashcardView(
                title: pos.rawValue,  // 🐻は付けない。付けるなら遷移先だけで
                cards: Array(SampleDeck.filtered(by: pos).prefix(4)),
                accent: accentFor(pos),
                animalName: animalNameFor(pos)
            )
        }
    }// ← body の閉じカッコ（ここは1個だけ！）
    // MARK: - Helpers (bodyの外)
    private func itemsFor(_ pos: PartOfSpeech) -> [WordItem] {
        // SampleDeck.filtered(by:) が無い場合でも動く安全版
        let list = SampleDeck.all.filter { $0.pos == pos }
        return Array(list.prefix(12)).map { WordItem(text: $0.word) }
    }
    // VStack（中身）ここまで
    
    
    //            .alert("⚠️ Wi-Fi環境ではありません", isPresented: $showCellularAlert) {
    //                Button("キャンセル", role: .cancel) {}
    //                Button("取得する（通信量がかかります）", role: .destructive) {
    //                    performRefresh(allowCellular: true)
    //                }
    //            } message: {
    //                Text("Wi-Fiではないため、通信量を消費します。取得しますか？")
    //            }
    
    // 画像名を品詞ごとに返す（HomePage の中・body の外）
    private func animalNameFor(_ pos: PartOfSpeech) -> String {
        switch pos {
        case .noun: return "noun_bear_brown"
        case .verb: return "verb_cat_gray"
        case .adj:  return "adj_rabbit_white"
        case .adv:  return "adv_alpaca_ivory"
        }
    }
    // MARK: - ダミー更新（HomePage の“中・bodyの外”）
    //   private func performRefresh(allowCellular: Bool = false) {
    //      guard !isUpdating else { return }
    //      isUpdating = true
    //      DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
    //         pendingCount = 0
    //          lastUpdated = Date()
    //           isUpdating = false
    //        }
    //    }
    // ← ここで **HomePage を閉じる**（最後の1個だけ）
    // 品詞→アクセント色（後でHexに差し替え可）
    func accentFor(_ pos: PartOfSpeech) -> Color {
        switch pos {
        case .noun:       return Color(red: 0.96, green: 0.78, blue: 0.83) // #F4C7D3 近似
        case .verb:       return Color(red: 0.63, green: 0.75, blue: 0.90) // 動詞系ブルー近似
        case .adj:        return Color(red: 0.72, green: 0.89, blue: 0.78) // #B7E4C7 近似
        case .adv:        return Color(red: 1.00, green: 0.95, blue: 0.69) // #FFF3B0 近似
        }
    }
    struct ColumnPage: View {
        var body: some View {
            ColumnTOCView()
        }
    }
    struct MyCollectionView: View {
        var body: some View {
            VStack(spacing: 16) {
                Text("My Collection")
                    .font(.title3).bold()
                
                Text("ここに“覚えにくい単語”が並びます。\n今はダミー表示です。")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // 後で本実装に差し替える:
                // WordListView(title: "My Collection", cards: picked)
            }
            .padding()
            .navigationTitle("My Collection")
        }
    }
    // ダミー更新（のちに UpdateCenter へ差し替え）
    //private func performRefresh(allowCellular: Bool = false) {
    //  guard !isUpdating else { return }
    // isUpdating = true
    // DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
    //   pendingCount = 0
    //  lastUpdated = Date()
    //  isUpdating = false
    //  }
    //}
    //} // ← ここで struct HomePage を閉じる（最後の1個だけ）
    
    // MARK: - SampleDeck 拡張
}
        extension SampleDeck {
            static var nouns: [WordCard] {
                all.filter { $0.pos == .noun }
            }
            static var adjectives: [WordCard] {
                all.filter { $0.pos == .adj }
            }
        }
        // ====== ここからは “body の外側” に置く宣言たち ======
        
        // MARK: - 索引／コラム（青リンク版）
        struct IndexPage: View {
            var body: some View {
                List {
                    Section("アルファベット順") {
                        NavigationLink {
                            AlphabetIndexView()
                        } label: {
                            Text("A … Z（実装予定）")
                                .foregroundColor(.blue)
                        }
                    }
                    Section("ひらがな五十音順") {
                        NavigationLink {
                            KanaIndexView()
                        } label: {
                            Text("あ … ん（実装予定）")
                                .foregroundColor(.blue)
                        }
                    }
                    Section("コラム目次") {
                        NavigationLink {
                            ColumnTOCView()
                        } label: {
                            Text("No. とタイトル一覧（実装予定）")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("索引ページ")
            }
        }
        
        struct AlphabetIndexView: View {
            var body: some View {
                Text("アルファベット順の索引ページ（実装予定）")
                    .padding()
                    .navigationTitle("A … Z")
            }
        }
        
        struct KanaIndexView: View {
            var body: some View {
                Text("ひらがな索引ページ（実装予定）")
                    .padding()
                    .navigationTitle("あ … ん")
            }
        }
        
        struct ColumnTOCView: View {
            var body: some View {
                Text("コラム目次（No. とタイトル一覧・実装予定）")
                    .padding()
                    .navigationTitle("コラム目次")
            }
        }
        
        
        // MARK: - 栞：色四角の1アイテム（押して遷移）
        struct BookmarkColorItem: View {
            let color: Color
            var body: some View {
                NavigationLink(destination: BookmarkPage(color: color)) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
        }
        
        // MARK: - 単語リスト（品詞別/検索結果共通）
        /*    struct POSFlashcardView: View {
         let title: String
         let cards: [WordCard]
         // @EnvironmentObject var collection: MyCollectionStore
         @State private var tempPicked: Set<String> = []
         var body: some View {
         List {
         ForEach(cards) { card in
         HStack {
         VStack(alignment: .leading, spacing: 4) {
         Text(card.word).font(.headline)
         Text(card.meaning).foregroundColor(.secondary)
         }
         Spacer()
         Button {
         //   collection.toggle(card.id)
         // } label: {
         // Image(systemName: //collection.contains(card.id) ? //
         //"heart.fill" : "heart")
         
         if tempPicked.contains(card.id) {
         tempPicked.remove(card.id)
         } else {
         tempPicked.insert(card.id)
         }
         } label: {
         Image(systemName: tempPicked.contains(card.id) ? "heart.fill" : "heart")
         }
         .buttonStyle(.borderless)
         .foregroundColor(.pink)
         
         }
         .padding(.vertical, 4)
         }
         }
         .navigationTitle(title)
         }
         }
         */
        // MARK: - My Collection 画面
        //struct MyCollectionView: View {
        var body: some View {
            VStack(spacing: 16) {
                Text("My Collection").font(.title3).bold()
                Text("ここに“覚えにくい単語”が並びます。\n今はダミー表示です。")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            .padding()
            .navigationTitle("My Collection")
        }
        //}
        
        // MARK: - 栞ページ（仮）
        struct BookmarkPage: View {
            let color: Color
            var body: some View {
                ZStack {
                    color.opacity(0.12).ignoresSafeArea()
                    Text("この色の栞ページです").padding()
                }
                .navigationTitle("栞ページ")
            }
        }
        
    

