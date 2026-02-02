
// HomeworkUI.swift

import SwiftUI
import Foundation
import UniformTypeIdentifiers

// MARK: - Banner（先生：書き出し）

struct HomeworkBanner: View {
    @EnvironmentObject var hw: HomeworkState
    @EnvironmentObject var teacher: TeacherMode

    // Filesへ書き出し用
    @State private var exportDoc: JSONTextDocument? = nil
    @State private var exportFileName: String = "homework.json"
    @State private var showingExporter = false
    @State private var exportErrorMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            let leftColWidth: CGFloat = 84

            VStack(alignment: .leading, spacing: 8) {

                // 1段目
                HStack(spacing: 8) {
                    Text("📘今サイクル")
                        .font(.headline)
                        .frame(width: leftColWidth, alignment: .leading)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                        .allowsTightening(true)

                    pill(hw.currentPair == .nounAdj ? "名詞＋形容詞" : "動詞＋副詞")
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .allowsTightening(true)

                    Spacer(minLength: 8)
                }

                // 2段目
                // 2段目
                HStack(spacing: 8) {
                    Button {
                        teacher.showingUnlockSheet = true
                    } label: {
                        Label("Teacher", systemImage: teacher.unlocked ? "lock.open" : "lock")
                            .font(.caption2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: leftColWidth, alignment: .leading)

                    pill(hw.daysPerCycle == 14 ? "2週間" : "1週間")

                    // 先生解除時だけ：書き出し + （DEBUG時だけ）🔁
                    if teacher.unlocked {

                        Button {
                            print("✅ EXPORT BUTTON TAP") 
                            
                            let payload = HomeworkPackStore.shared.buildOrLoadFixedPack(
                                hw: hw,
                                requiredCount: 10,
                                totalCount: 24
                            )

                            // ✅ ここに入れる（確認ログ）
                            print("items count:", payload.items.count)

                            let firstJA = payload.items.first?.example?.ja
                            print("JA EXAMPLE:", firstJA ?? "nil")
                            let json = HomeworkPackStore.shared.makePrettyJSONString(payload)

                            exportDoc = JSONTextDocument(text: json)
                            exportFileName = HomeworkExportFile.makeFileName(for: payload)
                            exportErrorMessage = nil
                            showingExporter = true
                        } label: {
                            Label("書き出し", systemImage: "square.and.arrow.down")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)

                        #if DEBUG
                        Button {
                            HomeworkPackStore.shared.clear(
                                cycleIndex: hw.currentCycleIndex,
                                pair: hw.currentPair
                            )
                            print("✅ cleared pack")
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: Capsule())
                                .foregroundStyle(.secondary)
                                .frame(minWidth: 44, minHeight: 44)  // ←押しやすさ
                                .contentShape(Rectangle())           // ←判定拡張
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("今回分の固定パックを消す（先生）")
                        #endif
                    }

                    Spacer()
                }
            }

            HStack(spacing: 8) {
                ToggleButton(title: "▶︎ 宿題あり",
                             isOn: hw.status == .active,
                             onTap: { hw.setActive() },
                             color: .green)

                ToggleButton(title: "⏸ ストップ",
                             isOn: hw.status == .paused,
                             onTap: { hw.setPaused() },
                             color: .orange)

                ToggleButton(title: "⛔️ 宿題なし",
                             isOn: hw.status == .none,
                             onTap: { hw.setNone() },
                             color: .red)

                Spacer()

                Button("＋1週延長") { hw.extendOneWeek() }
                    .buttonStyle(.bordered)
                    .tint(.primary)
            }

            if let msg = exportErrorMessage {
                Text("⚠️ \(msg)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.black.opacity(0.08), lineWidth: 1))
        .onAppear {
            DispatchQueue.main.async {
                hw.refresh()
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
                exportErrorMessage = nil
                print("✅ exported:", url)
            case .failure(let err):
                exportErrorMessage = err.localizedDescription
                print("❌ export error:", err)
            }
        }
    }

    private func pill(_ t: String) -> some View {
        Text(t)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.white)
            .cornerRadius(999)
            .overlay(RoundedRectangle(cornerRadius: 999).stroke(.black.opacity(0.15), lineWidth: 1))
    }
}

private struct ToggleButton: View {
    let title: String
    let isOn: Bool
    let onTap: () -> Void
    let color: Color

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(isOn ? color.opacity(0.9) : Color.white)
                .foregroundColor(isOn ? .white : .black)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recent Widget（生徒：取り込み）
struct HomeworkRecentWidget: View {
    @EnvironmentObject var hw: HomeworkState
    @Binding var confirmEntry: HomeworkEntry?     // ← これを追加

    @State private var showingImporter = false
    @State private var showingImportAlert = false
    @State private var importMessage: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack {
                NavigationLink("履歴をすべて見る") {
                    HomeworkHistoryList()
                }
                .font(.callout)
                .foregroundColor(.blue)

                Spacer()

                Button("🔵宿題取得") { showingImporter = true }
                    .font(.callout)
                    .buttonStyle(.bordered)
                    .tint(.blue)
            }

            ForEach(hw.history.prefix(4)) { e in
                Button { confirmEntry = e } label: {
                    HStack {
                        Text(dateString(e.date)).foregroundColor(.secondary)
                        Text(e.titleLine)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.black.opacity(0.08), lineWidth: 1))

        // 取り込み・alert はそのまま
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importFromURL(url)
            case .failure(let err):
                importMessage = "ファイル選択に失敗: \(err.localizedDescription)"
                showingImportAlert = true
            }
        }
        .alert("宿題取得", isPresented: $showingImportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importMessage)
        }
    }

    private func importFromURL(_ url: URL) {
        let gotAccess = url.startAccessingSecurityScopedResource()
        defer { if gotAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(HomeworkExportPayload.self, from: data)

            if hw.isAlreadyImported(payload: payload) {
                importMessage = "最新の宿題は既に取得済みです。\n" + makeImportOKMessage(payload)
                showingImportAlert = true
                return
            }

            try HomeworkPackStore.shared.importHomeworkPayload(payload, hw: hw)
            
            // ✅ 取り込んだ payload を「今サイクル」として即反映（cycleIndex/pairIndexも揃う）
            hw.applyImportedPayload(payload)
            // ✅ 追加：取り込んだ内容を “カード” にしてキャッシュへ反映
            hw.addImportedToHistory(payload: payload)
            hw.markImported(payload: payload)

            importMessage = makeImportOKMessage(payload)
            showingImportAlert = true

        } catch {
            importMessage = "取り込みに失敗: \(error.localizedDescription)"
            showingImportAlert = true
        }
    }

    private func makeImportOKMessage(_ payload: HomeworkExportPayload) -> String {
        let ymd = String(payload.createdAt.prefix(10)).replacingOccurrences(of: "-", with: "/")
        let pairLabel = (payload.pair == 0) ? "名詞＋形容詞" : "動詞＋副詞"
        return "\(ymd) の宿題（\(pairLabel)）を取得しました。"
    }
}

// MARK: - History List

struct HomeworkHistoryList: View {
    @EnvironmentObject var hw: HomeworkState

    @State private var confirmEntry: HomeworkEntry?
    @State private var pushEntry: HomeworkEntry?

    var body: some View {
        List(hw.history) { e in
            Button {
                confirmEntry = e
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateString(e.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(e.titleLine)
                }
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("宿題の履歴")

        // ✅ 押した後の遷移先（24語）
        .navigationDestination(item: $pushEntry) { e in
            HomeworkHistoryWordsView(entry: e)
                .environmentObject(hw)
        }

        // ✅ 確認アラート
        .alert("この日の宿題を見ますか？",
               isPresented: .constant(confirmEntry != nil),
               presenting: confirmEntry) { e in
            Button("見る") { pushEntry = e; confirmEntry = nil }
            Button("キャンセル", role: .cancel) { confirmEntry = nil }
        }
    }
}

// MARK: - Utilities

private func dateString(_ d: Date) -> String {
    let f = DateFormatter()
    f.locale = .current
    f.dateFormat = "yyyy/MM/dd"
    return f.string(from: d)
}

// MARK: - Previews

#Preview("Banner") {
    HomeworkBanner()
        .environmentObject(HomeworkState())
        .environmentObject(TeacherMode.shared) // private init 対策：shared を使う
}

#Preview("RecentWidget") {
    @Previewable @State var confirmEntry: HomeworkEntry? = nil

    NavigationStack {
        HomeworkRecentWidget(confirmEntry: $confirmEntry)
            .environmentObject(HomeworkState())
    }
}


import SwiftUI
import UniformTypeIdentifiers

struct JSONTextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let s = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = s
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return .init(regularFileWithContents: data)
    }
}

