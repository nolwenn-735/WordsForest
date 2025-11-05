//
//  WordCard.swift
//  WordsForest
//
//  Created by Nami .T on 2025/09/30.
//

// WordCard.swift
import Foundation

struct WordCard: Identifiable, Codable, Hashable {
    let id: UUID
    var word: String
    var meaning: String
    var pos: PartOfSpeech
    // ← ここが保存用の正規フラグ
    var isFavorite: Bool = false

    // --- 互換ブリッジ（読み書きが isFavorite に流れる） ---
    var inCollection: Bool {
        get { isFavorite }
        set { isFavorite = newValue }
    }
}

extension WordCard {
    private enum CodingKeys: String, CodingKey {
        case id, word, meaning, pos
        case isFavorite          // 新キー
        case inCollection        // 旧キー（互換）
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        word = try c.decode(String.self, forKey: .word)
        meaning = try c.decode(String.self, forKey: .meaning)
        pos = try c.decode(PartOfSpeech.self, forKey: .pos)
        // 新キーがあればそれを、なければ旧キー、どちらも無ければ false
        isFavorite = (try? c.decode(Bool.self, forKey: .isFavorite))
        ?? (try? c.decode(Bool.self, forKey: .inCollection))
        ?? false
    }
    // encode は新キーだけでOK（旧キーは書き出さない）
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(word, forKey: .word)
        try c.encode(meaning, forKey: .meaning)
        try c.encode(pos, forKey: .pos)
        try c.encode(isFavorite, forKey: .isFavorite)
    }
        /// id と isFavorite を省略できる便利 init
    init(word: String, meaning: String, pos: PartOfSpeech,id: UUID = UUID(), isFavorite: Bool = false) {
            self.id = UUID()                  // 新規生成（安定IDにしたければ後述）
            self.word = word
            self.meaning = meaning
            self.pos = pos
            self.isFavorite = isFavorite
        }    
}
