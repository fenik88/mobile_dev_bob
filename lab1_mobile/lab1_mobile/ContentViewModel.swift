import Foundation
import Combine

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var searchText: String = ""

    func filtered(cards: [WordCard]) -> [WordCard] {
        guard !searchText.isEmpty else { return cards }//возвращаем без фильтрации
        return cards.filter {
            $0.word.localizedCaseInsensitiveContains(searchText) ||
            $0.translation.localizedCaseInsensitiveContains(searchText)
        }
    }
}
