//
//  POSFlashcardListView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/12/07.
//
import SwiftUI

/// 品詞ごとの一覧を作って POSFlashcardView に渡すラッパー
struct POSFlashcardListView: View {
    let pos: PartOfSpeech
    let accent: Color
    let animalName: String

    @Environment(\.dismiss) private var dismiss

    @State private var refreshID = UUID()
    @State private var showingAdd = false
    @State private var editingWord: WordCard? = nil

    /// HomeworkStore と SampleDeck をマージして、重複を除いた一覧
    private var mergedCards: [WordCard] {
        let store = HomeworkStore.shared.list(for: pos)
        let deck  = SampleDeck.filtered(by: pos)
        let all   = store + deck

        // 「品詞 + 単語 + 意味」で一意にする（検索と同じロジック）
        let unique = all.uniqued {
            "\($0.pos.rawValue)|\($0.word.lowercased())|\($0.meanings.joined(separator: ","))"
        }

        // ✅ HomeworkStore に聞いて「覚えた」単語を除外する
           let hw = HomeworkStore.shared
           return unique.filter { card in
               !hw.isLearned(card)
           }
    }
    

    var body: some View {
        let cards = mergedCards

        Group {
            if cards.isEmpty {
                // まだ単語がないとき
                ContentUnavailableView("まだありません", systemImage: "book")
            } else {
                // 単語があるとき
                POSFlashcardView(
                    title: pos.jaTitle,                               // 画面タイトル
                    cards: cards,                                     // 単語カード一覧
                    accent: pos.accentColor,                          // タイトル帯の色
                    background: pos.backgroundColor.opacity(0.50),    // ← 品詞ごとの背景色
                    animalName: animalName,                           // 品詞ごとの動物
                    onEdit: { c in editingWord = c },                 // “…” 長押し編集
                    onDataChanged: { refreshID = UUID() }             // 変更後に再描画
                )
                .id(refreshID)
            }
        }
        .navigationTitle(pos.jaTitle)
        .navigationBarTitleDisplayMode(.inline)

        // 🔧 ツールバー（＋メニュー ＆ ホームへ🏠）
        .toolbar {
            // 左：＋メニュー
            ToolbarItemGroup(placement: .topBarLeading) {
                Menu {
                    Button("単語を追加") {
                        showingAdd = true
                    }
                    if pos != .others {
                        Button("不足分を自動追加（24まで）") {
                            HomeworkStore.shared.autofill(for: pos, target: 24)
                            refreshID = UUID()
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.secondary)
                        .opacity(0.45)
                }
            }

            // 右：ホームへ🏠
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { dismiss() } label: {
                    Text("ホームへ🏠")
                }
                .foregroundStyle(.blue)
                .buttonStyle(.plain)
                .background(.ultraThinMaterial, in: Capsule())
            }
        }

        // 🔧 追加・編集シート
        .sheet(isPresented: $showingAdd, onDismiss: { refreshID = UUID() }) {
            AddWordView(pos: pos)
        }
        .sheet(item: $editingWord, onDismiss: { refreshID = UUID() }) { c in
            AddWordView(pos: pos, editing: c)
        }

        // 🔧 通知でリフレッシュ（お気に入り／覚えた／ストア変更／例文変更）
        .onReceive(NotificationCenter.default.publisher(for: .favoritesDidChange)) { _ in
            refreshID = UUID()
        }
        .onReceive(NotificationCenter.default.publisher(for: .learnedDidChange)) { _ in
            refreshID = UUID()
        }
        .onReceive(NotificationCenter.default.publisher(for: .storeDidChange)) { _ in
            refreshID = UUID()
        }
        .onReceive(NotificationCenter.default.publisher(for: .examplesDidChange)) { _ in
            refreshID = UUID()
        }
    }
}
