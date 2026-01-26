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
    @StateObject private var teacher = TeacherMode.shared
    @StateObject private var columnStore = ColumnStore.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                ContentView()
                    .navigationDestination(for: PartOfSpeech.self) { pos in
                        POSFlashcardListView(
                            pos: pos,
                            accent: pos.accentColor,
                            animalName: pos.animalName(forCycle: hw.variantIndex(for: pos))
                        )
                    }
            }
            .environmentObject(router)
            .environmentObject(hw)
            .environmentObject(teacher)
            .environmentObject(columnStore)

            // 解除シートはアプリで1個だけ管理（事故らない）
            .sheet(isPresented: $teacher.showingUnlockSheet) {
                TeacherUnlockSheet()
                    .environmentObject(teacher)
            }
        }
    }
}
