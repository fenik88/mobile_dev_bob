//https://dictionaryapi.dev

import Foundation

struct DictionaryResult {
    let definition: String
    let phonetic: String
}

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
        return raw.mapValues { DictionaryResult(definition: $0.definition, phonetic: $0.phonetic) }
    }

    private func saveToCache(word: String, result: DictionaryResult) {
        var raw = (try? JSONDecoder().decode(
            [String: CachedEntry].self,
            from: UserDefaults.standard.data(forKey: cacheKey) ?? Data()
        )) ?? [:]
        raw[word.lowercased()] = CachedEntry(definition: result.definition, phonetic: result.phonetic)
        if let data = try? JSONEncoder().encode(raw) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

// поиск
    func lookup(word: String) async -> DictionaryResult? {
        let key = word.lowercased().trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return nil }

        // Сначала проверяем кэш
        let cache = loadCache()
        if let cached = cache[key] { return cached }

        // гет запрос к апишке
        guard let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(key)") else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            guard let json = try? JSONDecoder().decode([DictEntry].self, from: data),
                  let first = json.first else { return nil }

            let phonetic = first.phonetic ?? first.phonetics?.first(where: { $0.text != nil })?.text ?? ""
            let definition = first.meanings?.first?.definitions?.first?.definition ?? ""

            let result = DictionaryResult(definition: definition, phonetic: phonetic)
            saveToCache(word: key, result: result)
            return result
        } catch {
            return nil
        }
    }
}


private struct CachedEntry: Codable {
    let definition: String
    let phonetic: String
}

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
