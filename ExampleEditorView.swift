//
//  ExampleEditorView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/23.　(12/17 .jason)→(2026/01/30カード裏面のnote1つに変更版)
//
import SwiftUI

struct ExampleEditorView: View {

    let pos: PartOfSpeech
    let word: String

    @Environment(\.dismiss) private var dismiss

    struct Draft: Identifiable {
        let id = UUID()
        var meaning: String = ""
        var en: String = ""
        var ja: String = ""
    }

    @State private var drafts: [Draft] = [Draft()]
    @State private var wordNoteText: String = ""

    var body: some View {
        NavigationStack {
            Form {

                // 先頭：単語
                Section {
                    HStack {
                        Text("単語")
                        Spacer()
                        Text(word)
                            .foregroundStyle(.secondary)
                    }
                }

                // ✅ 単語ノート（全体）
                Section("単語ノート（全体）") {
                    TextEditor(text: $wordNoteText)
                        .frame(minHeight: 140)
                }

                // 意味ブロック（縦に増える）
                ForEach($drafts) { $d in
                    Section {
                        TextField("意味（例：〜を管理する）", text: $d.meaning)

                        Divider().padding(.vertical, 2)

                        TextField("English sentence", text: $d.en)
                            .textInputAutocapitalization(.sentences)

                        TextField("日本語訳（任意）", text: $d.ja)
                    } header: {
                        HStack {
                            Text("意味＋例文")
                            Spacer()

                            // 意味ブロック削除（1個しかない時は出さない）
                            if drafts.count > 1 {
                                Button {
                                    removeDraft(id: d.id)
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle("例文を編集")
            .toolbar {

                // 左：戻る
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("戻る") { dismiss() }
                }

                // 右：＋（meaningブロック追加）
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        drafts.append(Draft())
                    } label: {
                        Label("追加", systemImage: "plus")
                    }
                }

                // 右：保存
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        saveAll()
                        dismiss()
                    }
                }

                // 下：この単語の例文を全部消したい時（安全のため meaning 空は触らない）
                ToolbarItem(placement: .bottomBar) {
                    Button("この単語の例文を削除（入力済みmeaningのみ）", role: .destructive) {
                        removeAllExamplesForFilledMeanings()
                        dismiss()
                    }
                }
            }
            .onAppear { loadExisting() }
        }
    }

    // MARK: - Load

    private func loadExisting() {
        // ✅ 単語ノート（全体）を読む
        wordNoteText = ExampleStore.shared.wordNote(pos: pos, word: word) ?? ""

        // 既存 meaning を HomeworkStore から拾う（複数意味の“正”はここ）
        let meanings = HomeworkStore.shared.existingMeanings(for: word, pos: pos)

        if meanings.isEmpty {
            drafts = [Draft()]
            return
        }

        drafts = meanings.map { m in
            let ex = ExampleStore.shared.firstExample(pos: pos, word: word, meaning: m)
            return Draft(
                meaning: m,
                en: ex?.en ?? "",
                ja: ex?.ja ?? ""
            )
        }
    }

    // MARK: - Save

    private func saveAll() {
        // ✅ 単語ノート（全体）を保存（空なら削除）
        let wn = wordNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        ExampleStore.shared.saveWordNote(pos: pos, word: word, note: wn.isEmpty ? nil : wn)

        for d in drafts {
            let meaning = d.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
            if meaning.isEmpty { continue }

            // ① meaning を HomeworkStore に追加（重複は add() 側が弾く）
            _ = HomeworkStore.shared.add(word: word, meaning: meaning, pos: pos)

            // ② 例文（全部空なら“削除”扱いにする）
            let enT = d.en.trimmingCharacters(in: .whitespacesAndNewlines)
            let jaT = d.ja.trimmingCharacters(in: .whitespacesAndNewlines)

            let hasAny = !enT.isEmpty || !jaT.isEmpty
            if hasAny {
                ExampleStore.shared.saveExample(
                    pos: pos,
                    word: word,
                    meaning: meaning,
                    en: enT,
                    ja: jaT.isEmpty ? nil : jaT,
                    note: nil // ✅ note は単語全体に集約
                )
            } else {
                ExampleStore.shared.removeExample(pos: pos, word: word, meaning: meaning)
            }
        }
    }

    private func removeAllExamplesForFilledMeanings() {
        for d in drafts {
            let meaning = d.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
            if meaning.isEmpty { continue }
            ExampleStore.shared.removeExample(pos: pos, word: word, meaning: meaning)
        }
    }

    private func removeDraft(id: UUID) {
        drafts.removeAll { $0.id == id }
        if drafts.isEmpty { drafts = [Draft()] }
    }
}

#Preview {
    ExampleEditorView(pos: .noun, word: "test")
}
