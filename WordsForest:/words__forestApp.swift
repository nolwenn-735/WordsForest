//
//  words__forestApp.swift
//  words' forest
//
//  Created by Nami .T on 2025/08/24.
//

import SwiftUI

@main
struct words__forestApp: App {
    @StateObject private var homework = HomeworkState()

    var body: some Scene {
        WindowGroup {
            ContentView() // ←あなたの最初のルートビュー名
                .environmentObject(homework)
        }
    }
}
