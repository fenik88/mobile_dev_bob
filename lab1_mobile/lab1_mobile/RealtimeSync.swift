//
//  RealtimeSync.swift
//  FlashWords
//
//  Подписка на изменения в Firestore в реальном времени
//  При любом изменении в облаке — карточки обновляются без перезагрузки
//

import Foundation
import FirebaseFirestore

final class RealtimeSync: ObservableObject {
    static let shared = RealtimeSync()
    private init() {}

    // ListenerRegistration — токен подписки
    // нужен чтобы отписаться когда объект уничтожается
    // аналог unsubscribe() в Java RxJava или EventHandler в C#
    private var listener: ListenerRegistration?

    // MARK: - Начать слушать изменения

    func startListening(store: CardStore) {
        // если уже слушаем — сначала останавливаем
        stopListening()

        let collection = Firestore.firestore().collection("cards")

        // addSnapshotListener — подписка на realtime обновления
        // вызывается КАЖДЫЙ РАЗ когда данные в Firestore меняются
        // не нужно делать повторные запросы — Firebase сам присылает изменения
        listener = collection.addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                print("Realtime sync error: \(error?.localizedDescription ?? "unknown")")
                return
            }

            // documentChanges — только то что ИЗМЕНИЛОСЬ, не весь список
            // это эффективнее чем перезагружать все карточки каждый раз
            for change in snapshot.documentChanges {
                let data = change.document.data()

                switch change.type {
                case .added, .modified:
                    // новая карточка или изменённая — обновляем локально
                    guard let idStr = data["id"] as? String,
                          let id    = UUID(uuidString: idStr),
                          let word  = data["word"] as? String,
                          let trans = data["translation"] as? String else { continue }

                    DispatchQueue.main.async {
                        // ищем карточку в локальном хранилище
                        if let existing = store.cards.first(where: { $0.id == id }) {
                            // обновляем существующую
                            existing.word        = word
                            existing.translation = trans
                            existing.definition  = data["definition"]  as? String ?? ""
                            existing.example     = data["example"]     as? String ?? ""
                            existing.isLearned   = data["isLearned"]   as? Bool   ?? false
                            store.objectWillChange.send()
                        }
                        // если карточки нет локально — не добавляем
                        // (она придёт при следующем запуске через fetchAll)
                    }

                case .removed:
                    // карточка удалена в облаке — удаляем локально
                    guard let idStr = data["id"] as? String,
                          let id    = UUID(uuidString: idStr) else { continue }

                    DispatchQueue.main.async {
                        store.cards.removeAll { $0.id == id }
                        store.objectWillChange.send()
                    }

                @unknown default:
                    break
                }
            }
        }
    }

    // MARK: - Остановить прослушивание

    func stopListening() {
        listener?.remove() // отписываемся от Firebase
        listener = nil
    }
}
