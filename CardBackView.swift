//
//
//  CardBackView.swift新仕様対応11/27デザイン版//(2025/12/07)(12/17複数意味対応）（2026/01/15書出し、編集、両対応）
//

import SwiftUI
import AVFoundation

/// 単語カード裏面（品詞ページ／宿題／My Collection／覚えたBOX 共通）
struct CardBackView: View {

    // MARK: - 入力データ
    let pos: PartOfSpeech
    let word: String
    let meanings: [String]
    let examples: [ExampleEntry]
    let note: String
    let irregularForms: [String]

    // MARK: - 状態（読み上げ & 編集）
    @EnvironmentObject private var teacher: TeacherMode

    @State private var speechSlow = false      // ゆっくり
    @State private var speakBoth  = true       // 英＋日
    @State private var showingEditor = false   // 例文編集シート

    private let synthesizer = AVSpeechSynthesizer()

    // MARK: - 本体
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // 見出し：単語 & 意味
            VStack(alignment: .leading, spacing: 6) {
                Text(displayTitle)
                    .font(.system(size: 26, weight: .bold))

                ForEach(meanings.indices, id: \.self) { idx in
                    Text("・\(meanings[idx])")
                        .font(.body)
                }
            }

            Divider().padding(.vertical, 4)

            // 上のボタン列：単語 読み上げ ＋ 編集ペン（先生のみ）
            HStack(spacing: 16) {
                Button(action: speakWord) {
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2.fill")
                        Text("単語")
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)

                Spacer()

                if teacher.unlocked {
                    Button(action: { showingEditor = true }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(.secondary)
                            .opacity(0.7)
                    }
                    .buttonStyle(.plain)
                }
            }
            .font(.subheadline)

            // 例文表示
            if meanings.isEmpty {
                // meanings が空のときだけ救済表示（念のため）
                if let first = examples.first {
                    exampleBlock(first, showDivider: false)
                } else {
                    // 生徒に見せたくないなら、ここは “何も出さない” でOK
                    EmptyView()
                }

            } else {
                // meanings があるとき：meaningごとに「例文があるものだけ」表示
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(meanings.enumerated()), id: \.offset) { i, rawM in
                        let m = rawM.trimmingCharacters(in: .whitespacesAndNewlines)

                        // meaning指定で引く（なければ表示しない）
                        // 旧データ救済：先頭meaningだけ meaning未指定の例文も拾う
                        let ex = ExampleStore.shared.firstExample(pos: pos, word: word, meaning: m)
                            ?? (i == 0 ? ExampleStore.shared.firstExample(pos: pos, word: word) : nil)

                        if let ex {
                            exampleBlock(ex, showDivider: i != meanings.count - 1)
                        }
                    }
                }
            }

            Spacer(minLength: 8)

            // 下のトグル（ゆっくり／英＋日）
            HStack(spacing: 32) {
                Toggle(isOn: $speechSlow) { Text("ゆっくり") }
                    .toggleStyle(.switch)

                Toggle(isOn: $speakBoth) { Text("英＋日") }
                    .toggleStyle(.switch)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)

        // 例文編集シート（先生のみボタン表示だが、sheet自体は置いてOK）
        .sheet(isPresented: $showingEditor) {
            ExampleEditorView(pos: pos, word: word)
        }
    }

    // MARK: - 例文表示ブロック（共通）
    @ViewBuilder
    private func exampleBlock(_ ex: ExampleEntry, showDivider: Bool) -> some View {
        let ja = (ex.ja ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let n  = (ex.note ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let hasAny = !ex.en.isEmpty || !ja.isEmpty || !n.isEmpty

        if hasAny {
            VStack(alignment: .leading, spacing: 6) {

                // 例文読み上げ（英→必要なら日）
                Button { speakExample(for: ex) } label: {
                    Label("例文", systemImage: "text.bubble.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .font(.subheadline)

                if !ex.en.isEmpty { Text(ex.en).font(.body) }
                if !ja.isEmpty { Text(ja).font(.body) }

                if !n.isEmpty {
                    Text(n)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if showDivider {
                    Divider()
                        .padding(.top, 10)     // 「私は毎日走ります」↔ 次の意味ブロックを離す主役
                        .padding(.bottom, 4)
                }
            }
            .padding(.bottom, showDivider ? 8 : 0)
        }
    }

    // MARK: - 表示用タイトル（不規則動詞なら 3 形を並べる）
    private var displayTitle: String {
        irregularForms.isEmpty ? word : irregularForms.joined(separator: " · ")
    }

    // MARK: - 読み上げ
    private func speakWord() {
        let forms = irregularForms.isEmpty ? [word] : irregularForms
        let text  = forms.joined(separator: ", ")
        speak(text, lang: "en-US")
    }

    private func speakExample(for ex: ExampleEntry) {
        guard !ex.en.isEmpty else { return }
        speak(ex.en, lang: "en-US")

        if speakBoth, let ja = ex.ja, !ja.isEmpty {
            speak(ja, lang: "ja-JP")
        }
    }

    private func speak(_ text: String, lang: String) {
        guard !text.isEmpty else { return }

        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: lang)

        let native = AVSpeechUtteranceDefaultSpeechRate
        let slow   = max(0.35, native * 0.80)
        u.rate = speechSlow ? slow : native

        synthesizer.speak(u)
    }
}

// （この extension は “ファイル最下部・struct の外” に置くこと）
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
