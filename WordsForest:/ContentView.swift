import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @State private var page = 0

    @EnvironmentObject private var router: Router
    @EnvironmentObject private var hw: HomeworkState
    @EnvironmentObject private var teacher: TeacherMode

    /// TabViewの“外側”に敷く背景（白帯対策）
    private var baseBackground: Color {
        page == 0
        ? Color(.systemGreen).opacity(0.20)   // 表紙の薄いグリーン
        : Color.homeIvory                    // Homeのアイボリー
    }

    var body: some View {
        ZStack {
            // ✅ ここが白帯を消す本体：TabViewより後ろで、画面全域を塗る
            baseBackground.ignoresSafeArea()

            TabView(selection: $page) {
                // 表紙
                CoverPageView {
                    // 表紙側で「開始」したらHomeへ（必要なら）
                    withAnimation(.easeInOut) { page = 1 }
                }
                .tag(0)

                // Home（NavigationStackはHome側だけに乗せる）
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
                .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }

        // ✅ 解除シートはContentViewで一括管理（どの画面でも出せる）
        .sheet(isPresented: $teacher.showingUnlockSheet) {
            TeacherUnlockSheet()
                .environmentObject(teacher)
        }

        // ✅ 60分ロックの期限チェック（復帰時）
        #if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            teacher.refreshLockState()
        }
        #endif
    }
}
