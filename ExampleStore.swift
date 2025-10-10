//
//  File.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/24.
//
import Foundation
import Combine

struct ExamplePair: Codable, Equatable {
    var en: String
    var ja: String
    var note: String? = nil
}

final class ExampleStore: ObservableObject {
    static let shared = ExampleStore()

    @Published private(set) var map: [String: ExamplePair] = [:]

    private let key = "example_store_v1"
    private var cancellables = Set<AnyCancellable>()

    private init() {
        load()
        // 変更があれば自動保存
        $map
            .dropFirst()
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.save() }
            .store(in: &cancellables)
    }

    // 読み出し
    func example(for word: String) -> ExamplePair? { map[word] }

    // 保存/更新（※これを1つだけ残す）
    func setExample(for word: String, en: String, ja: String, note: String? = nil) {
        map[word] = ExamplePair(en: en, ja: ja, note: note)
    }

    // 削除
    func removeExample(for word: String) {
        map.removeValue(forKey: word)
    }

    // MARK: - Persistence
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        do {
            map = try JSONDecoder().decode([String: ExamplePair].self, from: data)
        } catch {
            print("ExampleStore load error:", error)
            map = [:]
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(map)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("ExampleStore save error:", error)
        }
    }
}
