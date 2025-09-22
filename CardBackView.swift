//
//  CardBackView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/21.
//
import SwiftUI
import AVFoundation

enum SpeechSpeed { case normal, slow }

struct CardBackView: View {
    // 表示データ
    let word: String
    let posLabel: String?
    let meaning: String
    let exampleEn: String
    let exampleJa: String
    let hasDolphin: Bool
    let hasGold: Bool

    // 表側の状態を橋渡し
    @Binding var inCollection: Bool
    @Binding var learned: Bool

    // 先生用オプション（編集ボタンの出し分け＆タップ時のハンドラ）
    let canEditExamples: Bool
    let onEditExample: (() -> Void)?

    // ローカル状態
    @State private var slow = false
    @State private var jpAlso = false

    // 指定イニシャライザ（ラベル順＆デフォルト値はここ）
    init(
        word: String,
        posLabel: String?,
        meaning: String,
        exampleEn: String,
        exampleJa: String,
        hasDolphin: Bool,
        hasGold: Bool,
        inCollection: Binding<Bool>,
        learned: Binding<Bool>,
        canEditExamples: Bool = false,
        onEditExample: (() -> Void)? = nil
    ) {
        self.word = word
        self.posLabel = posLabel
        self.meaning = meaning
        self.exampleEn = exampleEn
        self.exampleJa = exampleJa
        self.hasDolphin = hasDolphin
        self.hasGold = hasGold
        self._inCollection = inCollection
        self._learned = learned
        self.canEditExamples = canEditExamples
        self.onEditExample = onEditExample
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // ① 意味（日本語）を上に大きく
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(meaning)
                    .font(.title2).fontWeight(.semibold)
                if let posLabel, !posLabel.isEmpty {
                    Text(posLabel).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if hasGold { Text("✨🐬") }
                else if hasDolphin { Text("🐬") }
            }

            // ② 音声ボタン列（🔈単語 / 🗣例文）＋（必要時のみ）鉛筆
            HStack(spacing: 16) {
                Button {
                    playWord(word, speed: slow ? .slow : .normal)
                } label: {
                    Label("単語", systemImage: "speaker.wave.2.fill")
                }

                Button {
                    // 英語が空なら単語で代用。JPはトグルに合わせる
                    let en = exampleEn.isEmpty ? word : exampleEn
                    let jp = jpAlso ? exampleJa : nil
                    playExample(english: en, japanese: jp, speed: slow ? .slow : .normal)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "text.bubble.fill")
                        Text("例文")
                    }
                    .foregroundStyle(.blue)
                }

                Spacer(minLength: 0)

                if canEditExamples, let onEditExample {
                    Button(action: onEditExample) {
                        Image(systemName: "square.and.pencil")
                            .imageScale(.medium)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("例文を編集")
                }
            }

            // ③ 例文表示（英→和）
            VStack(alignment: .leading, spacing: 6) {
                Text(exampleEn.isEmpty ? "（例文が未設定）" : exampleEn)
                    .font(.body)
                    .foregroundStyle(exampleEn.isEmpty ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)

                if jpAlso, !exampleJa.isEmpty {
                    Text(exampleJa)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 2)

            // ④ トグル列（下げて、文字とスイッチを近づける）
            Spacer(minLength: 6)

            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Text("ゆっくり").font(.footnote)
                    Toggle("", isOn: $slow)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                }
                HStack(spacing: 6) {
                    Text("英日").font(.footnote)
                    Toggle("", isOn: $jpAlso)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

// ===== 音声ヘルパ（ファイル内共通）=====
fileprivate let synth = AVSpeechSynthesizer()

fileprivate func playWord(_ text: String, speed: SpeechSpeed) {
    let u = AVSpeechUtterance(string: text)
    u.voice = AVSpeechSynthesisVoice(language: "en-US")
    u.rate  = (speed == .slow) ? 0.35 : 0.5
    synth.speak(u)
}

fileprivate func playExample(english: String, japanese: String?, speed: SpeechSpeed) {
    var arr: [AVSpeechUtterance] = []
    let e = AVSpeechUtterance(string: english)
    e.voice = AVSpeechSynthesisVoice(language: "en-US")
    e.rate  = (speed == .slow) ? 0.35 : 0.5
    arr.append(e)
    if let jp = japanese, !jp.isEmpty {
        let j = AVSpeechUtterance(string: jp)
        j.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        j.rate  = (speed == .slow) ? 0.35 : 0.5
        arr.append(j)
    }
    arr.forEach { synth.speak($0) }
}
