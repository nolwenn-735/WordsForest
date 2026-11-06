

//Created by Nami .T on 2025/12/07.

//  POSFlashcardListView.swift
//  WordsForest
//
//
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
    @EnvironmentObject private var router: Router
    
    @State private var showingAdd = false
    @State private var editingWord: WordCard? = nil
    @State private var displayedCards: [WordCard] = []
 
    private func reloadCards() {
        displayedCards = homeworkStore.list(for: pos)
            .filter { !homeworkStore.isLearned($0) }
            .sorted { $0.word.localizedCaseInsensitiveCompare($1.word) == .orderedAscending }
    }
    

    
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

        // 🔧 ツールバー（単語追加 ＆ ホームへ🏠）
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                GuardedButton {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.secondary)
                        .opacity(0.45)
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    router.goHome()
                } label: {
                    Text("ホームへ🏠")
                }
                .foregroundStyle(.blue)
                .buttonStyle(.plain)
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
