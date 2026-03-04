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
    @State private var showOverwriteAlert = false

    // 初期ロード時のスナップショット（上書き判定用）
    @State private var initialWordNoteText: String = ""
    @State private var initialDraftsSnapshot: [DraftSnapshot] = []
    
    struct DraftSnapshot: Hashable {
        var meaning: String
        var en: String
        var ja: String
    }

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
                        print("🧪 ExampleEditor save target pos=\(pos.rawValue) word=\(word) note=[\(wordNoteText)]")
                        attemptSave()
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
            .alert("既にある内容を上書きしますか？", isPresented: $showOverwriteAlert) {
                Button("する", role: .destructive) {
                    saveAll()
                    dismiss()
                }
                Button("しない", role: .cancel) {
                    // 何もしない（既存のまま）
                }
            } message: {
                Text("この単語には既存の例文またはノートがあります。今回の入力内容を保存すると、その内容が上書きされます。")
            }
        }
    }

    // MARK: - Load

    private func loadExisting() {
        // ✅ 単語ノート（全体）を読む
        wordNoteText = ExampleStore.shared.wordNote(pos: pos, word: word) 

        // 既存 meaning を HomeworkStore から拾う（複数意味の“正”はここ）
        let meanings = HomeworkStore.shared.existingMeanings(for: word, pos: pos)

        if meanings.isEmpty {
            drafts = [Draft()]
            initialWordNoteText = normalizedText(wordNoteText)
            initialDraftsSnapshot = makeDraftSnapshots(from: drafts)
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
        initialWordNoteText = normalizedText(wordNoteText)
        initialDraftsSnapshot = makeDraftSnapshots(from: drafts)
    }
    
    
    private func attemptSave() {
        let hasExisting = hasAnyExistingContentNow()
        let isChangingExisting = hasOverwriteRiskComparedToInitial()

        if hasExisting && isChangingExisting {
            showOverwriteAlert = true
        } else {
            saveAll()
            dismiss()
        }
    }
    
    private func hasAnyExistingContentNow() -> Bool {
        // 単語ノート（既存）
        let existingNote = ExampleStore.shared.wordNote(pos: pos, word: word)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if !existingNote.isEmpty {
            return true
        }

        // 既存 meaning ごとの例文
        let meanings = HomeworkStore.shared.existingMeanings(for: word, pos: pos)
        for m in meanings {
            let meaning = m.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !meaning.isEmpty else { continue }

            if let ex = ExampleStore.shared.firstExample(pos: pos, word: word, meaning: meaning) {
                let en = ex.en.trimmingCharacters(in: .whitespacesAndNewlines)
                let ja = (ex.ja ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let note = (ex.note ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

                if !en.isEmpty || !ja.isEmpty || !note.isEmpty {
                    return true
                }
            }
        }

        return false
    }
    
    private func hasOverwriteRiskComparedToInitial() -> Bool {
        // 単語ノート差分（既存ノートがあって内容が変わる）
        let currentNote = normalizedText(wordNoteText)
        if !initialWordNoteText.isEmpty && currentNote != initialWordNoteText {
            return true
        }

        // meaningごとの例文差分（既存があるmeaningだけ確認）
        let currentMap = Dictionary(
            uniqueKeysWithValues: makeDraftSnapshots(from: drafts).map { ($0.meaning, $0) }
        )
        let initialMap = Dictionary(
            uniqueKeysWithValues: initialDraftsSnapshot.map { ($0.meaning, $0) }
        )

        for (meaning, initial) in initialMap {
            let initialHasAny = !initial.en.isEmpty || !initial.ja.isEmpty
            guard initialHasAny else { continue }

            let current = currentMap[meaning] ?? DraftSnapshot(meaning: meaning, en: "", ja: "")

            if current.en != initial.en || current.ja != initial.ja {
                return true
            }
        }

        return false
    }

    private func makeDraftSnapshots(from drafts: [Draft]) -> [DraftSnapshot] {
        drafts
            .map { d in
                DraftSnapshot(
                    meaning: normalizedText(d.meaning),
                    en: normalizedText(d.en),
                    ja: normalizedText(d.ja)
                )
            }
            .filter { !$0.meaning.isEmpty }
            .sorted { $0.meaning < $1.meaning }
    }

    private func normalizedText(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
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

