//
//  SpellingModels.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/31.
//
// SpellingModels.swift
// WordsForest
import Foundation

enum SpellingDifficulty: String, Identifiable {
    case easy
    case hard

    var id: String { rawValue }
}

// MARK: - シャッフルしても「元の並び」と同じにはしないヘルパー

extension Array where Element: Equatable {
    /// 配列をシャッフルするが、可能な限り「元の並び」とは異なる順番を返す。
    /// （すべて同じ要素 [a, a, a] などの場合は変えようがないのでそのまま）
    func shuffledAvoidingOriginal(maxAttempts: Int = 10) -> [Element] {
        // 1文字しかないならどうしようもない
        guard count > 1 else { return self }

        var attempt = 0
        var candidate = self.shuffled()

        // 最大 maxAttempts 回まで「元と同じ並び」をやり直す
        while candidate == self && attempt < maxAttempts {
            candidate = self.shuffled()
            attempt += 1
        }

        return candidate
    }
}
