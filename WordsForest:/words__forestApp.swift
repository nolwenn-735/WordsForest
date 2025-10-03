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

    // 追加：表紙の表示フラグ
    @State private var showCover = true

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                HomePage()
                    // 遷移先はこれまで通りここに
                    .navigationDestination(for: PartOfSpeech.self) { pos in
                        POSFlashcardListView(
                            pos: pos,
                            accent: pos.accent,
                            animalName: pos.animalName(forCycle: hw.history.count)                
                            
                        )
                    }
            }
            .environmentObject(router)
            .environmentObject(hw)

            // ← ここに付ける（NavigationStack の“外側”）
            .fullScreenCover(isPresented: $showCover) {
                // CoverPage から呼ばれる閉じ処理を配線
                CoverPageView { showCover = false }
            }
        }
    }
}
    

