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
    
    @ObservedObject private var homeworkStore = HomeworkStore.shared
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var teacher: TeacherMode
    
    @State private var showingAdd = false
    @State private var editingWord: WordCard? = nil
    @State private var displayedCards: [WordCard] = []
 
    private func reloadCards() {
        displayedCards = homeworkStore.list(for: pos)
            .filter { !homeworkStore.isLearned($0) }
            .sorted { $0.word.localizedCaseInsensitiveCompare($1.word) == .orderedAscending }
    }
    
/*
    private var mergedCards: [WordCard] {
        let store = homeworkStore.list(for: pos)
        let deck  = SampleDeck.filtered(by: pos)

        func key(_ c: WordCard) -> String {
            "\(c.pos.rawValue)|\(normWord(c.word))"
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

        var dict: [String: WordCard] = [:]

        // 先に SampleDeck を入れる
        for c in deck {
            dict[key(c)] = c
        }

        // HomeworkStore 側は「上書き」ではなく「統合」
        for c in store {
            let k = key(c)
            if let existing = dict[k] {
                dict[k] = mergeCards(base: existing, incoming: c)
            } else {
                dict[k] = c
            }
        }

        return dict.values
            .filter { !homeworkStore.isLearned($0) }
            .sorted { $0.word.localizedCaseInsensitiveCompare($1.word) == .orderedAscending }
    }
*/
    
    var body: some View {
        let cards = displayedCards

        Group {
            if cards.isEmpty {
                // まだ単語がないとき
                ContentUnavailableView("まだありません", systemImage: "book")
            } else {
                // 単語があるとき
                POSFlashcardView(
                    title: pos.jaTitle,
                    cards: cards,
                    accent: pos.accentColor,
                    background: pos.backgroundColor,
                    animalName: animalName,
                    onEdit: { c in editingWord = c },
                    onDataChanged: {
                        reloadCards()
                    }
                )
            }
        }
    /*      .navigationTitle(pos.jaTitle)
            .navigationBarTitleDisplayMode(.inline)
    */
        // 🔧 ツールバー（＋メニュー ＆ ホームへ🏠）
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                Menu {
                    GuardedButton {
                        showingAdd = true
                    } label: {
                        Text("単語を追加")
                    }

                    if pos != .others {
                        GuardedButton {
                            HomeworkStore.shared.autofill(for: pos, target: 24)
                            reloadCards()
                        } label: {
                            Text("不足分を自動追加（24まで）")
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
                }
                .foregroundStyle(.blue)
                .buttonStyle(.plain)
                .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .onAppear {
            reloadCards()
        }
        .onReceive(NotificationCenter.default.publisher(for: .favoritesDidChange)) { _ in
            reloadCards()
        }
        .onReceive(NotificationCenter.default.publisher(for: .learnedDidChange)) { _ in
            reloadCards()
        }
        .onReceive(NotificationCenter.default.publisher(for: .storeDidChange)) { _ in
            reloadCards()
        }
        // ✅ toolbar の外に sheet を置く
        .sheet(isPresented: $showingAdd, onDismiss: {
            reloadCards()
        }) {
            AddWordView(pos: pos)
        }
        .sheet(item: $editingWord, onDismiss: {
            reloadCards()
        }) { c in
            AddWordView(pos: pos, editing: c)
        }
    }
}
