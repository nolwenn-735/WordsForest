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
    @ViewBuilder
    private func makeWordcardPage(for pos: PartOfSpeech) -> some View {
        // 既に保存されているカード
        let userCards: [WordCard] = HomeworkStore.shared.list(for: pos)

        // 目標枚数（デフォルトは 12。設定があればそれを使用）
        let quota: Int = hw.weeklyQuota[pos] ?? 12
        let need = max(0, quota - userCards.count)

        // 足りない分をサンプルから補充（重複は除外）
        let userWords = Set(userCards.map { $0.word })
        let pool = SampleDeck.filtered(by: pos)
            .filter { !userWords.contains($0.word) }
        let fill = Array(pool.prefix(need))

        // 上限で切り上げ（順番は保存優先）
        let cards = Array((userCards + fill).prefix(quota))

        // 右下マスコットのバリアント
        let animal = pos.animalName(forCycle: hw.variantIndex(for: pos))

        POSFlashcardView(
            title: "\(pos.jaTitle) レッスン",
            cards: cards,
            accent: pos.accent,
            background: pos.backgroundColor,
            animalName: animal,
            reversed: false
        )
    }
}
