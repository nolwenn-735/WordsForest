//
//  ExampleStore.swift 2026/02/16全置換版
//  WordsForest
//
import Foundation

/// 単語＋意味ごとの例文を保存する（Teacher編集用）
final class ExampleStore: ObservableObject {

    static let shared = ExampleStore()

    /// key = "pos|word|meaning" → [ExampleEntry]
    @Published private(set) var examples: [String: [ExampleEntry]] = [:]

    /// ✅ 単語ノート（meaningに依存しない）
    /// key = "pos|word" → note
    @Published private(set) var wordNotes: [String: String] = [:]

    private let key = "example_store_v2"
    private let notesKey = "word_notes_v1"

    private init() {
        load()
        loadNotes()
    }

    // MARK: - Normalize / Key

    private func normWord(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func normMeaning(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func makeKey(pos: PartOfSpeech, word: String, meaning: String) -> String {
        "\(pos.rawValue)|\(normWord(word))|\(normMeaning(meaning))"
    }

    private func makeWordKey(pos: PartOfSpeech, word: String) -> String {
        "\(pos.rawValue)|\(normWord(word))"
    }

    // MARK: - CRUD（意味ごと）

    /// 1 meaning = 1例文（上書き）
    /// ✅ noteは「単語ノート」に寄せる（meaning分裂させない）
    func saveExample(pos: PartOfSpeech,
                     word: String,
                     meaning: String,
                     en: String,
                     ja: String?,
                     note: String?) {

        let k = makeKey(pos: pos, word: word, meaning: meaning)

        #if DEBUG
        if word.lowercased() == "run" {
            print("🟩 saveExample word=\(word) meaning=[\(meaning)] en=[\(en)] ja=[\(ja ?? "")] note=[\(note ?? "")]")
        }
        #endif

        // 例文はmeaningごとに保存（ExampleEntry.noteは使わない）
        examples[k] = [ExampleEntry(en: en, ja: ja, note: nil)]
        save()

        // noteは単語単位で保存
        // ✅ 空/nil のときは既存ノートを消さない（例文保存でノートを巻き添え削除しない）
        if let note {
            let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                saveWordNote(pos: pos, word: word, note: trimmed)
            }
        }
    }
    
    func removeExample(pos: PartOfSpeech, word: String, meaning: String) {
        let k = makeKey(pos: pos, word: word, meaning: meaning)
        examples[k] = []
        save()
    }

    func examples(pos: PartOfSpeech, word: String, meaning: String) -> [ExampleEntry] {
        let k = makeKey(pos: pos, word: word, meaning: meaning)
        return examples[k] ?? []
    }

    func firstExample(pos: PartOfSpeech, word: String, meaning: String) -> ExampleEntry? {
        examples(pos: pos, word: word, meaning: meaning).first
    }

    // ✅ 互換：meaning未指定（暫定表示/Export用に1個返す）
    func firstExample(pos: PartOfSpeech, word: String) -> ExampleEntry? {
        let prefix = "\(pos.rawValue)|\(normWord(word))|"
        let keys = examples.keys.filter { $0.hasPrefix(prefix) }.sorted()
        for k in keys {
            if let e = examples[k]?.first { return e }
        }
        return nil
    }

    // MARK: - ✅ 単語ノート（wordNotes）

    func saveWordNote(pos: PartOfSpeech, word: String, note: String?) {
        let k = makeWordKey(pos: pos, word: word)
        let trimmed = (note ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

#if DEBUG
let lw = word.lowercased()
if lw == "run" || lw == "look" {
    print("🟩 saveWordNote word=\(word) key=\(k) trimmed=[\(trimmed)]")
}
#endif

        if trimmed.isEmpty {
            wordNotes.removeValue(forKey: k)
        } else {
            wordNotes[k] = trimmed
        }
        saveNotes()

#if DEBUG
let lw2 = word.lowercased()
if lw2 == "run" || lw2 == "look" {
    print("🟩 wordNotes.count(after save)=\(wordNotes.count)")
    print("🟩 wordNotes[k] after save = [\(wordNotes[k] ?? "(nil)")]")
    print("🟩 all wordNotes.keys = \(wordNotes.keys.sorted())")
}
#endif
        
    }

    /// 空なら "" を返す（UI側が楽）
    func wordNote(pos: PartOfSpeech, word: String) -> String {
        wordNotes[makeWordKey(pos: pos, word: word)] ?? ""
    }

    // MARK: - Save / Load（examples）

    private func save() {
        if let data = try? JSONEncoder().encode(examples) {
            UserDefaults.standard.set(data, forKey: key)
            NotificationCenter.default.post(name: .examplesDidChange, object: nil)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: [ExampleEntry]].self, from: data) {
            examples = decoded
        }
    }

    // MARK: - Save / Load（wordNotes）

    private func saveNotes() {
        if let data = try? JSONEncoder().encode(wordNotes) {
            UserDefaults.standard.set(data, forKey: notesKey)
            // 表示更新したいなら同じ通知でOK
            NotificationCenter.default.post(name: .examplesDidChange, object: nil)
        }
    }

    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: notesKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            wordNotes = decoded
        }
            
#if DEBUG
            let debugKey = makeWordKey(pos: .verb, word: "run")
            let debugRunNote = wordNotes[debugKey] ?? "(nil)"
            print("🟨 loadNotes notesKey=\(notesKey)")
            print("🟨 debugKey(run,verb)=\(debugKey)")
            print("🟨 wordNotes.count=\(wordNotes.count)")
            print("🟨 loaded run note=[\(debugRunNote)]")
            print("🟨 wordNotes.keys=\(wordNotes.keys.sorted())")
            print("🟨 wordNotes.all=\(wordNotes)")
#endif
        }
    }
extension Notification.Name {
    static let examplesDidChange = Notification.Name("examplesDidChange")
}

// =======================================================
// MARK: - Import merge（宿題JSON → ExampleStore 反映）
// =======================================================

extension ExampleStore {

    /// 宿題JSONに含まれる「例文」「単語ノート」を ExampleStore に取り込む
    /// - preferPayload: true なら payload を優先して上書き（空のときは上書きしない）
    func mergeImportedPayload(_ payload: HomeworkExportPayload, preferPayload: Bool = true) {

        func trim(_ s: String?) -> String {
            (s ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        for item in payload.items {
#if DEBUG
let dbgWord = item.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
if dbgWord == "run" || dbgWord == "look" {
    print("🟪 mergeImportedPayload item word=\(item.word) pos=\(item.pos) note=[\(item.note ?? "")] meanings=\(item.meanings)")
}
#endif
            guard let pos = PartOfSpeech(rawValue: item.pos) else { continue }

            // ---------------------------
            // ① 単語ノート（全体）
            // ---------------------------
            let incomingNote = trim(item.note)

            if !incomingNote.isEmpty {
                // ⚠️ ここは ExampleStore.wordNote の戻り型に合わせてどちらかにしてね：
                // A) wordNote が String? の場合:
                // let existing = trim(self.wordNote(pos: pos, word: item.word))
                //
                // B) wordNote が String の場合（いま ExampleEditorView 側のエラー的にこっちっぽい）:
                let existing = self.wordNote(pos: pos, word: item.word).trimmingCharacters(in: .whitespacesAndNewlines)

                if preferPayload || existing.isEmpty {
#if DEBUG
if dbgWord == "run" || dbgWord == "look" {
    print("🟪 mergeImportedPayload -> saveWordNote word=\(item.word) incomingNote=[\(incomingNote)] preferPayload=\(preferPayload)")
}
#endif
                    self.saveWordNote(pos: pos, word: item.word, note: incomingNote)
                }
            }

            // ---------------------------
            // ② 例文（v2: meaningごと）
            // ---------------------------
            if !item.examplesByMeaning.isEmpty {
                for ex in item.examplesByMeaning {
                    mergeOneExample(
                        pos: pos,
                        word: item.word,
                        meaning: ex.meaning,
                        en: ex.en,
                        ja: ex.ja,
                        note: ex.note,
                        preferPayload: preferPayload
                    )
                }
                continue
            }

            // ---------------------------
            // ③ v1救済（代表例文が1個だけ）
            // ---------------------------
            if let ex1 = item.example {
                let m0 = trim(item.meanings.first)
                guard !m0.isEmpty else { continue }

                mergeOneExample(
                    pos: pos,
                    word: item.word,
                    meaning: m0,
                    en: ex1.en,
                    ja: ex1.ja,
                    note: ex1.note,
                    preferPayload: preferPayload
                )
            }
        }
    }

    // 1 meaning の例文を「上書き or 空だけ補完」で取り込む
    private func mergeOneExample(
        pos: PartOfSpeech,
        word: String,
        meaning: String,
        en: String,
        ja: String?,
        note: String?,
        preferPayload: Bool
    ) {
        func trim(_ s: String?) -> String {
            (s ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let m = trim(meaning)
        guard !m.isEmpty else { return }

        let enT = trim(en)
        let jaT = trim(ja)
        let noteT = trim(note)

        // payload が空なら「削除」扱いにはしない（既存を守る）
        let incomingHasAny = !enT.isEmpty || !jaT.isEmpty || !noteT.isEmpty
        guard incomingHasAny else { return }

        let existing = self.firstExample(pos: pos, word: word, meaning: m)

        // 既存が無い or 既存が空っぽ なら必ず入れる
        if existing == nil {
            self.saveExample(
                pos: pos,
                word: word,
                meaning: m,
                en: enT,
                ja: jaT.isEmpty ? nil : jaT,
                note: nil
            )
            return
        }

        // 既存がある場合：
        // preferPayload=true なら payload で上書き（ただし payload が空のフィールドは消さない）
        if preferPayload, let ex = existing {
            let finalEn = enT.isEmpty ? ex.en : enT
            let finalJa = jaT.isEmpty ? ex.ja : jaT
            

            self.saveExample(
                pos: pos,
                word: word,
                meaning: m,
                en: finalEn,
                ja: (finalJa ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : finalJa,
                note: nil
            )
            return
        }

        // preferPayload=false（既存優先）なら「空だけ補完」
        if let ex = existing {
            var finalEn = ex.en
            var finalJa = ex.ja

            if trim(ex.en).isEmpty, !enT.isEmpty { finalEn = enT }
            if trim(ex.ja).isEmpty, !jaT.isEmpty { finalJa = jaT }

            self.saveExample(
                pos: pos,
                word: word,
                meaning: m,
                en: finalEn,
                ja: trim(finalJa).isEmpty ? nil : finalJa,
                note: nil
            )
        }
    }
}
