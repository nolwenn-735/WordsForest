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
    @StateObject private var hw = HomeworkState()   // ← 追加（または .shared があるならそれ）

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                HomePage()
            }
            .environmentObject(router)
            .environmentObject(hw)                  // ← これが大事
        }
    }
}
