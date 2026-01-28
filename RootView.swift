//
//  RootView.swift
//  WordsForest
//
//  Created by Nami .T on 2026/01/29.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var hw: HomeworkState

    @State private var showCover = true

    var body: some View {
        ZStack {
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

            if showCover {
                CoverPageView {
                    // ✅ ここはアニメしない（CoverPageView内のスライドだけにする）
                    showCover = false
                }
                .ignoresSafeArea()
                .zIndex(10)
            }
        }
    }
}
