//
//  ColumnArticle.swift
//  WordsForest
//
//  Created by Nami .T on 2026/11/05.
//
//
//  ColumnArticle.swift
//  WordsForest
//

import Foundation

struct ColumnArticle: Identifiable, Hashable, Codable {
    var id: Int
    var title: String
    var body: String
    var tags: [String]
}


