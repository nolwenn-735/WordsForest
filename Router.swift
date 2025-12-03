//
//  RouterOfHome.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/24.

// RouterOfHome.swift

import SwiftUI

final class Router: ObservableObject {
    @Published var path = NavigationPath()

    /// 任意の Hashable を push する
    func push<T: Hashable>(_ value: T) {
        path.append(value)
    }

    /// ルートに戻る（すべてのスタックをクリア）
    func reset() {
        path = NavigationPath()
    }

    /// 「ホームへ戻る」動作用のラッパー
    func goHome() {
        reset()
    }
}
