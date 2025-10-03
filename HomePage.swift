import SwiftUI

struct HomePage: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var hw: HomeworkState
    
    @State private var searchText = ""
    @State private var showBannerAlert = false
    @State private var showRecent = true
    // 栞は今は非表示（必要になったら true）
    private let showBookmarks = false
    private let bookmarkColors: [Color] = [.red, .blue, .green, .orange, .purple]
    
    var body: some View {
        ZStack {
            Color.homeIvory.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // ① タイトル（ナビタイトルは使わない）
                    HStack(spacing: 8) {
                        Spacer()
                        Text("Home Page")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.primary)
                        Text("🏠")
                            .font(.system(size: 28))
                            .accessibilityLabel("ホーム")
                        Spacer()
                    }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    
                    
                    // ② 検索
                    HStack(spacing: 8) {
                        TextField("単語を検索（英語・日本語）", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                        
                        NavigationLink("検索") {
                            let q = searchText.trimmingCharacters(in: .whitespaces)
                            
                            // 全品詞のサンプルをまとめる（← ここがポイント）
                            let allSamples = PartOfSpeech.allCases.flatMap { SampleDeck.filtered(by: $0) }
                            
                            let cards = allSamples.filter { c in
                                !q.isEmpty && (
                                    c.word.localizedCaseInsensitiveContains(q) ||
                                    c.meaning.localizedCaseInsensitiveContains(q)
                                )
                            }
                            
                            POSFlashcardView(
                                title: "検索結果",
                                cards: cards,
                                accent: .gray.opacity(0.6),
                                background: Color(.systemGray6),
                                animalName: "adj_rabbit_gray",
                                reversed: false
                            )
                        }
                        .disabled(searchText.trimmingCharacters(in: .whitespaces).isEmpty)
                        .buttonStyle(ColoredPillButtonStyle(color: .blue))
                    }
                    
                    // ③ 今サイクル / 新着（既存のウィジェットをそのまま）
                    Group {
                        HomeworkBanner()
                        // 🆕 新着情報（直近4件）
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("新着情報（直近4件）", systemImage
                                        : "sparkles")
                                    .font(.headline)
                                Spacer()
                                Button(showRecent ? "隠す" : "表示") {
                                    withAnimation(.snappy) { showRecent.toggle() }
                                }
                                NavigationLink("履歴をすべて見る") {
                                    HistoryAllView()           // ← 仮の一覧画面（下に定義を置きます）
                                }
                                .font(.subheadline)
                            }
                            
                            if showRecent {
                                HomeworkRecentWidget()
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(.vertical, 4)
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
                        
                        // ⑥ その他ページ（Stub。あとで本物に差し替え）
                        NavigationLink("✏️ スペリング・チャレンジ") { SpellingChallengeView() }
                            .buttonStyle(ColoredPillButtonStyle(color: .purple))
                        
                        NavigationLink("🍄 My Collection（覚えにくい単語）") { MyCollectionView() }
                            .buttonStyle(ColoredPillButtonStyle(color: .pink))
                        
                        NavigationLink("🐺 コラムページ（ColumnPage）") { ColumnPage() }
                            .buttonStyle(ColoredPillButtonStyle(color: .indigo))
                        
                        Spacer(minLength: 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            // ← .navigationTitle は付けない（表紙と重複防止）
        }
    }
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
       private struct MyCollectionView: View {
           var body: some View { Text("My Collection stub") }
       }
       private struct ColumnPage: View {
           var body: some View { Text("Column Page stub") }
       }

       // 🆕 履歴一覧（仮）
       private struct HistoryAllView: View {
           var body: some View {
               List(0..<8) { _ in
                   HStack(alignment: .top, spacing: 12) {
                       Image(systemName: "square.fill")
                           .foregroundStyle(.green)
                       VStack(alignment: .leading, spacing: 4) {
                           Text("2025/10/02").font(.caption).foregroundStyle(.secondary)
                           Text("宿題：名詞＋形容詞（24語）")
                       }
                   }
                   .padding(.vertical, 4)
               }
               .navigationTitle("宿題の履歴")
           }
       }
   }
