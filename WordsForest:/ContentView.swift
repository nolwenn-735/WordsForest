import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @State private var page = 0

    @EnvironmentObject private var router: Router
    @EnvironmentObject private var hw: HomeworkState
    @EnvironmentObject private var teacher: TeacherMode

    var body: some View {

        TabView(selection: $page) {

            // =========================
            // 表紙
            // =========================
            ZStack {
                // ✅ ここは「完全不透明」の表紙色で塗る（薄すぎて白に見える事故を防ぐ）
                Color.coverMintA.ignoresSafeArea()

                CoverPageView {
                    withAnimation(.easeInOut) { page = 1 }
                }
            }
            .tag(0)

            // =========================
            // Home（NavigationStackはHome側だけ）
            // =========================
            ZStack {
                // ✅ Homeの背景も、タブの最背面で safe area まで塗る
                Color.homeIvory.ignoresSafeArea()

                NavigationStack(path: $router.path) {
                    HomePage()
                        .navigationDestination(for: PartOfSpeech.self) { pos in
                            POSFlashcardListView(
                                pos: pos,
                                accent: pos.accentColor,
                                animalName: pos.animalName(
                                    forCycle: hw.variantIndex(for: pos)
                                )
                            )
                        }
                }
            }
            .tag(1)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

        // ✅ 解除シートはContentViewで一括管理
        .sheet(isPresented: $teacher.showingUnlockSheet) {
            TeacherUnlockSheet()
                .environmentObject(teacher)
        }

        #if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            teacher.refreshLockState()
        }
        #endif
    }
}
