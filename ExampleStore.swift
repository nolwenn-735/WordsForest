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

    func example(for word: String) -> ExamplePair? {
        map[word]
    }
    func setExample(_ pair: ExamplePair, for word: String) {
        map[word] = pair
        save()
    }
    func removeExample(for word: String) {
        map.removeValue(forKey: word)
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        if let decoded = try? JSONDecoder().decode([String: ExamplePair].self, from: data) {
            map = decoded
        }
    }
    private func save() {
        if let data = try? JSONEncoder().encode(map) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
