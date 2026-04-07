
import Foundation
import Combine

class CardStore: ObservableObject {
    static let shared = CardStore()

    @Published var cards: [WordCard] = []

    private let saveKey = "flashwords_cards"

    init() {
        load()
    }
    func add(word: String, translation: String, example: String) {
        let card = WordCard(word: word, translation: translation, example: example)
        cards.insert(card, at: 0)
        save()
    }

    func update(_ card: WordCard, word: String, translation: String, example: String) {
        card.word = word
        card.translation = translation
        card.example = example
        objectWillChange.send()
        save()
    }

    func toggleLearned(_ card: WordCard) {
        card.isLearned.toggle()
        objectWillChange.send()
        save()
    }

    func delete(at offsets: IndexSet) {
        cards.remove(atOffsets: offsets)
        save()
    }

    func delete(card: WordCard) {
        cards.removeAll {$0.id == card.id}
        save()
    }

// сохраняю в json
    private func save() {
        if let data = try? JSONEncoder().encode(cards) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    //  загрузка из json формата
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let saved = try? JSONDecoder().decode([WordCard].self, from: data) else { return }
        cards = saved
    }
}
