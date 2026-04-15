//
//  FirestoreService.swift
//  FlashWords
//
//  Удалённая база данных — Firebase Firestore
//  Синхронизирует карточки пользователя с облаком
//

import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private init() {}

    // ссылка на коллекцию карточек в Firestore
    // структура: /cards/{cardId}
    private let collection = Firestore.firestore().collection("cards")

    // MARK: - Сохранить карточку в Firestore

    func save(_ card: WordCard) async {
        // превращаем карточку в словарь для Firestore
        let data: [String: Any] = [
            "id":          card.id.uuidString,
            "word":        card.word,
            "translation": card.translation,
            "definition":  card.definition,
            "example":     card.example,
            "isLearned":   card.isLearned,
            "createdAt":   Timestamp(date: card.createdAt)
            // Timestamp — специальный тип Firestore для дат
            // аналог Date в Swift, но понятный Firestore
        ]

        do {
            // используем id карточки как ключ документа
            // setData — создаёт или перезаписывает документ
            try await collection.document(card.id.uuidString).setData(data)
        } catch {
            print("Firestore save error: \(error.localizedDescription)")
        }
    }

    // MARK: - Удалить карточку из Firestore

    func delete(_ card: WordCard) async {
        do {
            try await collection.document(card.id.uuidString).delete()
        } catch {
            print("Firestore delete error: \(error.localizedDescription)")
        }
    }

    // MARK: - Загрузить все карточки из Firestore

    func fetchAll() async -> [WordCard] {
        do {
            // getDocuments — одноразовый запрос (не realtime, это для ЛР4)
            let snapshot = try await collection.getDocuments()

            // превращаем каждый документ обратно в WordCard
            return snapshot.documents.compactMap { doc -> WordCard? in
                let data = doc.data()

                // достаём поля — все опциональные т.к. могут отсутствовать
                guard let idStr   = data["id"] as? String,
                      let id      = UUID(uuidString: idStr),
                      let word    = data["word"] as? String,
                      let trans   = data["translation"] as? String else {
                    return nil // пропускаем битые документы
                }

                let card = WordCard(
                    word:        word,
                    translation: trans,
                    definition:  data["definition"]  as? String ?? "",
                    example:     data["example"]     as? String ?? ""
                )
                card.id        = id
                card.isLearned = data["isLearned"]  as? Bool ?? false

                // Timestamp → Date
                if let ts = data["createdAt"] as? Timestamp {
                    card.createdAt = ts.dateValue()
                }

                return card
            }
        } catch {
            print("Firestore fetch error: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Синхронизировать все локальные карточки в Firestore

    func syncAll(_ cards: [WordCard]) async {
        // загружаем в параллель через withTaskGroup
        // аналог параллельного цикла — все save() запускаются одновременно
        await withTaskGroup(of: Void.self) { group in
            for card in cards {
                group.addTask {
                    await self.save(card)
                }
            }
        }
    }
}
