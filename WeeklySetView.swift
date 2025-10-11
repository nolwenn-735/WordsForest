//
//  WeeklySetView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/07.
//
import SwiftUI

struct WeeklySetView: View {
    @EnvironmentObject var hw: HomeworkState
    let pair: PosPair
    
    var body: some View {
        let parts = pair.parts   // [.noun, .adj] など
        
        List {
            Section("今週のセット") {
                posRow(parts[0])
                posRow(parts[1])
            }
            
            Section {
                // 将来の「24語まとめ」用のプレースホルダ
                NavigationLink("24語まとめて学習") {
                    makeWordcardPage(for: parts[0])
                }
            }
        }
        .navigationTitle("今週のセット")
    }
    
    @ViewBuilder
    private func posRow(_ pos: PartOfSpeech) -> some View {
        NavigationLink("\(pos.jaTitle) 12語") {
            makeWordcardPage(for: pos)
        }
        .foregroundStyle(pos.accent)
    }
    
    // 週セットのカードを作る（保存＋サンプルをミックス）
    private func makeWordcardPage(for pos: PartOfSpeech) -> some View {
        // 既に保存されたカード
        let userCards: [WordCard] = HomeworkStore.shared.list(for: pos)
        
        // 目標枚数（デフォルト12）
        let quota: Int = hw.weeklyQuota[pos] ?? 12
        let need = max(0, quota - userCards.count)
        
        // サンプルから補充（重複除外）
        let userWords = Set(userCards.map(\.word))
        let pool: [WordCard] = SampleDeck.filtered(by: pos)
            .filter { !userWords.contains($0.word) }
        let fill: [WordCard] = Array(pool.prefix(need))
        
        // 上限で切り上げ（保存分を優先）
        let combined: [WordCard] = userCards + fill
        let cards: [WordCard] = Array(combined.prefix(quota))
        
        // 右下マスコットのバリアント
        let animal = pos.animalName(forCycle: hw.variantIndex(for: pos))
        
        // ここで View を返す（← return を忘れない）
        return POSFlashcardView(
            title: "\(pos.jaTitle) レッスン",
            cards: cards,
            accent: pos.accent,
            background: pos.backgroundColor,
            animalName: animal,
            reversed: false,
            onEdit: { _ in }      // WeeklySet では編集は使わないので無視
            // onDataChanged: {}   // 省略可（デフォルト {}）
        )
    }
    
}
