//
//  SandboxView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/16.
//
import SwiftUI

struct SandboxView: View {
    @State private var count = 0
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Sandbox").font(.title2)
                Text("Count: \(count)")
                Button("増やす") { count += 1 }
            }
            .padding()
            .navigationTitle("実験室")
        }
    }
}

#Preview {
    SandboxView()
}
