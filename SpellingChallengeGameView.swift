//
//  SpellingChallengeGameView.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/31.
//

// SpellingChallengeGameView.swift
// WordsForest
import SwiftUI
import UniformTypeIdentifiers

// ===== DnD 用の独自UTType =====
extension UTType {
    static let wfTile = UTType(exportedAs: "app.wordsforest.tile")
}

// ===== タイル型（Transferable + Codable 明示実装）=====
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

    // 等価判定 & ハッシュを id のみで
    static func == (lhs: GameTile, rhs: GameTile) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    enum CodingKeys: String, CodingKey { case id, char, isExtra }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id      = try c.decode(UUID.self,    forKey: .id)
        let s   = try c.decode(String.self,  forKey: .char)
        char    = s.first ?? "?"
        isExtra = try c.decode(Bool.self,    forKey: .isExtra)
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,                forKey: .id)
        try c.encode(String(char),      forKey: .char)
        try c.encode(isExtra,           forKey: .isExtra)
    }
}

// DnD用（idを含むCodableで転送）
extension GameTile: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .wfTile)
    }
}
typealias Tile = GameTile

// ===== メインView =====
struct SpellingChallengeGameView: View {
    let words: [SpellingWord]
    let difficulty: SpellingDifficulty

    @Environment(\.dismiss) private var dismiss

    // 進行・演出
    @State private var currentIndex = 0
    @State private var showHeart = false
    @State private var showWrongMark = false      // ❌

    // タイル状態
    @State private var tiles: [Tile] = []         // 表示中（必要＋余分）
    @State private var trashed = Set<Tile>()      // 捨てた集合（透明＆無効化）
    @State private var neededDiscarded = false    // 必要文字も捨てたフラグ

    var body: some View {
        if words.isEmpty {
            VStack(spacing: 16) {
                Text("出題できる単語がありません")
                Button("閉じる") { dismiss() }
            }
            .padding()
        } else {
            GeometryReader { geo in
                let h = geo.size.height
                let w = geo.size.width
                let current = words[currentIndex]

                ZStack {
                    // ===== ① タイトル／日本語意味 =====
                    VStack(spacing: 4) {
                        Text("問題 \(currentIndex + 1) / \(words.count)")
                            .font(.system(size: 30, weight: .semibold))
                        Text("\(current.pos.jaTitle)　\(current.meaningJa)")
                            .font(.title3)
                            .foregroundStyle(.primary)
                            .padding(.top, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .position(x: w / 2, y: h * 0.12)

                    // ===== ② タイル列＋判定ボタン =====
                    VStack(spacing: 16) {
                        let visible = tiles.filter { !trashed.contains($0) }
                        let tileWidth: CGFloat = min(60, 300 / CGFloat(max(visible.count, 1)))

                        HStack(spacing: 8) {
                            ForEach(visible) { t in
                                Text(String(t.char))
                                    .font(.title2)
                                    .frame(width: tileWidth, height: tileWidth)
                                    .background(current.pos.tileColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .opacity(trashed.contains(t) ? 0.25 : 1.0)
                                    .contentShape(RoundedRectangle(cornerRadius: 12))   // ← ヒット領域を見た目どおりに拡張
                                    .onTapGesture { attemptTrash(t) }     // DnDなし環境でも試せる
                                    .modifier(DraggableIfAvailable(tile: t))
                            }
                        }
                        .padding(.horizontal, 16)

                        Button("正解したことにする（仮）") {
                            finishAttempt()
                        }
                        .padding(.top, 4)
                        .tint(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .position(x: w / 2, y: h * 0.40)

                    // ===== ③ ハスキーと❤️/❌ =====
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
                .onAppear { setupTiles() }
                .onChange(of: currentIndex) { _ in setupTiles() }
                .animation(.easeInOut, value: showHeart)
                .animation(.easeInOut, value: showWrongMark)

                // ===== 右下の小さめゴミ箱（黒丸近辺） =====
                .overlay(alignment: .bottomTrailing) {
                    TrashButton()
                        .modifier(DropDestinationIfAvailable { items in
                            items.forEach { attemptTrash($0) }
                            return true
                        })
                        .scaleEffect(0.92)
                        .padding(.trailing, 20)
                        .padding(.bottom, h * 0.42) // 0.15〜0.22で微調整OK
                }
            }
        }
    }

    // MARK: - セットアップ

    private func setupTiles() {
        let word = baseWord(words[currentIndex].text)
        tiles = buildTiles(for: word)
        trashed.removeAll()
        neededDiscarded = false
        showWrongMark = false
    }

    // 不規則動詞のベース（記号・前後空白も正規化）
    private func baseWord(_ raw: String) -> String {
        // 小文字 & 前後空白
        var s = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // 不規則動詞の代表形へ寄せる（必要に応じて増やせる）
        switch s {
        case "run", "ran": s = "run"
        case "go", "went", "gone": s = "go"
        case "keep", "kept": s = "keep"
        default: break
        }

        // 区切り対策（"to keep / kept …" などの先頭トークンだけ採用）
        var seps = CharacterSet(charactersIn: "/,・•;()")
        seps.insert(charactersIn: " \t")
        if let r = s.rangeOfCharacter(from: seps) {
            s = String(s[..<r.lowerBound])
        }

        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    // タイル生成（必要文字＋余分1枚）
    private func buildTiles(for word: String) -> [Tile] {
        var arr: [Tile] = Array(word.uppercased()).map { Tile(char: $0, isExtra: false) }
        if difficulty == .hard, let extra = word.misleadingLetter() {
            arr.append(Tile(char: Character(String(extra).uppercased()), isExtra: true))
        }
        return arr.shuffled()
    }

    // MARK: - ふるまい

    // 捨てる試行：必要文字でもブロックせずに「捨てた扱い」にし、後で❌を出す
    private func attemptTrash(_ t: Tile) {
        trashed.insert(t)
        // 余分フラグに依存せず、「残りで答えが作れるか」で判断
        neededDiscarded = !canStillMakeAnswer()

        #if DEBUG
        print("TRASH:", String(t.char),
              "| canStillMakeAnswer =", canStillMakeAnswer(),
              "| neededDiscarded =", neededDiscarded)
        #endif
    }

    // 「完成」判定（いまは仮ボタンで呼ぶ）
    private func finishAttempt() {
        if neededDiscarded {
            // 3秒後に❌→少し見せてリセット（同一問題を再挑戦）
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation { showWrongMark = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation { showWrongMark = false }
                    trashed.removeAll()  // 必要文字を復元（余分文字はそのままでもOK）
                }
            }
        } else {
            handleCorrect() // ❤️→次へ
        }
    }

    private func handleCorrect() {
        withAnimation(.spring) { showHeart = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation { showHeart = false }
            goNext()
        }
    }

    private func goNext() {
        if currentIndex + 1 < words.count {
            currentIndex += 1
        } else {
            dismiss()
        }
    }
    // 残っているタイル文字列を取得（大文字で統一）
    private func visibleString() -> String {
        tiles.filter { !trashed.contains($0) }
             .map { String($0.char) }
             .joined()
    }

    // 文字出現回数のマップ
    private func freqMap(_ s: String) -> [Character: Int] {
        var d: [Character: Int] = [:]
        for c in s.uppercased() { d[c, default: 0] += 1 }
        return d
    }

    // 「残りタイル」で正解がまだ作れるか（マルチセット包含判定）
    private func canStillMakeAnswer() -> Bool {
        let need = freqMap(baseWord(words[currentIndex].text))
        let have = freqMap(visibleString())
        for (ch, cnt) in need {
            if (have[ch] ?? 0) < cnt { return false }
        }
        return true
    }
}


// ===== 見た目だけのゴミ箱ボタン（小さめ・青カプセル）=====
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

// ===== iOSバージョン差吸収：.draggable / .dropDestination を安全ラップ =====
private struct DraggableIfAvailable: ViewModifier {
    let tile: Tile
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.draggable(tile)
        } else {
            content // 古い環境はタップのみで捨てテスト
        }
    }
}
private struct DropDestinationIfAvailable: ViewModifier {
    let onDrop: ([Tile]) -> Bool
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.dropDestination(for: Tile.self) { items, _ in
                onDrop(items)
            }
        } else {
            content // 古い環境は視覚のみ
        }
    }
}
