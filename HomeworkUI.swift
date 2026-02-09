
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

    // 🔁消去確認
    @State private var showClearConfirm = false

    var body: some View {
        bannerCard
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
            .alert("固定パックを消しますか？", isPresented: $showClearConfirm) {
                Button("消す", role: .destructive) {
                    HomeworkPackStore.shared.clear(
                        cycleIndex: hw.currentCycleIndex,
                        pair: hw.currentPair
                    )
                    print("✅ cleared pack")

                    // ✅ 追加：HomeworkState 側のキャッシュも全部捨てる
                    hw.clearCachedHomeworkAll()
                    print("✅ cleared cachedHomework(all)")

                    // ✅ 既存の refresh は残してOK
                    hw.refresh()
                }
                Button("やめる", role: .cancel) { }
            } message: {
                Text("このサイクルの「今回分」固定パックを削除します。")
            }
    }
    
    private var bannerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            let leftColWidth: CGFloat = 84

            VStack(alignment: .leading, spacing: 8) {
                firstRow(leftColWidth: leftColWidth)
                secondRow(leftColWidth: leftColWidth)
            }

            thirdRow

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
            DispatchQueue.main.async { hw.refresh() }
        }
    }

    private func firstRow(leftColWidth: CGFloat) -> some View {
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
    }

    private func secondRow(leftColWidth: CGFloat) -> some View {
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

            // ✅ ここを置き換え
                    cycleLengthCapsule

                    if teacher.unlocked {
                        exportButton
                        #if DEBUG
                        clearButton
                        #endif
                    }

                    Spacer()
                }
            }
    
    @ViewBuilder
    private var cycleLengthCapsule: some View {
        if teacher.unlocked {
            Menu {
                Button("1週間") { hw.daysPerCycle = 7 }
                Button("2週間") { hw.daysPerCycle = 14 }
            } label: {
                Text(hw.cycleLengthLabel)
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        } else {
            Text(hw.cycleLengthLabel)
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }

    private var exportButton: some View {
        Button {
            print("✅ EXPORT BUTTON TAP")

            let payload = HomeworkPackStore.shared.buildOrLoadFixedPack(
                hw: hw,
                requiredCount: 10,
                totalCount: 24
            )

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
    }

    private var clearButton: some View {
        Button {
            // ✅ いつでも確認を出す
            showClearConfirm = true
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .foregroundStyle(.secondary)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("今回分の固定パックを消す（先生）")
    }

    @ViewBuilder
    private var thirdRow: some View {
        HStack(spacing: 10) {
            ToggleButton(
                title: "▶︎ 宿題あり",
                isOn: hw.status == .active,
                onTap: { hw.setActive() },
                color: .green
            )
            
            ToggleButton(
                title: "⏸ ストップ",
                isOn: hw.status == .paused,
                onTap: { hw.setPaused() },
                color: .orange
            )
            
            ToggleButton(
                title: "⛔️ 宿題なし",
                isOn: hw.status == .none,
                onTap: { hw.setNone() },
                color: .red
            )
            
            Button("+1週延長") {
                guard teacher.unlocked else { return }   // ←薄くしない保険
                hw.extendOneWeek()
            }
            .buttonStyle(.borderedProminent) // これは固定でOK
            .tint(hw.isExtended ? Color.yellow.opacity(0.85) : Color.gray.opacity(0.25))
            .foregroundColor(hw.isExtended ? .black : .primary)
            .overlay(alignment: .trailing) {
                if let t = hw.extensionLabel {
                    Text(t)
                        .font(.caption2)
                        .foregroundStyle(.blue)
                        .padding(.leading, 8)
                        .offset(x: 6, y: 0)
                }
            }
        }
        .allowsHitTesting(teacher.unlocked)  // ←生徒は“反応ゼロ”
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
    @Binding var confirmEntry: HomeworkEntry?

    @State private var showingImporter = false
    @State private var showingImportAlert = false
    @State private var importMessage: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack {
                NavigationLink("履歴をすべて見る") {
                    HomeworkHistoryList()
                        .environmentObject(hw)
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

            // ✅ 即反映
            hw.applyImportedPayload(payload)
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

        .navigationDestination(item: $pushEntry) { e in
            HomeworkHistoryWordsView(entry: e)
                .environmentObject(hw)
        }

        // ✅ isPresented: .constant(...) だと挙動が微妙になるので Bindingで出す
        .alert("この日の宿題を見ますか？", isPresented: Binding(
            get: { confirmEntry != nil },
            set: { if !$0 { confirmEntry = nil } }
        )) {
            Button("見る") {
                if let e = confirmEntry {
                    pushEntry = e
                }
                confirmEntry = nil
            }
            Button("キャンセル", role: .cancel) {
                confirmEntry = nil
            }
        } message: {
            Text("履歴の宿題（24語）を開きます。")
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
        .environmentObject(TeacherMode.shared) // private init 対策
}

#Preview("RecentWidget") {
    NavigationStack {
        HomeworkRecentWidget(confirmEntry: .constant(nil))
            .environmentObject(HomeworkState())
    }
}

// MARK: - JSON FileDocument（同居OK）

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
