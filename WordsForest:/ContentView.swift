import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @State private var page = 0

    // ✅ 受け取るだけ（作らない！）
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var hw: HomeworkState
    @EnvironmentObject private var teacher: TeacherMode

    var body: some View {
        TabView(selection: $page) {
            CoverPageView()
                .tag(0)

            HomePage()
                .tag(1)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

        // ✅ 白帯保険：TabView側の地を埋める（各ページ背景が薄色/半透明だと効く）
        .background(Color(.systemBackground).ignoresSafeArea())

        // ✅ 60分ロックの期限チェック（復帰時）
        #if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            teacher.refreshLockState()
        }
        #endif
    }
}
