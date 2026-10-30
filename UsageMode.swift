//
//  UsageMode.swift
//  WordsForest
//
//  Created by Nami .T on 2026/10/30.
//
import Foundation

enum UsageMode: String, CaseIterable, Identifiable {
    case individual
    case classroom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .individual:
            return "個人"
        case .classroom:
            return "教室"
        }
    }
}


