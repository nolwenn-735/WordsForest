//
//  HomeworkDebug.swift
//  WordsForest
//
//  Created by Nami .T on 2026/01/19.
//

#if DEBUG
import Foundation

extension HomeworkState {

    /// ✅ 安全：履歴の重複を間引いて、日付順に整列（パック照合はしない）
    func debugPruneHistory() {
        var list = history   // 読むのはOK（private(set)なので）

        // 1) 日付が変なのを除去（ゆるめ）
        let now = Date()
        let tooFuture = now.addingTimeInterval(60 * 60 * 24) // +1日
        let tooPast = Date(timeIntervalSince1970: 946684800) // 2000-01-01
        list.removeAll { $0.date > tooFuture || $0.date < tooPast }

        // 2) 重複を間引く（同じ「日付(YYYY-MM-DD) + pair + wordsCount + status」は1つだけ残す）
        let cal = Calendar.current
        var seen = Set<String>()
        list = list.filter { e in
            let d = cal.dateComponents([.year, .month, .day], from: e.date)
            let dayKey = "\(d.year ?? 0)-\(d.month ?? 0)-\(d.day ?? 0)"
            let key = "\(dayKey)|\(e.pair.rawValue)|\(e.wordsCount)|\(e.status.rawValue)"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }

        // 3) 降順ソート（新しいのが上）
        list.sort {
            if $0.date != $1.date { return $0.date > $1.date }
            if $0.pair.rawValue != $1.pair.rawValue { return $0.pair.rawValue > $1.pair.rawValue }
            return $0.status.rawValue > $1.status.rawValue
        }

        // 4) 反映（代入じゃなく入口経由）
        debugReplaceHistory(list)
    }
}
#endif
