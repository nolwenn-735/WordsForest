

//HomeworkUI.swift

import SwiftUI
import Foundation
import UniformTypeIdentifiers

struct HomeworkBanner: View {
    @EnvironmentObject var hw: HomeworkState
    @EnvironmentObject var teacher: TeacherMode

    // ✅ 追加：書き出し結果のURL（ShareLink用）
    @State private var exportedURL: URL? = nil
    @State private var exportErrorMessage: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // 1段目：📘今サイクル + 動詞＋副詞（ここは上段）
            // 2段目：🔒Teacher（元のペア位置） + 1週間（ここ） + デバッグ
            // ✅ 左カラム幅を固定して、(動詞＋副詞) と (1週間) を縦に揃える

            let leftColWidth: CGFloat = 84   // ← ここを 88〜100 くらいで微調整してOK

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
                    .frame(width: leftColWidth, alignment: .leading) // ← これで上段と左端を揃える

                    pill(hw.daysPerCycle == 14 ? "2週間" : "1週間")
                  
                    // ✅ Teacher解除時だけ「書き出し」
                    if teacher.unlocked {
                        if let url = exportedURL {
                            ShareLink(item: url) {
                                Label("書き出し", systemImage: "square.and.arrow.up")
                                    .font(.caption2)
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button {
                                do {
                                    let url = try HomeworkExportFile.exportCurrentHomework(
                                        hw: hw,
                                        requiredCount: 10,
                                        totalCount: 24
                                    )
                                    exportedURL = url
                                    exportErrorMessage = nil
                                } catch {
                                    exportErrorMessage = error.localizedDescription
                                }
                            } label: {
                                Label("書き出し", systemImage: "doc.badge.plus")
                                    .font(.caption2)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                  

                    #if DEBUG
                    Button("ペア切替") { hw.advanceCycle() }
                        .font(.caption2)
                        .tint(.blue)
                        .lineLimit(1)
                    #endif

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
        .onAppear { hw.refresh() }
    }

    private func pill(_ t: String) -> some View {
        Text(t).padding(.vertical, 6).padding(.horizontal, 10)
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
                .padding(.vertical, 8).padding(.horizontal, 12)
                .background(isOn ? color.opacity(0.9) : Color.white)
                .foregroundColor(isOn ? .white : .black)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}




struct HomeworkRecentWidget: View {
    @EnvironmentObject var hw: HomeworkState
    
    @State private var showingImporter = false
    @State private var importErrorMessage: String? = nil
    // ✅ 追加：成功/重複メッセージ用
    @State private var showingImportOK = false
    @State private var importOKMessage: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            HStack {
                          NavigationLink("履歴をすべて見る") {
                              HomeworkHistoryList()
                          }
                          .font(.callout)
                          .foregroundColor(.blue)

                          Spacer()

                          Button("🔵宿題取得") {
                              showingImporter = true
                          }
                          .font(.callout)
                          .buttonStyle(.bordered)
                          .tint(.blue)
                      }

                      ForEach(hw.history.prefix(4)) { e in
                          HStack {
                              Text(dateString(e.date))
                                  .foregroundColor(.secondary)
                              Text(e.titleLine)
                              Spacer()
                          }
                      }

            
            if let msg = importErrorMessage {
                Text("⚠️ \(msg)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.black.opacity(0.08), lineWidth: 1)
        )
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            do {
                let url = try result.get().first!
                
                let ok = url.startAccessingSecurityScopedResource()
                defer { if ok { url.stopAccessingSecurityScopedResource() } }
                
                let data = try Data(contentsOf: url)
                let payload = try JSONDecoder().decode(HomeworkExportPayload.self, from: data)
                
                // 既に取得済み？
                if hw.isAlreadyImported(payload: payload) {
                    importOKMessage = "最新の宿題は既に取得済みです。\n\n" + makeImportOKMessage(payload)
                    showingImportOK = true
                    return
                }
                
                // 通常取り込み
                try HomeworkPackStore.shared.importHomeworkPayload(payload, hw: hw)
                hw.addImportedToHistory(payload: payload)
                hw.markImported(payload: payload)
                
                importOKMessage = makeImportOKMessage(payload)
                showingImportOK = true
                importErrorMessage = nil
                
            } catch {
                importErrorMessage = error.localizedDescription
            }
        }
        .alert("宿題取得", isPresented: $showingImportOK) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importOKMessage)
        }
    }
}
private func makeImportOKMessage(_ payload: HomeworkExportPayload) -> String {
    // payload.createdAt は ISO8601 (例: 2025-12-17T00:00:00Z)
    let ymd = String(payload.createdAt.prefix(10)).replacingOccurrences(of: "-", with: "/")
    let pairLabel: String = (payload.pair == 0) ? "名詞＋形容詞" : "動詞＋副詞"
    return "\(ymd) の宿題（\(pairLabel)）を取得しました。"
}

struct HomeworkHistoryList: View {
    @EnvironmentObject var hw: HomeworkState
    var body: some View {
        List(hw.history) { e in
            VStack(alignment: .leading, spacing: 4) {
                Text(dateString(e.date)).font(.caption).foregroundColor(.secondary)
                Text(e.titleLine)
            }
        }
        .navigationTitle("宿題の履歴")
    }
}

// MARK: - Utilities
private func dateString(_ d: Date) -> String {
    let f = DateFormatter()
    f.locale = .current
    f.dateFormat = "yyyy/MM/dd"
    return f.string(from: d)
}
#Preview("Banner") {
    HomeworkBanner()
        .environmentObject(HomeworkState())
}

#Preview("履歴リスト") {
    NavigationStack {
        HomeworkHistoryList()
    }
    .environmentObject(HomeworkState())
}
