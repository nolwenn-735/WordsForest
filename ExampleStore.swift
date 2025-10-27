//
//  File.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/24.
//
import Foundation

struct ExamplePair: Codable, Hashable {
    var en: String
    var ja: String
    var note: String?
}

final class ExampleStore {
    static let shared = ExampleStore()
    private init() { load() }

    // いま使う保存キー
    private let key = "examples_v1"

    // 単語→例文
    private var map: [String: ExamplePair] = [:]

    // すべて同じ規則でキー化（前後空白カット＋小文字）
    private func norm(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // 読み出し
    func example(for word: String) -> ExamplePair? { map[norm(word)] }

    // 保存/更新（← save() が超重要）
    func setExample(for word: String, en: String, ja: String, note: String?) {
        map[norm(word)] = ExamplePair(en: en, ja: ja, note: note)
        save()
    }

    // 削除（← save() が超重要）
    func removeExample(for word: String) {
        map.removeValue(forKey: norm(word))
        save()
    }

    // MARK: - Persistence

    /// 現在のキーにデータが無い場合、UserDefaults 全体を走査して
    /// 旧キーに残っている [String: ExamplePair] を見つけて取り込む
    private func recoverIfNeededFromAnyKey() {
        guard map.isEmpty else { return } // もう読めていれば何もしない

        let ud = UserDefaults.standard
        let all = ud.dictionaryRepresentation()

        for (k, v) in all where k != key {
            guard let data = v as? Data else { continue }
            if let decoded = try? JSONDecoder().decode([String: ExamplePair].self, from: data),
               !decoded.isEmpty {

                // 読み込めた → キーを正規化して取り込み
                var normalized: [String: ExamplePair] = [:]
                for (raw, pair) in decoded {
                    normalized[norm(raw)] = pair
                }
                map = normalized
                print("[EX] Recovered examples from key: \(k) (\(decoded.count) items)")

                // 現在のキーに保存し直し＆通知
                save()
                break
            }
        }
    }

    /// メモリ上の辞書のキーを正規化（古い形式を矯正）
    private func normalizeKeysInMemory() {
        var changed = false
        var normalized: [String: ExamplePair] = [:]
        for (raw, pair) in map {
            let n = norm(raw)
            if n != raw { changed = true }
            normalized[n] = pair
        }
        if changed {
            map = normalized
            save() // 正しいキーで保存し直す（通知も飛ぶ）
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                map = try JSONDecoder().decode([String: ExamplePair].self, from: data)
            } catch {
                print("ExampleStore load error:", error)
                map = [:]
            }
        } else {
            map = [:]
        }

        // まずキー正規化（古いデータを矯正）
        normalizeKeysInMemory()

        // それでも空なら、他キーからの復旧を試みる
        recoverIfNeededFromAnyKey()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(map)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("ExampleStore save error:", error)
        }
        // 必ず通知を飛ばす（裏面や一覧を即更新させる）
        NotificationCenter.default.post(name: .examplesDidChange, object: nil)
        print("[EX] posted .examplesDidChange  (count=\(map.count))")
    }
}

extension Notification.Name {
    static let examplesDidChange = Notification.Name("examplesDidChange")
}
