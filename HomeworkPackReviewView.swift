//
//  HomeworkPackReviewView.swift
//  WordsForest
//
//  Created by Nami .T on 2026/01/30.
//

import SwiftUI

/// 宿題確定後に「24語の確認＆例文編集入口」を出す画面
struct HomeworkPackReviewView: View {

    let title: String
    let cards: [WordCard]          // 24語（pos混在でもOK）

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var teacher: TeacherMode

    @State private var editingCard: WordCard? = nil

    // posごとに見やすく分ける（順序を固定したければここで並べ順を調整）
    private var grouped: [(pos: PartOfSpeech, items: [WordCard])] {
        let dict = Dictionary(grouping: cards, by: { $0.pos })

        let order: [PartOfSpeech] = [.noun, .verb, .adj, .adv, .others]
        return order.compactMap { pos in
            guard let items = dict[pos], !items.isEmpty else { return nil }
            return (pos, items)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.pos) { section in
                    Section(section.pos.jaTitle) {
                        ForEach(section.items, id: \.self) { c in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(c.word)
                                        .font(.headline)

                                    if let first = c.meanings.first, !first.isEmpty {
                                        Text(first)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                // ✅ “いつもの例文編集”へ
                                Button {
                                    teacher.requestUnlock {
                                        editingCard = c
                                    }
                                } label: {
                                    Image(systemName: "square.and.pencil")
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                }
            }
            .sheet(item: $editingCard) { card in
                // ✅ ここが「既存の例文編集画面」に統一されるポイント
                ExampleEditorView(pos: card.pos, word: card.word)
            }
        }
    }
}

extension WordCard {
    /// 重複排除・表示用の安定キー（Identifiableのidとは別物）
    var stableKey: String { "\(pos.rawValue)|\(word.lowercased())" }
}
