//
//  DisplaySettingView.swift
//  WordsForest
//
//  Created by Nami .T on 2026/05/04.
//

import SwiftUI

struct DisplaySettingsView: View {
    @AppStorage(DefaultsKeys.showMascots) private var showMascots: Bool = true

    var body: some View {
        Form {
            Section {
                Toggle("動物マスコットを表示", isOn: $showMascots)
                    .tint(.green)
            } footer: {
                Text("HomePage、単語カード画面に表示される動物マスコットを表示するかしないかを選べます。ライトモード、ダークモードの設定は、iPhone,iPadの⚙️設定から行えます。")
            }
        }
        .navigationTitle("表示設定")
    }
}
