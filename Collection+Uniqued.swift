//
//  Collection+Uniqued.swift
//  WordsForest
//
//  Created by Nami .T on 2025/10/22.
//

import Foundation

// 配列の重複をキーで排除するヘルパー
extension Array {
    func uniqued<Key: Hashable>(by key: (Element) -> Key) -> [Element] {
        var seen = Set<Key>()
        var result: [Element] = []
        result.reserveCapacity(count)
        for e in self {
            let k = key(e)
            if seen.insert(k).inserted {
                result.append(e)
            }
        }
        return result
    }
}
