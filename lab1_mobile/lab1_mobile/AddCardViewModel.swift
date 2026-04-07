
import Foundation
import Combine

@MainActor
final class AddCardViewModel: ObservableObject {
    @Published var word: String = ""
    @Published var translation: String = ""   // перевод на русский — заполняется из API
    @Published var definition: String = ""    // английское определение из API
    @Published var example: String = ""       // пример от пользователя (вводит сам)
    @Published var phonetic: String = ""      // транскрипция /kæt/
    @Published var isLookingUp: Bool = false
    @Published var lookupError: String? = nil

    // пользователь выбирает что хранить в третьем поле — definition из API или свой пример
    // true = показываем definition из API, false = пользователь пишет свой example
    @Published var useDefinition: Bool = true

    // флаг — пользователь вручную редактировал поле перевода
    // если true — не перезаписываем перевод из API автоматически
    var userEditedTranslation: Bool = false

    // задача поиска — храним чтобы отменять при новом вводе
    private var lookupTask: Task<Void, Never>?

    // валидация — слово и перевод обязательны
    var isValid: Bool {
        !word.trimmingCharacters(in: .whitespaces).isEmpty &&
        !translation.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // вызывается при каждом изменении поля "слово"
    func onWordChanged(isConnected: Bool) {
        // отменяем предыдущий поиск (дебаунс)
        lookupTask?.cancel()
        phonetic = ""
        definition = ""
        lookupError = nil

        // при смене слова сбрасываем флаг ручного редактирования —
        // раз слово новое, перевод тоже должен подтянуться из API заново
        userEditedTranslation = false
        translation = ""

        let trimmed = word.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else { return }

        lookupTask = Task {
            // debounce — ждём 0.7 сек тишины перед запросом
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }

            if !isConnected {
                // нет инета — пробуем из кэша
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

    // вызывается когда пользователь сам редактирует поле перевода
    // после этого API не будет перезаписывать то что он написал
    func onTranslationEditedByUser() {
        userEditedTranslation = true
    }

    // применяем результат из API
    private func applyResult(_ result: DictionaryResult) {
        phonetic = result.phonetic
        definition = result.definition

        // перевод обновляем только если пользователь не редактировал поле сам
        if !userEditedTranslation {
            translation = result.translation
        }
    }

    // сохраняем карточку в хранилище
    func save(to store: CardStore) {
        store.add(
            word:        word.trimmingCharacters(in: .whitespaces),
            translation: translation.trimmingCharacters(in: .whitespaces),
            definition:  definition.trimmingCharacters(in: .whitespaces),
            example:     example.trimmingCharacters(in: .whitespaces)
        )
    }
}
