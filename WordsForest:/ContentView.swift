import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @State private var page = 0

    @StateObject private var router = Router()
    @StateObject private var hw = HomeworkState()

    // ✅ 追加：TeacherMode を全体に配る
    @StateObject private var teacher = TeacherMode.shared

    var body: some View {
        TabView(selection: $page) {
            CoverPageView()
                .environmentObject(router)
                .environmentObject(hw)
                .environmentObject(teacher)   // ✅ 追加
                .tag(0)

            HomePage()
                .environmentObject(router)
                .environmentObject(hw)
                .environmentObject(teacher)   // ✅ 追加
                .tag(1)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .ignoresSafeArea(.container, edges: .all)

        // ✅ 解除シートはここで一括管理（どの画面でも出せる）
        .sheet(isPresented: $teacher.showingUnlockSheet) {
            TeacherUnlockSheet()
                .environmentObject(teacher)
        }

        // ✅ 60分ロックの期限チェック（復帰時に自動ロックしたい場合）
        #if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            teacher.refreshLockState()
        }
        #endif
    }
}
