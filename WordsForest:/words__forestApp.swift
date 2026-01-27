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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
                .environmentObject(hw)
                .environmentObject(ColumnStore.shared)
                .environmentObject(teacher)
        }
    }
}
