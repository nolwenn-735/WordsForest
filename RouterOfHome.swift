//
//  RouterOfHome.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/24.

// RouterOfHome.swift
import SwiftUI

final class Router: ObservableObject {
    @Published var path = NavigationPath()

    func goHome() {
        // ルート(Home)まで戻る
        path.removeLast(path.count)
    }

    func push<T: Hashable>(_ value: T) {
        path.append(value)
    }
}
