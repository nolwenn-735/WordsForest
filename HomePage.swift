import SwiftUI

struct HomePage: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var hw: HomeworkState

    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

    @State private var showRecent = false
    @State private var showSpellingMenu = false

    @State private var favCount = HomeworkStore.shared.favoritesCount
    @State private var learnedCount = HomeworkStore.shared.learnedCount

    private var favBadgeText: String { favCount > 99 ? "99+" : "\(favCount)" }
    private var learnedBadgeText: String { learnedCount > 99 ? "99+" : "\(learnedCount)" }

    var body: some View {
        ZStack {
            Color.homeIvory.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {

                    // MARK: タイトル
                    HStack {
                        Spacer()
                        Text("Home Page")
                            .font(.system(size: 34, weight: .bold))
                        Text("🏡")
                            .font(.system(size: 34))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    // MARK: 検索
                    searchSection

                    // MARK: 今サイクル
                    HomeworkBanner()
                        .overlay(alignment: .topTrailing) {
                            WeeklySetMiniButton()
                                .padding(.top, 8)
                                .padding(.trailing, 8)
                        }

                    // MARK: 新着
                    recentSection

                    // MARK: 品詞別レッスン
                    Text("『単語カード学習』各品詞へ")
                        .font(.headline)
                        .padding(.leading, 4)

                    posRow(.noun, title: "🐻名詞", color: .pink)
                    posRow(.verb, title: "🐈動詞", color: .blue)
                    posRow(.adj, title: "🐇形容詞", color: .green)
                    posRow(.adv, title: "🦙副詞", color: .orange)

                    // MARK: スペリング
                    Button {
                        showSpellingMenu = true
                    } label: {
                        Text("✏️ スペリング・チャレンジ")
                    }
                    .buttonStyle(ColoredPillButtonStyle(color: .purple, size: .compact, alpha: 0.20))
                    .sheet(isPresented: $showSpellingMenu) {
                        SpellingChallengeMenuView()
                    }

                    // MARK: My Collection
                    NavigationLink {
                        MyCollectionRootView()
                    } label: {
                        Text("💗  My Collection（覚えにくい単語）")
                    }
                    .buttonStyle(ColoredPillButtonStyle(color: .pink, size: .compact, alpha: 0.20))
                    .badgeOverlay(count: favCount, text: favBadgeText, color: .red)

                    // MARK: 覚えたBOX
                    NavigationLink {
                        LearnedBoxRootView()
                    } label: {
                        Text("📦  覚えたBOX")
                    }
                    .buttonStyle(ColoredPillButtonStyle(color: .green, size: .compact, alpha: 0.20))
                    .badgeOverlay(count: learnedCount, text: learnedBadgeText, color: .green)

                    // MARK: その他品詞
                    HStack {
                        NavigationLink("🐺 コラム ") {
                            ColumnIndexView()
                        }
                        .buttonStyle(ColoredPillButtonStyle(color: .indigo, size: .compact, alpha: 0.20))

                        NavigationLink("🦌 その他品詞") {
                            POSFlashcardListView(
                                pos: .others,
                                accent: .purple,
                                animalName: PartOfSpeech.others.animalName(forCycle: hw.variantIndex(for: .others))
                            )
                        }
                        .buttonStyle(ColoredPillButtonStyle(color: .orange, size: .compact, alpha: 0.20))
                    }

                    // デバッグ
                    NavigationLink("🛠️ 宿題セット修復（デバッグ用）") {
                        RepairHomeworkView()
                    }

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 12)
                .padding(.top, 2)
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            favCount = HomeworkStore.shared.favoritesCount
            learnedCount = HomeworkStore.shared.learnedCount
        }
        .onReceive(NotificationCenter.default.publisher(for: .favoritesDidChange)) { _ in
            favCount = HomeworkStore.shared.favoritesCount
        }
        .onReceive(NotificationCenter.default.publisher(for: .learnedDidChange)) { _ in
            learnedCount = HomeworkStore.shared.learnedCount
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 12) }
    }
}

// MARK: - 品詞ボタン（名詞・動詞・形容詞・副詞）
extension HomePage {
    @ViewBuilder
    func posRow(_ pos: PartOfSpeech, title: String, color: Color) -> some View {
        Button {
            router.push(pos)
        } label: {
            HStack {
                Text(title).foregroundStyle(color)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 検索セクション
private extension HomePage {
    var searchSection: some View {
        HStack(spacing: 8) {
            TextField("単語を検索（英語・日本語）", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($searchFocused)
                .padding(10)
                .background(.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)

            NavigationLink("検索") {
                let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                let cards = searchAllCards(query: q)

                POSFlashcardView(
                    title: "検索結果",
                    cards: cards,
                    accent: .gray.opacity(0.6),
                    background: Color(.systemGray6),
                    animalName: "index_raccoon_stand",
                    reversed: false,
                    onEdit: { _ in }
                )
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }
}
// MARK: - 新着
private extension HomePage {
    var recentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("🆕 新着情報（直近8件）")
                    .font(.headline)

                Button(showRecent ? "隠す" : "表示") {
                    withAnimation(.snappy) { showRecent.toggle() }
                }
                .font(.callout.weight(.semibold))
                .foregroundColor(.blue)

                Spacer()
            }

            if showRecent {
                HomeworkRecentWidget()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

// MARK: - Badge Overlay modifier
private extension View {
    func badgeOverlay(count: Int, text: String, color: Color) -> some View {
        self.overlay(alignment: .topTrailing) {
            if count > 0 {
                Text(text)
                    .font(.caption2).bold()
                    .padding(6)
                    .background(Circle().fill(color))
                    .foregroundColor(.white)
                    .padding(.top, 6)
                    .padding(.trailing, 10)
            }
        }
    }
}

// MARK: - MyCollection / LearnedBox ルート
private struct MyCollectionRootView: View {
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
                    onDataChanged: { refreshID = UUID() },
                    perRowAccent: true
                )
                .id(refreshID)
            }
        }
        .navigationTitle("My Collection")
    }
}

// MARK: - 検索ロジック
private extension HomePage {
    func searchAllCards(query q: String) -> [WordCard] {
        guard !q.isEmpty else { return [] }

        // 検索対象となる品詞
        let allPOS = PartOfSpeech.homeworkCases + [.others]

        // HomeworkStore と SampleDeck の両方を検索対象にする
        let cards =
            allPOS.flatMap { HomeworkStore.shared.list(for: $0) } +
            allPOS.flatMap { SampleDeck.filtered(by: $0) }

        // 重複を排除しつつ検索
        return cards
            .uniqued(by: { "\($0.pos)|\($0.word.lowercased())|\($0.meaning)" })
            .filter { c in
                c.word.localizedCaseInsensitiveContains(q) ||
                c.meaning.localizedCaseInsensitiveContains(q) ||
                (IrregularVerbBank.forms(for: c.word) ?? []).contains(where: {
                    $0.localizedCaseInsensitiveContains(q)
                })
            }
    }
}

private struct LearnedBoxRootView: View {
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
                    onDataChanged: { refreshID = UUID() },
                    perRowAccent: true
                )
                .id(refreshID)
            }
        }
        .navigationTitle("覚えたBOX")
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
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.thinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}





