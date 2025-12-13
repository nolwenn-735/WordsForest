//
//  RepairHomeworkView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/11/30.
//

import SwiftUI

struct RepairHomeworkView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {

            Text("宿題セットの修復")
                .font(.title3)
                .padding(.top)

            Text("単語データ、My Collection、覚えたBOXはそのまま。\n宿題セット・サイクル情報だけ再構築します。")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button(role: .destructive) {
                HomeworkStore.shared.repairHomeworkSets()
                dismiss()
            } label: {
                Text("宿題セットを修復する")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(12)
            }
            
            Button {
                            HomeworkStore.shared.restoreMissingMarkedCards()
                        } label: {
                            Text("🛠 行方不明（✅/💗）を復元")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.15))
                                .cornerRadius(12)
                        }
            Button("🧹 保存データの意味を正規化（全角/半角など）") {
                HomeworkStore.shared.normalizeStoredMeaningsOnce()
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("宿題セット修復")
        .navigationBarTitleDisplayMode(.inline)
    }
}
