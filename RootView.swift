//
//  RootView.swift
//  WordsForest
//
//  Created by Nami .T on 2026/01/29.
//  RootView.swift

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var hw: HomeworkState

    @AppStorage(DefaultsKeys.usageModeConfigured)
    private var usageModeConfigured: Bool = false

    @AppStorage(DefaultsKeys.usageMode)
    private var usageMode: UsageMode = .classroom

    @State private var showCover = true

    var body: some View {
        ZStack {
            NavigationStack(path: $router.path) {
                HomePage()
                    .navigationDestination(for: PartOfSpeech.self) { pos in
                        POSFlashcardListView(
                            pos: pos,
                            accent: pos.accentColor,
                            animalName: pos == .others
                                ? pos.dailyAnimalName
                                : pos.animalName(forCycle: hw.variantIndex(for: pos))
                        )
                    }
            }

            if !showCover && !usageModeConfigured {
                UsageModeSetupView()
                    .background(Color(.systemBackground))
                    .ignoresSafeArea()
                    .zIndex(9)
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
