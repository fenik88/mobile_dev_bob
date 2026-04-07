

import Foundation
import Combine

@MainActor
final class AddCardViewModel: ObservableObject {
    @Published var word: String = ""
    @Published var translation: String = ""
    @Published var example: String = ""
    @Published var isLookingUp: Bool = false
    @Published var lookupError: String? = nil
    @Published var phonetic: String = ""

    private var lookupTask: Task<Void, Never>?

    var isValid: Bool {
        !word.trimmingCharacters(in: .whitespaces).isEmpty &&
        !translation.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // Автоматический поиск при изменении слова
    func onWordChanged(isConnected: Bool) {
        lookupTask?.cancel()
        phonetic = ""
        lookupError = nil

        let trimmed = word.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else { return }

        lookupTask = Task {
            try? await Task.sleep(nanoseconds: 700_000_000) // debounce 0.7s
            guard !Task.isCancelled else { return }

            if !isConnected {
                // Пробуем из кэша даже без интернета
                if let result = await DictionaryService.shared.lookup(word: trimmed) {
                    applyResult(result)
                } else {
                    lookupError = NSLocalizedString("offline_no_cache", comment: "")
                }
                return
            }

            isLookingUp = true
            if let result = await DictionaryService.shared.lookup(word: trimmed) {
                applyResult(result)
            }
            isLookingUp = false
        }
    }

    private func applyResult(_ result: DictionaryResult) {
        phonetic = result.phonetic
        // Подставляем определение только если перевод ещё пустой
        if translation.trimmingCharacters(in: .whitespaces).isEmpty {
            translation = result.definition
        }
    }

    func save(to store: CardStore) {
        store.add(
            word: word.trimmingCharacters(in: .whitespaces),
            translation: translation.trimmingCharacters(in: .whitespaces),
            example: example.trimmingCharacters(in: .whitespaces)
        )
    }
}
