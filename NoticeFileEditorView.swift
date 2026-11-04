//  Created by Nami .T on 2026/03/19.→03/25🔔通知自動化
//
//  NoticeFileEditorView.swift
//  WordsForest
//
//
//  NoticeFileEditorView.swift
//
//
import SwiftUI

struct NoticeFileEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onConfirm: ((DeliveryManifest) -> Void)?
    
    enum EntryContext {
        case homework
        case column
    }

    let entryContext: EntryContext

    @State private var homeworkPayloadID: String
    @State private var homeworkDateText: String
    @State private var homeworkLabel: String
    @State private var homeworkCountText: String

    @State private var homeworkStatus: String
    @State private var homeworkCycleWeeks: Int
    @State private var homeworkExtensionWeeks: Int

    @State private var latestColumnIDText: String

    init(
        initialHomeworkPayloadID: String = "",
        initialHomeworkDateText: String = "",
        initialHomeworkLabel: String = "",
        initialHomeworkCount: Int? = nil,
        initialHomeworkStatus: String? = nil,
        initialHomeworkCycleWeeks: Int? = nil,
        initialHomeworkExtensionWeeks: Int? = nil,
        initialLatestColumnID: Int? = nil,
        entryContext: EntryContext = .homework,
        onConfirm: ((DeliveryManifest) -> Void)? = nil
        ) {
        self.entryContext = entryContext
        self.onConfirm = onConfirm
        let cycle = initialHomeworkCycleWeeks ?? 0
        let extensionWeeks = initialHomeworkExtensionWeeks ?? 0

        _homeworkPayloadID = State(initialValue: initialHomeworkPayloadID)
        _homeworkDateText = State(initialValue: initialHomeworkDateText)
        _homeworkLabel = State(initialValue: initialHomeworkLabel)
        _homeworkCountText = State(initialValue: initialHomeworkCount.map(String.init) ?? "")

        _homeworkStatus = State(initialValue: initialHomeworkStatus ?? "")
        _homeworkCycleWeeks = State(initialValue: (cycle == 1 || cycle == 2) ? cycle : 0)
        _homeworkExtensionWeeks = State(
            initialValue: (extensionWeeks == 1 || extensionWeeks == 2)
                ? extensionWeeks
                : 0
        )

        _latestColumnIDText = State(initialValue: initialLatestColumnID.map(String.init) ?? "")
    }
    
    @ViewBuilder
    private var columnNoticeSection: some View {
        Section(
            entryContext == .column
                ? "配布するコラム"
                : "最新コラムのNo."
        ) {
            TextField(
                "最新コラムNo.（例: 1）",
                text: $latestColumnIDText
            )
            .keyboardType(.numberPad)

            Text(
                entryContext == .column
                    ? "今回配布するコラムのナンバーです。"
                    : "現在配布済みの最新コラムのナンバーです。"
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .opacity(entryContext == .homework ? 0.45 : 1.0)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if entryContext == .column {
                    columnNoticeSection
                }

                Section("新しい宿題の通知") {
                    TextField("宿題ID（例: 2027-04-20-draft-pair1）", text: $homeworkPayloadID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Text("宿題JSONの id と同じ文字列を入れます。.json は付ける必要はありません。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    TextField("日付（例: 2027/04/20）", text: $homeworkDateText)

                    TextField("宿題名（例: 名詞＋形容詞）", text: $homeworkLabel)

                    TextField("語数（例: 24）", text: $homeworkCountText)
                        .keyboardType(.numberPad)
                }
                .opacity(entryContext == .column ? 0.45 : 1.0)

                Section("宿題状態と期間") {
                    Picker("宿題状態", selection: $homeworkStatus) {
                        Text("未指定").tag("")
                        Text("▶︎ 宿題あり").tag("active")
                        Text("⏸️ ストップ").tag("paused")
                        Text("⛔️ 宿題なし").tag("none")
                    }

                    Picker("元の出題期間", selection: $homeworkCycleWeeks) {
                        Text("未指定").tag(0)
                        Text("1週間").tag(1)
                        Text("2週間").tag(2)
                    }

                    Picker("延長", selection: $homeworkExtensionWeeks) {
                        Text("延長なし").tag(0)
                        Text("+1週延長").tag(1)
                        Text("+2週延長").tag(2)
                    }
                    
                    Text("⏸️は新規出題停止、⛔️は宿題なしです。延長を設定すると、元の出題期間に+1週または+2週を追加できます。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .opacity(entryContext == .column ? 0.45 : 1.0)

                if entryContext == .homework {
                    columnNoticeSection
                }

                Section {
                    Button {
                        confirmNoticeContent()
                    } label: {
                        HStack {
                            Text("🔔")
                            Text("通知内容を決定")
                        }
                    }
                    .disabled(!canExport)
                }
                
                Section {
                    Text("生徒に送るのは、この「通知ファイル」と、配布する内容のJSONです。宿題なら宿題JSON、コラムならコラムJSONを一緒に送ります。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("通知を作る")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var canExport: Bool {
        !homeworkPayloadID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !homeworkDateText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !homeworkLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !homeworkCountText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !homeworkStatus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        homeworkCycleWeeks != 0 ||
        homeworkExtensionWeeks != 0 ||
        !latestColumnIDText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func makeNoticeManifest() -> DeliveryManifest {
        let homeworkCount = Int(
            homeworkCountText
                .trimmingCharacters(in: .whitespacesAndNewlines)
        )

        let latestColumnID = Int(
            latestColumnIDText
                .trimmingCharacters(in: .whitespacesAndNewlines)
        )

        let status = nonEmptyOrNil(homeworkStatus)
        let cycleWeeks = homeworkCycleWeeks == 0
            ? nil
            : homeworkCycleWeeks

        let extensionWeeks: Int? = {
            if status != nil ||
                cycleWeeks != nil ||
                homeworkExtensionWeeks != 0 {

                return homeworkExtensionWeeks
            } else {
                return nil
            }
        }()

        return DeliveryManifest(
            latestHomeworkPayloadID:
                normalizedHomeworkID(homeworkPayloadID),
            latestHomeworkDateText:
                nonEmptyOrNil(homeworkDateText),
            latestHomeworkLabel:
                nonEmptyOrNil(homeworkLabel),
            latestHomeworkCount:
                homeworkCount,
            homeworkStatus:
                status,
            homeworkCycleWeeks:
                cycleWeeks,
            homeworkExtensionWeeks:
                extensionWeeks,
            latestColumnArticleID:
                latestColumnID,
            updatedAtISO:
                ISO8601DateFormatter().string(from: Date())
        )
    }

    private func confirmNoticeContent() {
        let manifest = makeNoticeManifest()

        dismiss()

        DispatchQueue.main.async {
            onConfirm?(manifest)
        }
    }
    

    private func normalizedHomeworkID(_ s: String) -> String? {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.lowercased().hasSuffix(".json") {
            return String(trimmed.dropLast(5))
        }

        return trimmed
    }

    private func nonEmptyOrNil(_ s: String) -> String? {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

#Preview {
    NoticeFileEditorView()
}

