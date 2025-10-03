//
//  Wordcardpage.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/28.
//

import SwiftUI
import AVFoundation   // ← ここに追加（importは必ずファイル先頭）

// スクロール量を拾うための PreferenceKey
private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - 一覧（品詞ごと → ここから遷移して 1 画面に入る）
struct POSFlashcardListView: View {
    let pos: PartOfSpeech
    let accent: Color
    let animalName: String

    @State private var showingAdd = false
    @Environment(\.dismiss) private var dismiss
    @State private var reversed = false
    @State private var speechFast = false
    private let tts = AVSpeechSynthesizer()
    
    var body: some View {
        
        // 上部：英⇄日トグル（右寄せ）
        HStack {
            Spacer()
            Button { reversed.toggle() } label: {
                Label(reversed ? "日⇒英" : "英⇒日",
                      systemImage: "arrow.left.arrow.right")
            }
            .labelStyle(.titleAndIcon)
        }
        .padding(.horizontal)
        .padding(.top, 4)
        // 宿題 or サンプルのカード配列を用意
        let hwList  = HomeworkStore.shared.list(for: pos)
        let cards: [WordCard] = hwList.isEmpty
            ? Array(SampleDeck.filtered(by: pos).prefix(4))
            : hwList

        ZStack {
            pos.backgroundColor.ignoresSafeArea()   // ← “固定パステル背景”

            // 単語カード 1 画面（見た目は元の CardRow 群）
            POSFlashcardView(
                title: "\(pos.rawValue) レッスン",
                cards: cards,
                accent: accent,
                background: pos.backgroundColor,     // ← 品詞の固定色
                animalName: animalName,
                reversed: reversed
            )
        }
        .navigationTitle("\(pos.rawValue) レッスン")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button { showingAdd = true } label: { Image(systemName: "plus")
                }
                .accessibilityLabel("単語を追加")
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { dismiss() } label: { Text("ホームへ🏠") }
                    .accessibilityLabel("ホームへ")
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddWordView(pos: pos)
        }
    }
}

// MARK: - 単語カード 1 画面（縦スクロール＋右下にマスコット固定）
struct POSFlashcardView: View {
    let title: String
    let cards: [WordCard]
    let accent: Color
    // 検索結果などで呼ぶときは背景不要にしたいのでデフォルト .clear
    let background: Color
    let animalName: String
    let reversed: Bool

    // レイアウト定数
    private let rowsPerScreen: CGFloat = 4        // ざっくり 4 枚見せ
    private let screensPerVariant: CGFloat = 3    // 「3スクリーン=1セット」
    private let actionBandTailRatio: CGFloat = 0.15   // 終端 15% で出す
    
    // 状態
    @State private var selected = Set<Int>()  // ✅
    @State private var favored  = Set<Int>()  // ♡
    @State private var expanded: Int? = nil   // 表⇄裏 展開インデックス
    @State private var scrollOffset: CGFloat = 0
    @State private var viewportH: CGFloat = 0
    private let tts = AVSpeechSynthesizer()
    @State private var speechFast = false

    var body: some View {
        ZStack {
            background.ignoresSafeArea()     // ← 品詞色 or .clear

            GeometryReader { outer in
                let rowH   = max(88, (outer.size.height - 140) / rowsPerScreen)
                let blockH = outer.size.height * screensPerVariant

                ScrollView {
                    // スクロール量を取得
                    GeometryReader { g in
                        Color.clear
                            .preference(key: ScrollOffsetKey.self,
                                        value: -g.frame(in: .named("scroll")).minY)
                    }
                    .frame(height: 0)

                    VStack(spacing: 16) {
                        // 必要ならタイトル（今は非表示のまま）
                        // Text(title)
                        //    .font(.system(size: 22, weight: .semibold))
                        //    .foregroundStyle(.primary)
                        //    .padding(.top, 6)

                        rows(rowH: rowH)

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 140) // 右下マスコット分の余白
                    .background(Color.clear)
                }
                .coordinateSpace(name: "scroll")
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 32)   // 好みで 24〜40
                }
                .onPreferenceChange(ScrollOffsetKey.self) { v in
                    scrollOffset = max(0, v)
                    viewportH = outer.size.height
                }

                // 右下の動物（固定／タップ不可）
                VStack { Spacer()
                    HStack { Spacer()
                        Image(animalName)
                            .resizable().scaledToFit()
                            .frame(width: 140, height: 140)
                            .allowsHitTesting(false)
                            .padding(.trailing, 12)
                            .padding(.bottom, 8)
                    }
                }

                // まとめ操作バー（末尾 15% で出現）
                if showActionBand(blockH: blockH) {
                    actionBand
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeOut(duration: 0.25),
                                   value: showActionBand(blockH: blockH))
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(accent)
        .toolbarBackground(accent, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    // MARK: 行の並び
    @ViewBuilder
    private func rows(rowH: CGFloat) -> some View {
        // 大きい式を分解して型推論を軽くする
        let enumerated = Array(cards.enumerated())
        ForEach(enumerated, id: \.offset) { pair in
            let i = pair.offset
            let c = pair.element
            row(for: c, index: i, rowH: rowH)
        }
    }

    // MARK: 1 行の CardRow（表／裏）
    @ViewBuilder
    private func row(for c: WordCard, index i: Int, rowH: CGFloat) -> some View {
        // 先にローカル変数へ落としておくとさらに楽になる
        let saved = ExampleStore.shared.example(for: c.word)
        let exEn: String = saved?.en ?? ""
        let exJa: String = saved?.ja ?? ""
        
        // デフォルトは非表示（検索結果では品詞タグを出さない）
        let posText: String? = nil
        let hasD: Bool = false
        let hasG: Bool = false
        
        CardRow(
                word: c.word,
                meaning: c.meaning,
                posText: posText,
                exampleEn: exEn,
                exampleJa: exJa,
                hasDolphin: hasD,
                hasGold: hasG,
                reversed: reversed,
                isChecked: selected.contains(i),
                isFav: favored.contains(i),
                expanded: expanded == i,
                rowHeight: rowH,
                checkTapped: { toggle(selected: i) },
                heartTapped: { toggle(favored: i) },
                centerTapped: {
                    withAnimation(.spring(response: 0.25)) {
                        expanded = (expanded == i ? nil : i)
                    }
                },
                speakWordTapped: { speakWord(c.word) },
                speakExampleTapped: { speakExample(en: exEn, ja: exJa) },
                addExampleTapped: { addExample(for: c) },
                toggleSpeechSpeed: { speechFast.toggle() },
                speechFast: speechFast
                )
    }
    // MARK: まとめ帯
    private var actionBand: some View {
        HStack(spacing: 10) {
            Button {
                selected.removeAll()
            } label: {
                bandButton("📦 覚えたBOX", filled: !selected.isEmpty)
            }

            Button {
                favored.removeAll()
            } label: {
                bandButton("♡ MYコレ", filled: !favored.isEmpty)
            }

            Spacer(minLength: 8)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.black.opacity(0.15), lineWidth: 1)
        )
    }

    private func bandButton(_ title: String, filled: Bool) -> some View {
        Text(title)
            .font(.headline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(filled ? AnyShapeStyle (Color.primary.opacity(0.08)): AnyShapeStyle(.thinMaterial))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func showActionBand(blockH: CGFloat) -> Bool {
        guard blockH > 0 else { return true }
        let r = (scrollOffset.truncatingRemainder(dividingBy: blockH)) / blockH
        return r >= (1.0 - actionBandTailRatio) // 終端 15% で表示
    }

    private func toggle(selected i: Int) {
        if selected.contains(i) { selected.remove(i) } else { selected.insert(i) }
    }
    private func toggle(favored i: Int) {
        if favored.contains(i)  { favored.remove(i) }  else { favored.insert(i) }
    }
        // ⬇︎ ここに“メソッド”を置く（struct の中・body の後・閉じカッコの前）
          private func speakWord(_ text: String) {
              speak(text, lang: "en-US")
          }

          private func speakExample(en: String, ja: String) {
              speak(en, lang: "en-US")
              if !ja.isEmpty { speak(ja, lang: "ja-JP") }
          }

          private func speak(_ text: String, lang: String) {
              guard !text.isEmpty else { return }
              let u = AVSpeechUtterance(string: text)
              u.voice = AVSpeechSynthesisVoice(language: lang)
              u.rate  = speechFast ? 0.55 : 0.45
              tts.speak(u)
          }

          private func addExample(for c: WordCard) {
              // 例文追加画面へ遷移したい場合はここで処理
          }// ⬆︎ ここまで（この下に struct の閉じカッコ `}` が来る）
}

// ===== 1行分のカード（表/裏） =====
import SwiftUI

struct CardRow: View {
    // 表示データ
    let word: String
    let meaning: String
    let posText: String?
    let exampleEn: String
    let exampleJa: String

    // タグ
    let hasDolphin: Bool
    let hasGold: Bool

    // 状態（親から渡す）
    let reversed: Bool        // 英⇄日の並び
    let isChecked: Bool       // ✅
    let isFav: Bool           // ♡
    let expanded: Bool        // 裏面を開く？

    // レイアウト
    let rowHeight: CGFloat

    // アクション
    let checkTapped: () -> Void
    let heartTapped: () -> Void
    let centerTapped: () -> Void
    let speakWordTapped: () -> Void
    let speakExampleTapped: () -> Void
    let addExampleTapped: () -> Void
    let toggleSpeechSpeed: () -> Void
    let speechFast: Bool      // いまのスピード表示用（🐢/🐇）

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // 1行目：✅ [タイトル2行] ♡（✅は左、♡は右）
            HStack(alignment: .firstTextBaseline) {
                Button(action: checkTapped) {
                    Image(systemName: isChecked ? "checkmark.circle.fill"
                                                : "checkmark.circle")
                }
                .accessibilityLabel("チェック")

                VStack(alignment: .leading, spacing: 4) {
                    if reversed {
                        Text(meaning).font(.headline)
                        Text(word).font(.subheadline)
                    } else {
                        Text(word).font(.headline)
                        Text(meaning).font(.subheadline)
                    }
                    if let posText, !posText.isEmpty {
                        Text(posText).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8)

                Button(action: heartTapped) {
                    Image(systemName: isFav ? "heart.fill" : "heart")
                }
                .accessibilityLabel("お気に入り")
            }

            // 裏面（expanded=true のときに表示）
            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    if !exampleEn.isEmpty { Text(exampleEn).font(.caption) }
                    if !exampleJa.isEmpty { Text(exampleJa).font(.caption2) }

                    HStack(spacing: 14) {
                        Button(action: speakWordTapped) {
                            Label("単語だけ", systemImage: "speaker.wave.2.fill")
                        }
                        Button(action: speakExampleTapped) {
                            Label("例文", systemImage: "text.bubble.fill")
                        }
                        Button(action: addExampleTapped) {
                            Label("例文追加", systemImage: "plus.bubble.fill")
                        }
                        Spacer()
                        Button(action: toggleSpeechSpeed) {
                            Image(systemName: speechFast ? "hare.fill" : "tortoise.fill")
                        }
                        .accessibilityLabel("読み上げ速度切替")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .frame(minHeight: rowHeight, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)                // 薄いカード面
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14).stroke(.black.opacity(0.10), lineWidth: 1)
        )
        .contentShape(Rectangle())                     // タップ範囲を広げる
        .onTapGesture(perform: centerTapped)           // 中央タップで表裏
        .animation(.spring(response: 0.25), value: expanded)
    }
}
