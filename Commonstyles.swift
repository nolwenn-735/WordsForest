//
//  Commonstyles.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/05.
//


import SwiftUI

// MARK: - Palette (共通色)
extension Color {
    static let homeIvory = Color(red: 0.99, green: 0.95, blue: 0.86)
}

// MARK: - 共通ボタンスタイルなど

// 例: Commonstyles.swift
struct ColoredPillButtonStyle: ButtonStyle {
    enum Size { case regular, compact }
    var color: Color
    var size: Size = .regular
    var alpha: Double = 0.22

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .lineLimit(1)
            .minimumScaleFactor(0.9)      // 長い文言でも1行で少しだけ縮小
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Capsule()
                    .fill(color.opacity(configuration.isPressed ? alpha + 0.08 : alpha))
        )
            .overlay(Capsule().stroke(color.opacity(0.35)))
            .foregroundStyle(.primary)
    }
}
