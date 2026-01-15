//
//  WeeklySetEntryView.swift
//  WordsForest
//
//  Created by Nami .T on 2026/01/05.
//

import SwiftUI

struct WeeklySetEntryView: View {
    @EnvironmentObject private var hw: HomeworkState
    @EnvironmentObject private var teacher: TeacherMode

    let pair: PosPair

    var body: some View {
        // 取り込み済み（or 先生側で確定済み）payload があるか？
        let payload = HomeworkPackStore.shared.load(
            cycleIndex: hw.currentCycleIndex,
            pair: pair
        )

        Group {
            if let payload {
                // ✅ 取り込み済み：配布された中身を表示
                WeeklySetPayloadView(payload: payload)

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

private struct WeeklySetPayloadView: View {
    let payload: HomeworkExportPayload

    var body: some View {
        List {
            Section {
                Text("日付: \(String(payload.createdAt.prefix(10)).replacingOccurrences(of: "-", with: "/"))")
                Text("ペア: \(payload.pair == 0 ? "名詞＋形容詞" : "動詞＋副詞")")
                Text("語数: \(payload.totalCount)")
            }

            Section("単語") {
                ForEach(Array(payload.items.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.word).font(.headline)
                        if !item.meanings.isEmpty {
                            Text(item.meanings.joined(separator: ", "))
                                .foregroundStyle(.secondary)
                        }
                        if let ex = item.example {
                            Text(ex.en).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
