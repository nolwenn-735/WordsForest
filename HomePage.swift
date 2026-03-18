//HomePage.swift

import SwiftUI
import UniformTypeIdentifiers

struct HomePage: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var hw: HomeworkState
    @EnvironmentObject private var teacher: TeacherMode 
    
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool
    @State private var submittedSearchText = ""
    
    @State private var confirmEntry: HomeworkEntry?
    @State private var pushEntry: HomeworkEntry?
    
    @State private var showRecent = false
    @State private var showSpellingMenu = false

    @State private var favCount = HomeworkStore.shared.collectionFavoritesCount
    @State private var learnedCount = HomeworkStore.shared.collectionLearnedCount
    @StateObject private var columnStore = ColumnStore.shared
    @State private var showingManifestImporter = false
    @State private var manifestImportErrorMessage: String? = nil
    @State private var showingHomeworkImporter = false
    @State private var homeworkImportErrorMessage: String? = nil
    

    @AppStorage("manifest_latestHomeworkPayloadID") private var manifestLatestHomeworkPayloadID: String = ""
    @AppStorage("manifest_latestHomeworkDateText") private var manifestLatestHomeworkDateText: String = ""
    @AppStorage("manifest_latestHomeworkLabel") private var manifestLatestHomeworkLabel: String = ""
    @AppStorage("manifest_latestHomeworkCount") private var manifestLatestHomeworkCount: Int = 0
    @AppStorage("manifest_latestColumnArticleID") private var manifestLatestColumnArticleID: Int = 0
    @AppStorage("manifest_updatedAtISO") private var manifestUpdatedAtISO: String = ""
    @AppStorage(DefaultsKeys.lastImportedHomeworkPayloadID)
    
    private var lastImportedHomeworkPayloadID: String = ""
    
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
                        .padding(.horizontal, 4)

                    // MARK: 新着
                    recentSection

                    Group {
                        // MARK: 品詞別レッスン
                        Text("『単語カード学習』各品詞へ")
                            .font(.headline)

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
                        HStack(spacing: 8) {
                            NavigationLink("🐺 コラム ") {
                                ColumnIndexView()
                            }
                            .buttonStyle(ColoredPillButtonStyle(color: .indigo, size: .compact, alpha: 0.20))
                            .overlay(alignment: .trailing) {
                                if columnStore.shouldShowNewBadge() {
                                    Text("🆕")
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(.red.opacity(0.95))
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                        .padding(.trailing, 14)
                                }
                            }

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
                        #if DEBUG
                        NavigationLink("🛠️ 宿題セット修復（デバッグ用）") {
                            DebugCenterView()
                        }
                        #endif
                    }
                    .padding(.horizontal, 6)

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 12)
                .padding(.top, 2)
                .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            favCount = HomeworkStore.shared.collectionFavoritesCount
            learnedCount = HomeworkStore.shared.collectionLearnedCount
        }
        .onReceive(NotificationCenter.default.publisher(for: .favoritesDidChange)) { _ in
            favCount = HomeworkStore.shared.collectionFavoritesCount
        }
        .onReceive(NotificationCenter.default.publisher(for: .learnedDidChange)) { _ in
            learnedCount = HomeworkStore.shared.collectionLearnedCount
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 12) }
        .fileImporter(
            isPresented: $showingManifestImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importSelectedManifestFile(from: url)

            case .failure(let error):
                manifestImportErrorMessage = "新着確認ファイルの読み込みに失敗しました: \(error.localizedDescription)"
                print("❌ manifest picker error:", error)
            }
        }
        .alert(
            "新着確認エラー",
            isPresented: Binding(
                get: { manifestImportErrorMessage != nil },
                set: { if !$0 { manifestImportErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                manifestImportErrorMessage = nil
            }
        } message: {
            Text(manifestImportErrorMessage ?? "")
        }
    }
        
    private func importSelectedManifestFile(from url: URL) {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            let manifest = try JSONDecoder().decode(DeliveryManifest.self, from: data)

            manifestLatestHomeworkPayloadID = manifest.latestHomeworkPayloadID ?? ""
            manifestLatestHomeworkDateText = manifest.latestHomeworkDateText ?? ""
            manifestLatestHomeworkLabel = manifest.latestHomeworkLabel ?? ""
            manifestLatestHomeworkCount = manifest.latestHomeworkCount ?? 0
            manifestLatestColumnArticleID = manifest.latestColumnArticleID ?? 0
            manifestUpdatedAtISO = manifest.updatedAtISO

            manifestImportErrorMessage = nil

            print("✅ manifest imported")
            print("  latestHomeworkPayloadID =", manifestLatestHomeworkPayloadID)
            print("  latestHomeworkDateText =", manifestLatestHomeworkDateText)
            print("  latestHomeworkLabel =", manifestLatestHomeworkLabel)
            print("  latestHomeworkCount =", manifestLatestHomeworkCount)
            print("  latestColumnArticleID =", manifestLatestColumnArticleID)
            print("  updatedAtISO =", manifestUpdatedAtISO)

        } catch {
            manifestImportErrorMessage = "新着確認ファイルの読み込みに失敗しました: \(error.localizedDescription)"
            print("❌ manifest import error:", error)
        }
    }
}

struct WeeklySetMiniButton: View {
    @EnvironmentObject var hw: HomeworkState
    @EnvironmentObject var teacher: TeacherMode
    
    var body: some View {
        HStack(spacing: 10) {
            
            NavigationLink {
                WeeklySetEntryView(pair: hw.currentPair)
                    .environmentObject(hw)
                    .environmentObject(teacher)
                    .id(hw.currentPair)
            } label: {
                Text("🗓️今回分へ")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: Capsule())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .allowsTightening(true)
            }
            .buttonStyle(.plain)                       
        }
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
                .submitLabel(.done)
                .onSubmit {
                    searchFocused = false
                }
                .padding(10)
                .background(.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)

            NavigationLink {
                let cards = searchAllCards(query: submittedSearchText)

                POSFlashcardView(
                    title: "検索結果",
                    cards: cards,
                    accent: .gray.opacity(0.6),
                    background: Color(.systemGray6),
                    animalName: "index_raccoon_stand"
                )
            } label: {
                Text("検索")
            }
            .simultaneousGesture(TapGesture().onEnded {
                submittedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                searchText = ""
                searchFocused = false
            })
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("閉じる") {
                    searchFocused = false
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }
}
// MARK: - 新着
private extension HomePage {
    var recentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("📚新しい宿題")
                            .font(.headline)
                        
                        Button {
                            showingManifestImporter = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("🔔")
                                Text("新着確認")
                            }
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.10), in: Capsule())
                            .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text("🆕新しい宿題が届いていないか確認しましょう")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Button(showRecent ? "隠す" : "表示") {
                    withAnimation(.snappy) { showRecent.toggle() }
                }
                .font(.callout.weight(.semibold))
                .foregroundColor(.blue)
                
                Spacer()
            }
            
            if showRecent {
                VStack(spacing: 10) {
                    if hasUnclaimedHomeworkFromManifest {
                        manifestHomeworkPreviewCard
                    }
                    
                    HomeworkRecentWidget(
                        confirmEntry: $confirmEntry,
                        onImportTap: {
                            showingHomeworkImporter = true
                        }
                    )
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .navigationDestination(item: $pushEntry) { e in
            HomeworkHistoryWordsView(entry: e)
                .environmentObject(hw)
        }
        .alert(
            "この日の宿題を見ますか？",
            isPresented: .constant(confirmEntry != nil),
            presenting: confirmEntry
        ) { e in
            Button("見る") {
                pushEntry = e
                confirmEntry = nil
            }
            Button("キャンセル", role: .cancel) {
                confirmEntry = nil
            }
        } message: { _ in
            Text("この日の宿題を表示します。")
        }
    }
    private var hasUnclaimedHomeworkFromManifest: Bool {
        !manifestLatestHomeworkPayloadID.isEmpty &&
        manifestLatestHomeworkPayloadID != lastImportedHomeworkPayloadID &&
        !manifestLatestHomeworkDateText.isEmpty &&
        !manifestLatestHomeworkLabel.isEmpty &&
        manifestLatestHomeworkCount > 0
    }
    
    private var manifestHomeworkPreviewCard: some View {
        
        HStack(alignment: .top, spacing: 10) {
            Text("🆕")
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.92), in: Capsule())
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(manifestLatestHomeworkDateText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("宿題：\(manifestLatestHomeworkLabel)")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text("(\(manifestLatestHomeworkCount)語)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.blue.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.blue.opacity(0.18), lineWidth: 1)
        )
        .padding(.horizontal, 4)
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
        let cards = HomeworkStore.shared.collectionFavorites

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
                    perRowAccent: true   // 行ごとに品詞色
                )
                .id(refreshID)
            }
        }
        .navigationTitle("My Collection")
    }
}

// 覚えたBOX ルート
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
                    perRowAccent: true
                )
                .id(refreshID)
            }
        }
        .navigationTitle("覚えたBOX")
    }
}

// MARK: - 検索ロジック
func searchAllCards(query q: String) -> [WordCard] {
    guard !q.isEmpty else { return [] }

    let allPOS = PartOfSpeech.homeworkCases + [.others]

    let rawCards =
        allPOS.flatMap { HomeworkStore.shared.list(for: $0) } +
        allPOS.flatMap { SampleDeck.filtered(by: $0) }

    func key(_ c: WordCard) -> String {
        "\(c.pos.rawValue)|\(c.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
    }

    func mergedUniqueStrings(_ lhs: [String], _ rhs: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for s in lhs + rhs {
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if !seen.contains(trimmed) {
                seen.insert(trimmed)
                result.append(trimmed)
            }
        }
        return result
    }

    func mergeCards(base: WordCard, incoming: WordCard) -> WordCard {
        WordCard(
            id: base.id,
            pos: base.pos,
            word: base.word,
            meanings: mergedUniqueStrings(base.meanings, incoming.meanings),
            examples: mergedUniqueStrings(base.examples, incoming.examples)
        )
    }

    var merged: [String: WordCard] = [:]

    for c in rawCards {
        let k = key(c)
        if let existing = merged[k] {
            merged[k] = mergeCards(base: existing, incoming: c)
        } else {
            merged[k] = c
        }
    }

    return merged.values
        .filter { c in
            if c.word.localizedCaseInsensitiveContains(q) { return true }

            if c.meanings.contains(where: { $0.localizedCaseInsensitiveContains(q) }) {
                return true
            }

            if c.examples.contains(where: { $0.localizedCaseInsensitiveContains(q) }) {
                return true
            }

            if (IrregularVerbBank.forms(for: c.word) ?? [])
                .contains(where: { $0.localizedCaseInsensitiveContains(q) }) {
                return true
            }

            return false
        }
        .sorted { $0.word.localizedCaseInsensitiveCompare($1.word) == .orderedAscending }
}






