//
//  Commonstyles.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/05.
//


import SwiftUI


// MARK: - 共通ボタンスタイルなど

// 例: Commonstyles.swift
import SwiftUI

struct ColoredPillButtonStyle: ButtonStyle {
    enum Size { case regular, compact }

    var color: Color
    var size: Size = .regular
    var alpha: Double = 0.22

    func makeBody(configuration: Configuration) -> some View {
        PillBody(
            configuration: configuration,
            color: color,
            size: size,
            alpha: alpha
        )
    }

    private struct PillBody: View {
        let configuration: Configuration
        let color: Color
        let size: Size
        let alpha: Double

        @Environment(\.colorScheme) private var colorScheme

        var body: some View {
            configuration.label
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .padding(.vertical, size == .compact ? 8 : 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Capsule()
                        .fill(color.opacity(configuration.isPressed ? alpha + 0.08 : alpha))
                )
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.35), lineWidth: 1)
                )
                .foregroundStyle(textColor)
        }

        private var textColor: Color {
            colorScheme == .dark ? .white : .primary
        }
    }
}
