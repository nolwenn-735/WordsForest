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
    
    /// HomeworkStore と SampleDeck をマージして、重複を除いた一覧
    private var mergedCards: [WordCard] {
        let store = homeworkStore.list(for: pos)
        let deck  = SampleDeck.filtered(by: pos)
        
        func key(_ c: WordCard) -> String {
            "\(c.pos.rawValue)|\(normWord(c.word))"
        }
        
        var dict: [String: WordCard] = [:]
        
        // 先に SampleDeck（仮の土台）
        for c in deck { dict[key(c)] = c }
        
        // 後から HomeworkStore（先生/自分が直した“正”で上書き）
        for c in store { dict[key(c)] = c }
        
        // ✅ 覚えたカードは除外（今の仕様を維持）
        return dict.values
            .filter { !homeworkStore.isLearned($0) }
            .sorted { $0.word < $1.word }
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
        // ✅ toolbar の外に sheet を置く
        .sheet(isPresented: $showingAdd) {
            AddWordView(pos: pos)
        }
        .sheet(item: $editingWord) { c in
            AddWordView(pos: pos, editing: c)
        }
        .sheet(isPresented: $teacher.showingUnlockSheet) {
            TeacherUnlockSheet()
                .environmentObject(teacher)
        }
    }
}
