//
//  SwiftUIView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/24.
//

import SwiftUI

struct AddWordView: View {
    let pos: PartOfSpeech
    var editing: WordCard? = nil   // ← 既存なら渡す（新規は nil）

    @Environment(\.dismiss) private var dismiss

    @State private var word: String = ""
    @State private var meaning: String = ""
    @State private var dupWord = false
    @State private var dupExact = false
    @State private var autoFillAfterSave = false

    // どこにカーソルを当てるか
    @FocusState private var focusedField: Field?

    private enum Field {
        case word, meaning
    }

    // トリムした値
    private var trimmedWord: String {
        word.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var trimmedMeaning: String {
        meaning.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // 保存できるかどうか
    private var canSave: Bool {
        !trimmedWord.isEmpty && !trimmedMeaning.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: 英単語
                Section("英単語") {
                    TextField("wander", text: $word)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .word)
                }

                // 重複のワーニング
                if dupWord {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(
                            dupExact ? "このカードは既にあります"
                                     : "この単語はこの品詞で登録済みです",
                            systemImage: dupExact ? "xmark.octagon.fill"
                                                  : "exclamationmark.triangle.fill"
                        )
                        .font(.footnote)
                        .foregroundStyle(dupExact ? .red : .orange)

                        if !dupExact {
                            let meanings = HomeworkStore.shared.existingMeanings(for: word, pos: pos)
                            if !meanings.isEmpty {
                                Text("既存の意味例：\(meanings.joined(separator: "、"))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.top, 4)
                    .animation(.default, value: dupWord || dupExact)
                }

                // MARK: 日本語の意味
                Section("日本語の意味") {
                    TextField("さまよう", text: $meaning)
                        .focused($focusedField, equals: .meaning)
                }

                // 新規追加のときだけ出すトグル
                if editing == nil {
                    Section {
                        Toggle("保存後に不足分を自動追加（24まで）", isOn: $autoFillAfterSave)
                            .tint(.orange)
                    }
                }
            }
            // 入力内容が変わったら重複チェック
            .onChange(of: word, initial: true) { _, _ in
                updateDupFlags()
            }
            .onChange(of: meaning) { _, _ in
                updateDupFlags()
            }
            .navigationTitle(editing == nil ? "単語を追加" : "単語を編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editing == nil ? "追加" : "更新") {
                        save()
                    }
                    .disabled(!canSave || dupExact)
                }
            }
            // 編集のときだけ下に「削除」
            .safeAreaInset(edge: .bottom) {
                if editing != nil {
                    Button("このカードを削除", role: .destructive) {
                        deleteCard()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .onAppear {
            // 既存カードなら値をセット
            if let c = editing {
                word = c.word
                meaning = c.meaning
                // 編集では意味のほうにフォーカス
                DispatchQueue.main.async {
                    focusedField = .meaning
                }
            } else {
                // 新規なら英単語にフォーカス
                DispatchQueue.main.async {
                    focusedField = .word
                }
            }
        }
    }

    // MARK: - 保存処理

    private func save() {
        if let c = editing {
            // 既存カードの更新
            HomeworkStore.shared.update(c,
                                        word: trimmedWord,
                                        meaning: trimmedMeaning)
        } else {
            // 新規追加
            let ok = HomeworkStore.shared.add(
                word: trimmedWord,
                meaning: trimmedMeaning,
                pos: pos
            )
            if ok, autoFillAfterSave {
                // 不足してたら埋める
                HomeworkStore.shared.autofill(for: pos, target: 24)
            }
        }
        dismiss()
    }

    // MARK: - 重複チェック

    private func updateDupFlags() {
        let w = trimmedWord
        let m = trimmedMeaning

        guard !w.isEmpty else {
            dupWord = false
            dupExact = false
            return
        }

        dupWord  = HomeworkStore.shared.exists(word: w, pos: pos)
        dupExact = HomeworkStore.shared.exists(word: w, meaning: m, pos: pos)
    }

    // MARK: - 削除

    private func deleteCard() {
        if let c = editing {
            HomeworkStore.shared.delete(c)
            dismiss()
        }
    }
}
