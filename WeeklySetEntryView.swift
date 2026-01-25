//
//  WeeklySetEntryView.swift
//  WordsForest
//
//  Created by Nami .T on 2026/01/05.→01/15card化のためのPayloadView置き換え
//

import SwiftUI

struct WeeklySetEntryView: View {
    @EnvironmentObject private var hw: HomeworkState
    @EnvironmentObject private var teacher: TeacherMode

    let pair: PosPair

    var body: some View {
        let payload = HomeworkPackStore.shared.load(
            cycleIndex: hw.currentCycleIndex,
            pair: pair
        )

        // ✅ PosPair → PartOfSpeech を取り出す（posA/posB は無いので parts を使う）
        let parts = pair.parts

        return Group {
            if let payload {
                // ✅ 取り込み済み：payloadから「カード画面」へ行けるUI
                WeeklySetPayloadCardsView(payload: payload)

            } else if teacher.unlocked {
                // ✅ 先生だけ：未取り込みでもローカル生成ビューに入れる
                WeeklySetView(pair: pair)

            } else {
                // ✅ 生徒：未取得ならガイドだけ出す
                HomeworkNotImportedView()
            }
        }
        .navigationTitle("今回の宿題")
        .navigationBarTitleDisplayMode(.inline)

        // ✅ ここがポイント：.toolbar(content:) じゃなくて .toolbar { } を使う
        .toolbar {
            if teacher.unlocked {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        HomeworkSetEditorView(posA: parts[0], posB: parts[1])
                            .environmentObject(hw)
                            .environmentObject(teacher)
                    } label: {
                        Text("編集")
                    }
                }
            }
        }
    }
}

private struct HomeworkNotImportedView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("この端末には、今回の宿題がまだ入っていません。")
                .font(.headline)

            Text("先生から届いたJSONを Files で開き、アプリの「🔵宿題取得」から取り込んでください。")
                .foregroundStyle(.secondary)

            Text("（取り込み後に、もう一度「🗓️今回分へ→」を押すと表示されます）")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }
}


// MARK: - payload版（ここが「カードにならない問題」を直す）
private struct WeeklySetPayloadCardsView: View {
    @EnvironmentObject private var hw: HomeworkState
    let payload: HomeworkExportPayload

    var body: some View {
        let pair = PosPair(rawValue: payload.pair) ?? hw.currentPair
        let parts = pair.parts

        List {
            Section("今回のセット") {
                posRow(parts[0])
                posRow(parts[1])
            }

            Section {
                NavigationLink("24語まとめて学習") {
                    combinedWordcardPage(for: parts)
                }
            }

            // ついでに情報も見えるように（安心用）
            Section("情報") {
                Text("日付: \(String(payload.createdAt.prefix(10)).replacingOccurrences(of: "-", with: "/"))")
                Text("ペア: \(payload.pair == 0 ? "名詞＋形容詞" : "動詞＋副詞")")
                Text("語数: \(payload.totalCount)")
            }
        }
        .navigationTitle("今回の宿題")
        .onAppear {
            // ✅ ここが重要：取り込んだpayloadを HomeworkState のキャッシュに落とす
            // （WeeklySetView の hw.homeworkWords(...) を動かすための反映）
            hw.applyImportedPayload(payload)
        }
    }

    @ViewBuilder
    private func posRow(_ pos: PartOfSpeech) -> some View {
        NavigationLink("\(pos.jaTitle) 12語") {
            singleWordcardPage(for: pos)
        }
        .foregroundStyle(pos.accent)
    }

    private func singleWordcardPage(for pos: PartOfSpeech) -> some View {
        // payload → WordCard[]
        let cards = hw.homeworkWords(for: pos)   // applyImportedPayload で cachedHomework が入る想定
        let animal = pos.animalName(forCycle: hw.variantIndex(for: pos))

        return POSFlashcardView(
            title: pos.jaTitle,
            cards: cards,
            accent: pos.accent,
            background: pos.backgroundColor,
            animalName: animal,
            hideLearned: true
        )
    }

    @ViewBuilder
    private func combinedWordcardPage(for parts: [PartOfSpeech]) -> some View {
        if parts.count < 2 {
            Text("設定に誤りがあります")
        } else {
            let a = hw.homeworkWords(for: parts[0])
            let b = hw.homeworkWords(for: parts[1])
            let all = a + b

            let title      = "\(parts[0].jaTitle)+\(parts[1].jaTitle) 24語"
            let background = Color(.systemGray6)
            let accent     = Color.primary
            let mixAnimal  = "index_raccoon_flower"

            POSFlashcardView(
                title: title,
                cards: all,
                accent: accent,
                background: background,
                animalName: mixAnimal,
                hideLearned: true
            )
        }
    }
}
