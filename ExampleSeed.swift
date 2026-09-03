//
//  ExampleSeed.swift
//  WordsForest
//
//  Created by Nami .T on 2026/09/03.
//

import Foundation

import Foundation

struct ExampleSeedItem: Codable {
    let pos: String
    let word: String
    let wordNote: String?
    let meanings: [ExampleSeedMeaning]
}

struct ExampleSeedMeaning: Codable {
    let meaning: String
    let en: String
    let ja: String?
}
