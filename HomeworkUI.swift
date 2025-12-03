import SwiftUI
import Foundation

struct HomeworkBanner: View {
    @EnvironmentObject var hw: HomeworkState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("📘 今サイクル").font(.headline)

            HStack(spacing: 8) {
                pill(hw.currentPair == .nounAdj ? "名詞＋形容詞" : "動詞＋副詞")
                if hw.paused { pill("⏸ ストップ中") }
                pill(hw.daysPerCycle == 14 ? "2週間" : "1週間")
                

                    // ★ デバッグ専用（本番では消える）
                    #if DEBUG
                    Button("ペア切替テスト") {
                        hw.advanceCycle()   // 強制的に「名詞＋形容詞」↔「動詞＋副詞」に交互切替
                    }
                    .font(.caption2)
                    .tint(.blue)
                    #endif
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // 🔥 タイトルは HomePage 側にあるため、ここでは描かない！

            ForEach(hw.history.prefix(4)) { e in
                HStack {
                    Text(dateString(e.date))
                        .foregroundColor(.secondary)
                    Text(e.titleLine)
                    Spacer()
                }
            }

            NavigationLink("履歴をすべて見る") {
                HomeworkHistoryList()
            }
            .font(.callout)
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.black.opacity(0.08), lineWidth: 1)
        )
    }
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
