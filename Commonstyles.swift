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

struct ColoredPillButtonStyle: ButtonStyle {
    var color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(color.opacity(configuration.isPressed ? 0.85 : 1.0))
            .cornerRadius(12)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

