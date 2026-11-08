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
    let onExitBulkEditing: (() -> Void)?

    init(
        pos: PartOfSpeech,
        word: String,
        onExitBulkEditing: (() -> Void)? = nil
    ) {
        self.pos = pos
        self.word = word
        self.onExitBulkEditing = onExitBulkEditing
    }

    @Environment(\.dismiss) private var dismiss
    struct Draft: Identifiable {
        let id = UUID()
        var meaning: String = ""
        var en: String = ""
        var ja: String = ""
    }
    
    private var bundledNoteText: String {
        ExampleStore.shared.bundledWordNote(
            pos: pos,
            word: word
        )
    }

    private var bundledMeanings: [String] {
        HomeworkStore.shared.existingMeanings(
            for: word,
            pos: pos
        )
        .filter { meaning in
            ExampleStore.shared.bundledFirstExample(
                pos: pos,
                word: word,
                meaning: meaning
            ) != nil
        }
    }

    @State private var drafts: [Draft] = [Draft()]
    @State private var wordNoteText: String = ""
    @State private var showOverwriteAlert = false
    @State private var showExitBulkAlert = false

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

                // 🔒 アプリ収録内容
                if !bundledNoteText.isEmpty || !bundledMeanings.isEmpty {
                    Section {
                        if !bundledNoteText.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("単語ノート")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text(bundledNoteText)
                            }
                        }

                        ForEach(bundledMeanings, id: \.self) { meaning in
                            if let example = ExampleStore.shared.bundledFirstExample(
                                pos: pos,
                                word: word,
                                meaning: meaning
                            ) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(meaning)
                                        .font(.subheadline.weight(.semibold))

                                    Text(example.en)

                                    if let ja = example.ja,
                                       !ja.isEmpty {
                                        Text(ja)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } header: {
                        Label(
                            "収録内容（変更不可）",
                            systemImage: "lock.fill"
                        )
                    }
                }

                // ユーザー補足ノート
                Section("補足ノート") {
                    TextEditor(text: $wordNoteText)
                        .frame(minHeight: 140)
                }

                // ユーザー補足の意味＋例文
                ForEach($drafts) { $d in
                    Section {
                        TextField(
                            "意味（例：〜を管理する）",
                            text: $d.meaning
                        )

                        Divider()
                            .padding(.vertical, 2)

                        TextField(
                            "English sentence",
                            text: $d.en
                        )
                        .textInputAutocapitalization(.sentences)

                        TextField(
                            "日本語訳（任意）",
                            text: $d.ja
                        )
                    } header: {
                        HStack {
                            Text("補足の意味＋例文")
                            Spacer()

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

                // 左：通常編集では「戻る」／宿題の連続編集では「編集を終了」
                ToolbarItem(placement: .navigationBarLeading) {
                    if onExitBulkEditing != nil {
                        Button("編集を終了") {
                            showExitBulkAlert = true
                        }
                    } else {
                        Button("戻る") {
                            dismiss()
                        }
                    }
                }

                // 右：意味ブロック追加
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        drafts.append(Draft())
                    } label: {
                        Text("＋ 意味追加")
                    }
                }

                // 右：保存
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        print("🧪 ExampleEditor save target pos=\(pos.rawValue) word=\(word) note=[\(wordNoteText)]")
                        attemptSave()
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
            .alert(
                "カード裏面の編集を終了しますか？",
                isPresented: $showExitBulkAlert
            ) {
                Button("続ける", role: .cancel) { }

                Button("終了する", role: .destructive) {
                    onExitBulkEditing?()
                }
            } message: {
                Text("ここまで保存した内容は保持されます。この画面でまだ保存していない変更は保存されません。")
            }
        }
    }

    // MARK: - Load

    private func loadExisting() {
        // ユーザー補足の単語ノートだけを読む
        wordNoteText = ExampleStore.shared.wordNote(
            pos: pos,
            word: word
        )

        // 既存 meaning を HomeworkStore から拾う
        let meanings = HomeworkStore.shared.existingMeanings(
            for: word,
            pos: pos
        )

        if meanings.isEmpty {
            drafts = [Draft()]
            initialWordNoteText = normalizedText(wordNoteText)
            initialDraftsSnapshot = makeDraftSnapshots(from: drafts)
            return
        }

        drafts = meanings.map { meaning in
            let ex = ExampleStore.shared.userFirstExample(
                pos: pos,
                word: word,
                meaning: meaning
            )

            return Draft(
                meaning: meaning,
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

        // 🦌 その他品詞：
        // 編集開始時にはあったのに、保存時には消えているmeaningを削除
        if pos == .others {
            let initialMeanings = Set(
                initialDraftsSnapshot
                    .map { normalizedText($0.meaning) }
                    .filter { !$0.isEmpty }
            )

            let currentMeanings = Set(
                drafts
                    .map { normalizedText($0.meaning) }
                    .filter { !$0.isEmpty }
            )

            let removedMeanings = initialMeanings.subtracting(currentMeanings)

            for meaning in removedMeanings {
                let didDelete = HomeworkStore.shared.deleteOtherMeaning(
                    word: word,
                    meaning: meaning
                )

                // HomeworkStoreから本当に削除できたmeaningだけ、
                // 対応する例文も削除する
                if didDelete {
                    ExampleStore.shared.removeExample(
                        pos: pos,
                        word: word,
                        meaning: meaning
                    )
                }
            }
        }

        // ✅ 単語ノート（全体）を保存（空なら削除）
        let wn = wordNoteText.trimmingCharacters(in: .whitespacesAndNewlines)

        ExampleStore.shared.saveWordNote(
            pos: pos,
            word: word,
            note: wn.isEmpty ? nil : wn
        )

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

    private func removeDraft(id: UUID) {
        drafts.removeAll { $0.id == id }
        if drafts.isEmpty { drafts = [Draft()] }
    }
}
#Preview {
    ExampleEditorView(pos: .noun, word: "test")
}

