import Foundation

//одна карточка
class WordCard: Identifiable, ObservableObject, Codable { //свой id, изменяемый, для json
    var id: UUID
    //паблишд для автоперерисовки
    @Published var word: String
    @Published var translation: String
    @Published var definition: String  // английское определение из словаря
    @Published var example: String     // пример от пользователя
    @Published var createdAt: Date
    @Published var isLearned: Bool

    //вызываем конструктор лего наш
    init(word: String, translation: String, definition: String = "", example: String = "") {
        self.id = UUID()
        self.word = word
        self.translation = translation
        self.definition = definition
        self.example = example
        self.createdAt = Date()
        self.isLearned = false
    }

    // перечисление как будут называться поля в джсоне
    enum CodingKeys: String, CodingKey {
        case id, word, translation, definition, example, createdAt, isLearned
    }

    // читаем джсон
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self,   forKey: .id)
        word = try c.decode(String.self, forKey: .word)
        translation = try c.decode(String.self, forKey: .translation)
        // decodeIfPresent — старые карточки без поля definition не сломаются
        definition = (try? c.decodeIfPresent(String.self, forKey: .definition)) ?? ""
        example = try c.decode(String.self, forKey: .example)
        createdAt = try c.decode(Date.self,   forKey: .createdAt)
        isLearned = try c.decode(Bool.self,   forKey: .isLearned)
    }

    // пишем в джсон
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(word, forKey: .word)
        try c.encode(translation, forKey: .translation)
        try c.encode(definition, forKey: .definition)
        try c.encode(example, forKey: .example)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(isLearned, forKey: .isLearned)
    }
}
