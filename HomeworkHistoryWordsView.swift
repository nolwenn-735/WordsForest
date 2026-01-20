//
//  HomeworkHistoryWordsView.swift
//  WordsForest
//
//  Created by Nami .T on 2026/01/20.
//

import SwiftUI

struct HomeworkHistoryWordsView: View {
    @EnvironmentObject var hw: HomeworkState
    let entry: HomeworkEntry

    var body: some View {
        let cards = hw.cards(for: entry)

        Group {
            if cards.isEmpty {
                VStack(spacing: 12) {
                    Text("この回は旧方式の履歴のため、単語の復元がまだできません。")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Text("（これから作られる履歴は復元できます）")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .navigationTitle("宿題（履歴）")
            } else {
                POSFlashcardView(
                    title: "\(entry.pair.jaTitle) 24語",
                    cards: cards,
                    accent: Color.primary,
                    background: Color(.systemGray6),
                    animalName: "index_raccoon_flower",
                    hideLearned: false
                )
                .navigationTitle("宿題（履歴）")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
