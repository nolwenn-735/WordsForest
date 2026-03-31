//
//  SpellingChallengeGameView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/31.
//

//SpellingChallengeGameView.swift

import SwiftUI
import UniformTypeIdentifiers

// ===== DnD 用の独自UTType =====
extension UTType {
    // アプリ内専用のタグ。外部公開はしないので Info.plist 登録も不要。
    static let wfTile: UTType = {
        UTType(
            tag: "wf-tile",
            tagClass: .filenameExtension,
            conformingTo: .data
        ) ?? .data   // ← 万一 nil でも .data を返す
    }()
}

// ===== タイル型 =====
struct GameTile: Identifiable, Hashable, Codable {
    let id: UUID
    let char: Character
    let isExtra: Bool

    init(id: UUID = UUID(), char: Character, isExtra: Bool) {
        self.id = id
        self.char = char
        self.isExtra = isExtra
    }

    enum CodingKeys: String, CodingKey { case id, char, isExtra }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        let s = try c.decode(String.self, forKey: .char)
        char = s.first ?? "?"
        isExtra = try c.decode(Bool.self, forKey: .isExtra)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(String(char), forKey: .char)
        try c.encode(isExtra, forKey: .isExtra)
    }
}

// DnD 対応
extension GameTile: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .wfTile)
    }
}

// 既存互換
typealias Tile = GameTile

// ===== メイン View =====
struct SpellingChallengeGameView: View {
    let words: [SpellingWord]
    let difficulty: SpellingDifficulty
    
    @Environment(\.dismiss) private var dismiss
    
    // 進行・演出
    @State private var currentIndex = 0
    @State private var showHeart = false
    @State private var showWrongMark = false
    
    // タイル状態
    @State private var tiles: [Tile] = []
    @State private var trashed = Set<Tile>()
    @State private var answerCheckToken = 0
    @State private var tileWidth: CGFloat = 40
    
    // currentIndex が変でも必ず配列内に収める安全インデックス
    private var safeIndex: Int {
        guard !words.isEmpty else { return 0 }
        return min(max(currentIndex, 0), words.count - 1)
    }
    
    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width
            
            // ★ 万一単語がない異常時だけ表示（通常ルートでは来ない想定）
            if words.isEmpty {
                Text("※ 単語が渡されていません（My Collection から選んでね）")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let index = safeIndex
                let current = words[index]
                
                ZStack {
                    // ===== タイトル／日本語意味 =====
                    VStack(spacing: 4) {
                        Text("問題 \(index + 1) / \(words.count)")
                            .font(.system(size: 30, weight: .semibold))
                        Text("\(current.pos.jaTitle)　\(current.meaningJa)")
                            .font(.title3)
                            .foregroundStyle(.primary)
                            .padding(.top, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .position(x: w / 2, y: h * 0.12)
                    
                    // ===== タイル列＋スキップボタン =====
                    VStack(spacing: 16) {
                        let visible = tiles.filter { !trashed.contains($0) }
                        let tileW = tileWidth
                        
                        HStack(spacing: 8) {
                            ForEach(tiles) { t in
                                let isHidden = trashed.contains(t)
                                
                                Text(String(t.char))
                                    .font(.title2)
                                    .frame(width: tileWidth, height: tileWidth)
                                    .background(current.pos.tileColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .opacity(isHidden ? 0.18 : 1.0)
                                // 並べ替え用 DnD
                                    .modifier(DraggableIfAvailable(tile: t))
                                    .modifier(DropReorderIfAvailable(tile: t) { from, to in
                                        moveTile(from: from, to: to)
                                    })
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // ★ 分からないとき用スキップボタン
                        Button("スキップ") {
                            skipQuestion()
                        }
                        .padding(.top, 4)
                        .tint(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .position(x: w / 2, y: h * 0.40)
                    
                    // ===== ハスキー＋❤️／❌ =====
                    VStack {
                        Spacer()
                        ZStack {
                            Image("tutor_husky_cock")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 180)
                            
                            if showHeart {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 42))
                                    .foregroundStyle(.pink)
                                    .offset(x: 60, y: -70)
                                    .transition(.scale.combined(with: .opacity))
                            }
                            if showWrongMark {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.indigo)
                                    .offset(x: 60, y: -78)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 12)
                    }
                }
                // ===== ライフサイクル =====
                .onAppear(perform: setupTiles)
                .onChange(of: currentIndex) {
                    setupTiles()
                }
                .animation(.easeInOut, value: showHeart)
                .animation(.easeInOut, value: showWrongMark)
                // ===== 右下ゴミ箱 =====
                .overlay(alignment: .bottomTrailing) {
                    TrashButton()
                        .modifier(DropDestinationIfAvailable { items in
                            items.forEach { attemptTrash($0) }
                            return true
                        })
                        .scaleEffect(0.98)
                        .padding(.trailing, 32)
                        .padding(.bottom, h * 0.42)
                }
            }
        }
    }
    
    // MARK: - セットアップ
    
    private func setupTiles() {
        guard !words.isEmpty else { return }
        
        let word = words[safeIndex]

        // タイル生成（⭐️⭐️の余分タイル含む）
        tiles = buildTiles(for: word)
        trashed.removeAll()
        showHeart = false
        showWrongMark = false
        answerCheckToken += 1

        // === タイル幅の決定（正解の文字数だけを見る） ===
        let answerLength = max(word.answer.count, 1)
        let calculated = 300 / CGFloat(answerLength)

        // 40 を上限、24 を下限（短すぎ/長すぎを防ぐ）
        tileWidth = min(40, max(24, calculated))
    }
    
    // SpellingWord に合わせたタイル生成
    private func buildTiles(for word: SpellingWord) -> [Tile] {
        var tiles = word.letters.map { Tile(char: $0, isExtra: false) }
        
        // ⭐️⭐️: 紛らわしい1文字を追加
        if difficulty == .hard,
           let extraLower = word.answer.misleadingLetter() {
            let extra = Character(String(extraLower).uppercased())
            tiles.append(Tile(char: extra, isExtra: true))
        }
        
        // ランダムシャッフル（元の並びそのままは避ける）
        let shuffled = tiles.shuffledAvoidingOriginal()
        return shuffled
    }
    
    // MARK: - ふるまい
    
    // ゴミ箱に入ったタイルだけ「捨てた」扱い
    private func attemptTrash(_ t: Tile) {
        trashed.insert(t)
        evaluateAnswerIfReady()
    }
    
    // タイルの並べ替え（DnD）
    private func moveTile(from: Tile, to: Tile) {
        guard let fromIndex = tiles.firstIndex(of: from),
              let toIndex = tiles.firstIndex(of: to),
              fromIndex != toIndex else { return }
        
        let item = tiles.remove(at: fromIndex)
        tiles.insert(item, at: toIndex)
        
        evaluateAnswerIfReady()
    }
    
    // 自動判定：答えの長さに揃ったら「正解のときだけ」♥️
    private func evaluateAnswerIfReady() {
        guard !words.isEmpty else { return }

        let targetIndex = safeIndex
        let word = words[targetIndex]

        // 現在の並びから回答文字列を作成
        let usedTiles = tiles.filter { !trashed.contains($0) }
        let answer = String(usedTiles.map(\.char)).lowercased()

        // まだ文字数が揃っていない → 何もしない
        guard answer.count == word.answer.count else {
            // 途中で文字数が変わったら、予約中の誤答判定を無効化
            answerCheckToken += 1
            return
        }

        // ✅ 正解は即時
        if answer == word.answer {
            // 予約中の誤答判定があれば無効化
            answerCheckToken += 1
            showCorrectAndNext()
            return
        }

        // ❌ 不正解は少し待つ
        // まだ並べ替え途中の可能性があるので、短い猶予を置く
        let token = answerCheckToken + 1
        answerCheckToken = token

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // その間に別の操作があったらキャンセル
            guard token == answerCheckToken else { return }

            // 問題が切り替わっていたらキャンセル
            guard targetIndex == safeIndex,
                  targetIndex < words.count else { return }

            let latestWord = words[targetIndex]
            let latestUsed = tiles.filter { !trashed.contains($0) }
            let latestAnswer = String(latestUsed.map(\.char)).lowercased()

            // 文字数が崩れていたらまだ途中なので何もしない
            guard latestAnswer.count == latestWord.answer.count else { return }

            // この時点で正解になっていれば何もしない
            guard latestAnswer != latestWord.answer else { return }

            showWrongAndReset()
        }
    }
    
    // ❤️ 正解のとき → ハート表示して次の問題へ
    private func showCorrectAndNext() {
        showWrongMark = false
        withAnimation { showHeart = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            showHeart = false
            goNextQuestion()
        }
    }
    
    // ❌ 不正解のとき → バツを出して同じ問題をやり直し
    private func showWrongAndReset() {
        showHeart = false
        withAnimation { showWrongMark = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            showWrongMark = false
            setupTiles()
        }
    }
    // 次の問題へ（通常の正解 or スキップ後に使用）
    private func goNextQuestion() {
        trashed.removeAll()
        showHeart = false
        showWrongMark = false
        
        if currentIndex + 1 < words.count {
            currentIndex += 1
            setupTiles()
        } else {
            dismiss()
        }
    }
    
    // 分からないとき用スキップ
    private func skipQuestion() {
        // 進行中の判定を無効化
        answerCheckToken += 1
        showHeart = false
        showWrongMark = false
        goNextQuestion()
    }
    // ===== 見た目だけのゴミ箱ボタン =====
    private struct TrashButton: View {
        var body: some View {
            Label("ゴミ箱", systemImage: "trash")
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color(.systemGray6)))
                .overlay(Capsule().stroke(Color.blue.opacity(0.28), lineWidth: 2))
                .foregroundStyle(.blue)
                .contentShape(Capsule())
        }
    }
    
    // ===== .draggable / .dropDestination ラッパ =====
    private struct DraggableIfAvailable: ViewModifier {
        let tile: Tile
        func body(content: Content) -> some View {
            if #available(iOS 16.0, *) {
                content.draggable(tile)
            } else {
                content
            }
        }
    }
    
    // ゴミ箱用: Tile.self を受け取る
    private struct DropDestinationIfAvailable: ViewModifier {
        let onDrop: ([Tile]) -> Bool
        func body(content: Content) -> some View {
            if #available(iOS 16.0, *) {
                content.dropDestination(for: Tile.self) { items, _ in
                    onDrop(items)
                }
            } else {
                content
            }
        }
    }
    
    // 並べ替え用: タイル同士の上に落としたら moveTile 発火
    private struct DropReorderIfAvailable: ViewModifier {
        let tile: Tile
        let move: (Tile, Tile) -> Void
        
        func body(content: Content) -> some View {
            if #available(iOS 16.0, *) {
                content.dropDestination(for: Tile.self) { items, _ in
                    guard let from = items.first else { return false }
                    move(from, tile)
                    return true
                }
            } else {
                content
            }
        }
    }
}


