//
//  DebugCenterView.swift
//  WordsForest
//
//  Created by Nami .T on 2026/01/19.
//

import SwiftUI

#if DEBUG
struct DebugCenterView: View {
    @EnvironmentObject private var hw: HomeworkState

    var body: some View {
        List {
            Section("履歴（安全）") {
                Button("履歴のゴミだけ掃除") {
                    hw.debugPruneHistory()
                }
            }

            Section("宿題（注意）") {
                Button("履歴を全消去") {
                    hw.debugClearHistory()
                }

                Button("キャッシュ（今サイクル表示用）だけ消す") {
                    hw.debugClearCachedHomeworkOnly()
                }
            }

            Section("固定パック（危険）") {
                Button("固定パックを全消去") {
                    HomeworkPackStore.shared.debugClearAllPacks()
                }
            }
        }
        .navigationTitle("DEBUGセンター")
    }
}
#endif
