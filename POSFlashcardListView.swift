

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
    @EnvironmentObject private var router: Router
    
    @State private var showingAdd = false
    @State private var editingWord: WordCard? = nil
    @State private var editingExamplesCard: WordCard? = nil
    @State private var newlyAddedCard: WordCard? = nil
    @State private var showingPostAddPrompt = false
    @State private var displayedCards: [WordCard] = []
 
    private func reloadCards() {
        displayedCards = homeworkStore.list(for: pos)
            .filter { !homeworkStore.isLearned($0) }
            .sorted { $0.word.localizedCaseInsensitiveCompare($1.word) == .orderedAscending }
    }

    var body: some View {
        let cards = displayedCards
        let pageTitle = pos == .others ? "その他" : pos.jaTitle

        POSFlashcardView(
            title: pageTitle,
            cards: cards,
            accent: pos.accentColor,
            background: pos.backgroundColor,
            animalName: animalName,
            onEdit: { c in editingWord = c },
            onDataChanged: {
                reloadCards()
            },
            onBack: {
                dismiss()
            },
            onAdd: {
                showingAdd = true
            },
            onHome: {
                router.goHome()
            },
            alphabetJumpEnabled: true
        )

        // 上部操作は POSFlashcardView 側で一括管理
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

            if newlyAddedCard != nil {
                showingPostAddPrompt = true
            }
        }) {
            AddWordView(pos: pos) { card in
                newlyAddedCard = card
            }
        }
        .sheet(item: $editingWord, onDismiss: {
            reloadCards()
        }) { c in
            AddWordView(pos: pos, editing: c)
        }
        .sheet(item: $editingExamplesCard, onDismiss: {
            reloadCards()
        }) { c in
            ExampleEditorView(pos: c.pos, word: c.word)
        }
        .alert(
            "カードを追加しました",
            isPresented: $showingPostAddPrompt,
            presenting: newlyAddedCard
        ) { card in
            Button("例文・ノートを編集") {
                newlyAddedCard = nil

                DispatchQueue.main.async {
                    editingExamplesCard = card
                }
            }

            Button("あとで", role: .cancel) {
                newlyAddedCard = nil
            }
        } message: { card in
            Text("「\(card.word)」のカード裏面を続けて編集できます。")
        }
    }
}
