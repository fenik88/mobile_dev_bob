import Foundation
//отрисую карточку
class WordCard: Identifiable, ObservableObject, Codable {
    var id: UUID
    @Published var word: String
    @Published var translation: String
    @Published var example: String
    @Published var createdAt: Date
    @Published var isLearned: Bool

    init(word: String, translation: String, example: String = "") {
        self.id = UUID()
        self.word = word
        self.translation = translation
        self.example = example
        self.createdAt = Date()
        self.isLearned = false
    }

    enum CodingKeys: String, CodingKey {
        case id, word, translation, example, createdAt, isLearned
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self,   forKey: .id)
        word        = try c.decode(String.self, forKey: .word)
        translation = try c.decode(String.self, forKey: .translation)
        example     = try c.decode(String.self, forKey: .example)
        createdAt   = try c.decode(Date.self,   forKey: .createdAt)
        isLearned   = try c.decode(Bool.self,   forKey: .isLearned)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,          forKey: .id)
        try c.encode(word,        forKey: .word)
        try c.encode(translation, forKey: .translation)
        try c.encode(example,     forKey: .example)
        try c.encode(createdAt,   forKey: .createdAt)
        try c.encode(isLearned,   forKey: .isLearned)
    }
}
