//https://dictionaryapi.dev — транскрипция и definition
//https://translate.googleapis.com — перевод на русский через Google Translate (без ключа)

import Foundation

// из чего состоит результат поиска
struct DictionaryResult {
    let definition: String  // английское определение
    let phonetic: String    // транскрипция /kæt/
    let translation: String // перевод на русский
}

// синглтончик добавили
final class DictionaryService {
    static let shared = DictionaryService()
    private init() {}

    private let cacheKey = "dictionary_cache"

    // кэшик
    private func loadCache() -> [String: DictionaryResult] {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let raw = try? JSONDecoder().decode([String: CachedEntry].self, from: data) else {
            return [:]
        }
        return raw.mapValues {
            DictionaryResult(definition: $0.definition, phonetic: $0.phonetic, translation: $0.translation)
        }
    }

    // кэшик по факту словарь
    private func saveToCache(word: String, result: DictionaryResult) {
        var raw = (try? JSONDecoder().decode(
            [String: CachedEntry].self,
            from: UserDefaults.standard.data(forKey: cacheKey) ?? Data()
        )) ?? [:]
        raw[word.lowercased()] = CachedEntry(
            definition: result.definition,
            phonetic: result.phonetic,
            translation: result.translation
        )
        if let data = try? JSONEncoder().encode(raw) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    // поиск — два параллельных запроса: словарь + перевод
    // асинк чтобы не висла приложуха после запроса
    func lookup(word: String) async -> DictionaryResult? {
        let key = word.lowercased().trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return nil }

        // проверяем искали ли? если да то возвращаем из кэша без запросов
        let cache = loadCache()
        if let cached = cache[key] { return cached }

        // запускаем оба запроса одновременно через async let
        async let dictResult = fetchDictionary(word: key)
        async let translationResult = fetchTranslation(word: key)

        // ждём оба
        let (dict, translation) = await (dictResult, translationResult)

        // если словарь вообще ничего не вернул — возвращаем nil
        guard let dict = dict else { return nil }

        let result = DictionaryResult(
            definition: dict.definition,
            phonetic: dict.phonetic,
            translation: translation ?? ""
        )
        saveToCache(word: key, result: result)
        return result
    }

    // гет запрос к апишке словаря
    private func fetchDictionary(word: String) async -> (definition: String, phonetic: String)? {
        guard let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(word)") else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            // проверка на ошибочки
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            guard let json = try? JSONDecoder().decode([DictEntry].self, from: data),
                  let first = json.first else { return nil }

            // берём транскрипцию — сначала из phonetic, потом из массива phonetics
            let phonetic = first.phonetic ?? first.phonetics?.first(where: { $0.text != nil })?.text ?? ""
            // берём первое определение из первого значения слова
            let definition = first.meanings?.first?.definitions?.first?.definition ?? ""

            return (definition: definition, phonetic: phonetic)
        } catch {
            return nil
        }
    }

    // перевод через неофициальный эндпоинт Google Translate
    private func fetchTranslation(word: String) async -> String? {
        // кодируем слово для URL
        guard let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }

        // неофициальный Google Translate API
        let urlString = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=ru&dt=t&q=\(encoded)"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }

            // ответ приходит как вложенный массив JSON
            // парсим вручную через JSONSerialization
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [Any],
                  let firstBlock = json.first as? [Any] else { return nil }

            // собираем все части перевода (слово может разбиться на несколько кусков)
            let parts = firstBlock.compactMap { item -> String? in
                guard let pair = item as? [Any],
                      let text = pair.first as? String else { return nil }
                return text
            }

            let result = parts.joined()
            guard !result.isEmpty, result.lowercased() != word.lowercased() else { return nil }
            return result

        } catch {
            return nil
        }
    }
}

private struct CachedEntry: Codable {
    let definition: String
    let phonetic: String
    let translation: String
}

// опциональные поля ибо может и ничего не вернуться
private struct DictEntry: Codable {
    let phonetic: String?
    let phonetics: [Phonetic]?
    let meanings: [Meaning]?
}

private struct Phonetic: Codable {
    let text: String?
}

private struct Meaning: Codable {
    let definitions: [Definition]?
}

private struct Definition: Codable {
    let definition: String
}
