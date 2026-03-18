//
//  NoticeFileEditorView.swift
//  WordsForest
//
//  Created by Nami .T on 2026/03/19.
//

import SwiftUI
import UniformTypeIdentifiers

struct NoticeFileEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var homeworkPayloadID: String = ""
    @State private var homeworkDateText: String = ""
    @State private var homeworkLabel: String = ""
    @State private var homeworkCountText: String = ""
    @State private var latestColumnIDText: String = ""

    @State private var exportDoc: JSONTextDocument? = nil
    @State private var exportFileName: String = "wf-manifest.json"
    @State private var showingExporter = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("新しい宿題のお知らせ") {
                    TextField("宿題ファイルID", text: $homeworkPayloadID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("日付（例: 2026/03/19）", text: $homeworkDateText)

                    TextField("宿題名（例: 動詞＋副詞）", text: $homeworkLabel)

                    TextField("語数（例: 24）", text: $homeworkCountText)
                        .keyboardType(.numberPad)
                }

                Section("コラムのお知らせ") {
                    TextField("最新コラム番号（例: 25）", text: $latestColumnIDText)
                        .keyboardType(.numberPad)
                }

                Section {
                    Button {
                        exportNoticeFile()
                    } label: {
                        HStack {
                            Text("🔔")
                            Text("お知らせファイルを書き出す")
                        }
                    }
                    .disabled(!canExport)
                }

                Section {
                    Text("生徒に送るのは、宿題JSONやコラムJSONに加えて、この「お知らせファイル」です。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("お知らせを作る")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: exportDoc ?? JSONTextDocument(text: "{}"),
                contentType: .json,
                defaultFilename: exportFileName
            ) { result in
                switch result {
                case .success(let url):
                    errorMessage = nil
                    print("✅ notice exported:", url)
                case .failure(let err):
                    errorMessage = err.localizedDescription
                    print("❌ notice export error:", err)
                }
            }
            .alert(
                "書き出しエラー",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var canExport: Bool {
        !homeworkPayloadID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !homeworkDateText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !homeworkLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !homeworkCountText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !latestColumnIDText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func exportNoticeFile() {
        let homeworkCount = Int(homeworkCountText.trimmingCharacters(in: .whitespacesAndNewlines))
        let latestColumnID = Int(latestColumnIDText.trimmingCharacters(in: .whitespacesAndNewlines))

        let manifest = DeliveryManifest(
            latestHomeworkPayloadID: nonEmptyOrNil(homeworkPayloadID),
            latestHomeworkDateText: nonEmptyOrNil(homeworkDateText),
            latestHomeworkLabel: nonEmptyOrNil(homeworkLabel),
            latestHomeworkCount: homeworkCount,
            latestColumnArticleID: latestColumnID,
            updatedAtISO: ISO8601DateFormatter().string(from: Date())
        )

        do {
            let result = try DeliveryManifestFile.makeExportDocument(manifest)
            exportDoc = result.doc
            exportFileName = result.fileName
            errorMessage = nil
            showingExporter = true
        } catch {
            errorMessage = "お知らせファイルを作れませんでした: \(error.localizedDescription)"
        }
    }

    private func nonEmptyOrNil(_ s: String) -> String? {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

#Preview {
    NoticeFileEditorView()
}
