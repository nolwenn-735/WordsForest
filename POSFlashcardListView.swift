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

    @State private var showingAdd = false
    @State private var editingWord: WordCard? = nil

    /// HomeworkStore と SampleDeck をマージして、重複を除いた一覧
    private var mergedCards: [WordCard] {
        let store = homeworkStore.list(for: pos)
        let deck  = SampleDeck.filtered(by: pos)
        let all   = store + deck

        let unique = all.uniqued {
            "\($0.pos.rawValue)|\($0.word.lowercased())|\($0.meanings.joined(separator: ","))"
        }

        // ✅ 覚えたカードは品詞ページから除外
        return unique.filter { card in
            !homeworkStore.isLearned(card)
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
                    title: pos.jaTitle,
                    cards: cards,
                    accent: pos.accentColor,
                    background: pos.backgroundColor.opacity(0.50),
                    animalName: animalName,
                    onEdit: { c in editingWord = c }
                )
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
        // 追加シート
        .sheet(isPresented: $showingAdd) {
            AddWordView(pos: pos)
        }

        // 編集シート
        .sheet(item: $editingWord) { c in
            AddWordView(pos: pos, editing: c)
        } 
    }
}
