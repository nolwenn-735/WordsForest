//
//  AlphabetJumpControl.swift
//  WordsForest
//
//  Created by Nami .T on 2026/11/19.
//
//
//  AlphabetJumpControl.swift
//  WordsForest
//

import SwiftUI

struct AlphabetJumpControl: View {

    let words: [String]
    let onSelect: (String) -> Void

    @State private var isPresented = false

    static let alphabetLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map(String.init)

    static func initialLetter(of word: String) -> String? {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.uppercased().first else { return nil }

        let letter = String(first)
        return alphabetLetters.contains(letter) ? letter : nil
    }

    private var availableInitialLetters: Set<String> {
        Set(words.compactMap { Self.initialLetter(of: $0) })
    }

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Text("A–Z")
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
        }
        .modifier(AlphabetJumpGlassCapsuleButton())
        .frame(height: 44)
        .accessibilityLabel("頭文字へ移動")
        .popover(isPresented: $isPresented) {
            alphabetPopover
                .presentationCompactAdaptation(.popover)
        }
    }

    private var alphabetPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("頭文字へ移動")
                .font(.headline)

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 6),
                    count: 6
                ),
                spacing: 8
            ) {
                ForEach(Self.alphabetLetters, id: \.self) { letter in
                    let available = availableInitialLetters.contains(letter)

                    Button(letter) {
                        isPresented = false
                        onSelect(letter)
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 34)
                    .buttonStyle(.bordered)
                    .disabled(!available)
                    .opacity(available ? 1.0 : 0.28)
                }
            }
        }
        .padding(16)
        .frame(width: 286)
    }
}


// MARK: - Liquid Glass

private struct AlphabetJumpGlassCapsuleButton: ViewModifier {

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
        } else {
            content
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
        }
    }
}



