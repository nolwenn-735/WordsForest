//
//  words__forestApp.swift
//  words' forest
//
//  Created by Nami .T on 2025/08/24.
//

// words__forestApp.swift
import SwiftUI

@main
struct words__forestApp: App {
    @StateObject private var router = Router()
    @StateObject private var hw = HomeworkState()
    // ✅ 追加：TeacherMode を1個だけ作って全体に流す
    @StateObject private var teacher = TeacherMode.shared

    @State private var showCover = true

    var body: some Scene {
        WindowGroup {
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
            .environmentObject(router)
            .environmentObject(hw)

            // ❌ .environmentObject(Teacher) は消す（Teacherなんて変数が無い）
            .environmentObject(teacher)   // ✅ これが正解

            // ✅ 解除シートは「ここに1個だけ」置くのが一番事故らない
            .sheet(isPresented: $teacher.showingUnlockSheet) {
                TeacherUnlockSheet()
                    .environmentObject(teacher)
            }

            .fullScreenCover(isPresented: $showCover) {
                CoverPageView { showCover = false }
            }
        }
    }
}
