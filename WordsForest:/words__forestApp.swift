//
//  words__forestApp.swift
//  words' forest
//
//  Created by Nami .T on 2025/08/24.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@main
struct words__forestApp: App {
    @StateObject private var router = Router()
    @StateObject private var hw = HomeworkState()
    @StateObject private var teacher = TeacherMode.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .environmentObject(hw)
                .environmentObject(ColumnStore.shared)
                .environmentObject(teacher)

                // ✅ 解除シートは「ここに1個だけ」
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
}
