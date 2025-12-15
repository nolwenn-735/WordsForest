//
//
//  CardBackView.swift — 新仕様対応 11/27デザイン版 (2025/12/07)
//

import SwiftUI
import AVFoundation

/// 単語カード裏面（品詞ページ／宿題／My Collection／覚えたBOX 共通）
struct CardBackView: View {

    // MARK: - 入力データ

    /// ✅ 追加：品詞
    let pos: PartOfSpeech
    
    /// 見出し語（動詞のときは基本形）
    let word: String

    /// 意味リスト（WordCard.meanings）
    let meanings: [String]

    /// 例文リスト（ExampleStore.shared.examples(for:) の結果）
    let examples: [ExampleEntry]

    /// 将来のために残しておく備考テキスト（今はほぼ examples.first?.note を使う）
    let note: String

    /// 不規則動詞の 3 形など（["go", "went", "gone"]）
    let irregularForms: [String]

    // MARK: - 状態（読み上げ & 編集）

    @State private var speechFast = false      // ゆっくり
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

            // 上のボタン列：単語／例文 読み上げ ＋ 編集ペン
            HStack(spacing: 16) {
                Button(action: speakWord) {
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2.fill")
                        Text("単語")
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.blue)

                Button(action: speakExample) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.bubble.fill")
                        Text("例文")
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.blue)
                
                Spacer()

                // 生徒には極力触らせたくないので、薄いグレーのペン
                Button(action: { showingEditor = true }) {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(.secondary)
                        .opacity(0.7)
                }
                .buttonStyle(.plain)
            }
            .font(.subheadline)

            // 例文（先頭だけ表示）
            Group {
                if let first = examples.first {
                    VStack(alignment: .leading, spacing: 4) {
                        if !first.en.isEmpty {
                            Text(first.en)
                                .font(.body)
                        }
                        if let ja = first.ja, !ja.isEmpty {
                            Text(ja)
                                .font(.body)
                        }
                        if let n = first.note, !n.isEmpty {
                            Text(n)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if !note.isEmpty {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("（例文が未登録です）")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            // 下のトグル（ゆっくり／英＋日）
            HStack(spacing: 32) {
                Toggle(isOn: $speechFast) {
                    Text("ゆっくり")
                }
                .toggleStyle(.switch)

                Toggle(isOn: $speakBoth) {
                    Text("英＋日")
                }
                .toggleStyle(.switch)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        // 例文編集シート
        .sheet(isPresented: $showingEditor) {
            ExampleEditorView(pos: pos, word: word)
        }
    }

    // MARK: - 表示用タイトル（不規則動詞なら 3 形を並べる）

    private var displayTitle: String {
        if irregularForms.isEmpty {
            return word
        } else {
            return irregularForms.joined(separator: " · ")
        }
    }

    // MARK: - 読み上げ

    private func speakWord() {
        let forms = irregularForms.isEmpty ? [word] : irregularForms
        let text  = forms.joined(separator: ", ")
        speak(text, lang: "en-US")
    }

    private func speakExample() {
        guard let first = examples.first else { return }
        speak(first.en, lang: "en-US")

        if speakBoth, let ja = first.ja, !ja.isEmpty {
            speak(ja, lang: "ja-JP")
        }
    }
    
    private func speak(_ text: String, lang: String) {
        guard !text.isEmpty else { return }
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: lang)
        u.rate  = speechFast ? 0.65 : 0.45
        synthesizer.speak(u)
    }
}
