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
    
    
    // 表示データ（表側から受け取るデフォルト）
    let word: String
    let posLabel: String?
    let meaning: String
    let exampleEn: String
    let exampleJa: String
    let hasDolphin: Bool
    let hasGold: Bool

    // 表側の状態
    @Binding var inCollection: Bool
    @Binding var learned: Bool

    // 先生用オプション
    let canEditExamples: Bool
    let onEditExample: (() -> Void)?

    // ローカル状態
    @State private var slow = false
    @State private var jpAlso = true
    // CardBackView 内の先頭付近に（定数）
    private let backMinHeight: CGFloat = 280   // ← 210〜260 くらいで微調整// 表示サイズ（好みで調整OK）
    private let enFontSize: CGFloat = 24
    private let jaFontSize: CGFloat = 16

    // ★ 保存済み例文（通知で更新）
    @State private var savedExample: ExamplePair? = nil
    // 保存済み例文を取り直して State を更新
    private func refreshExample() {
        // 例文があれば反映、無ければ nil
        savedExample = ExampleStore.shared.example(for: word)
    }
    private var enToShow: String  { savedExample?.en   ?? exampleEn }
    private var jaToShow: String  { savedExample?.ja   ?? exampleJa }
    private var noteToShow: String? { savedExample?.note }
    // ★ 追加：表示用にトリムした値
    private var enDisplay:  String  { enToShow.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var jaDisplay:  String  { jaToShow.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var noteDisplay: String? { noteToShow?.trimmingCharacters(in: .whitespacesAndNewlines) }
    
    // 指定イニシャライザ
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

            // ① 見出し
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(meaning).font(.title2).fontWeight(.semibold)
                if let posLabel, !posLabel.isEmpty {
                    Text(posLabel).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if hasGold { Text("✨🐬") }
                else if hasDolphin { Text("🐬") }
            }

            // ② 操作列
            HStack(spacing: 16) {
                Button {
                    playWord(word, speed: slow ? .slow : .normal)
                } label: {
                    Label("単語", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.borderless)
                .tint(.blue)   // ← 青

                Button {
                    let en = enDisplay.isEmpty ? word : enDisplay
                    let jp = jpAlso ? (jaDisplay.isEmpty ? nil : jaDisplay) : nil
                    playExample(english: en, japanese: jp, speed: slow ? .slow : .normal)
                } label: {
                    Label("例文", systemImage: "text.bubble.fill")
                }
                .buttonStyle(.borderless)
                .tint(.blue)   // ← 青

                Spacer(minLength: 0)

                if canEditExamples, let onEditExample {
                    Button(action: onEditExample) {
                        Image(systemName: "square.and.pencil")
                            .imageScale(.medium)
                    }
                    .buttonStyle(.borderless)
                    .tint(.secondary)   // ← 先生だけ・薄い色
                    .accessibilityLabel("例文を編集")
                }
            }

            // ③ 例文表示
            // ③ 例文表示（表示は常に 英＋日。トグルはTTSのみに効く）
            VStack(alignment: .leading, spacing: 6) {
                // 英文（空ならプレースホルダ）
                Text(enDisplay.isEmpty ? "（例文が未設定）" : enDisplay)
                    .font(.system(size: enFontSize, weight: .regular))  // 英文は大きめ
                    .foregroundStyle(enDisplay.isEmpty ? .secondary : .primary)

                // 日本語訳は常に表示（空なら出さない）— トグルには連動させない
                if !jaDisplay.isEmpty {
                    Text(jaDisplay)
                        .font(.system(size: jaFontSize))                // 和文は小さめ
                        .foregroundStyle(.primary)
                }

                if let note = noteDisplay, !note.isEmpty {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
    
            .padding(.top, 2)

            // ④ トグル
            Spacer(minLength: 6)
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Text("ゆっくり").font(.footnote)
                    Toggle("", isOn: $slow).labelsHidden().toggleStyle(.switch).controlSize(.mini)
                }
                HStack(spacing: 6) {
                    Text("英+日").font(.footnote)
                    Toggle("", isOn: $jpAlso).labelsHidden().toggleStyle(.switch).controlSize(.mini)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .frame(minHeight: backMinHeight)   // ★ これを追加
        // ★ 初回表示＆保存/削除のたびに取り直して再描画
        .onAppear(perform: refreshExample)
        .onReceive(NotificationCenter.default.publisher(for: .examplesDidChange)) { _ in
            refreshExample()
        }
    }
 
}

// ===== 音声ヘルパ =====
fileprivate let synth = AVSpeechSynthesizer()
fileprivate func playWord(_ text: String, speed: SpeechSpeed) { let u = AVSpeechUtterance(string: text); u.voice = AVSpeechSynthesisVoice(language: "en-US"); u.rate = (speed == .slow) ? 0.35 : 0.5; synth.speak(u) }
fileprivate func playExample(english: String, japanese: String?, speed: SpeechSpeed) {
    var arr: [AVSpeechUtterance] = []
    let e = AVSpeechUtterance(string: english); e.voice = AVSpeechSynthesisVoice(language: "en-US"); e.rate = (speed == .slow) ? 0.35 : 0.5; arr.append(e)
    if let jp = japanese, !jp.isEmpty { let j = AVSpeechUtterance(string: jp); j.voice = AVSpeechSynthesisVoice(language: "ja-JP"); j.rate = (speed == .slow) ? 0.35 : 0.5; arr.append(j) }
    arr.forEach { synth.speak($0) }
}
