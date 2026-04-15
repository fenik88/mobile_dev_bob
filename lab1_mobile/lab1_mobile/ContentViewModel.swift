//
//  ContentViewModel.swift
//  FlashWords
//
//  Содержит всю логику главного экрана:
//  - точный и нечёткий поиск
//  - фильтрация по статусу
//  - сортировка
//  - синхронизация с Firestore
//

import Foundation
import Combine

// перечисление вариантов сортировки
// enum в Swift — как enum в Java/C#
enum SortOption: String, CaseIterable {
    case dateDesc  = "sort_date_desc"   // новые сначала (по умолчанию)
    case dateAsc   = "sort_date_asc"    // старые сначала
    case wordAZ    = "sort_word_az"     // по алфавиту А→Я
    case wordZA    = "sort_word_za"     // по алфавиту Я→А
}

// фильтр по статусу "выучено"
enum FilterOption: String, CaseIterable {
    case all        = "filter_all"       // все карточки
    case learned    = "filter_learned"   // только выученные
    case notLearned = "filter_not"       // только не выученные
}

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var searchText: String  = ""
    @Published var sortOption: SortOption   = .dateDesc
    @Published var filterOption: FilterOption = .all
    @Published var isSyncing: Bool = false  // индикатор синхронизации с Firestore

    // MARK: - Основной метод: поиск + фильтр + сортировка

    func filtered(cards: [WordCard]) -> [WordCard] {
        var result = cards

        // 1. Применяем фильтр по статусу
        switch filterOption {
        case .all:        break // ничего не делаем
        case .learned:    result = result.filter { $0.isLearned }
        case .notLearned: result = result.filter { !$0.isLearned }
        }

        // 2. Применяем поиск если текст не пустой
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            result = search(in: result, query: searchText)
        }

        // 3. Применяем сортировку
        result = sort(result)

        return result
    }

    // MARK: - Поиск: точный + нечёткий

    private func search(in cards: [WordCard], query: String) -> [WordCard] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)

        // сначала пробуем точное совпадение (contains)
        let exact = cards.filter {
            $0.word.localizedCaseInsensitiveContains(q) ||
            $0.translation.localizedCaseInsensitiveContains(q)
        }

        // если точных совпадений достаточно — возвращаем их
        if !exact.isEmpty { return exact }

        // иначе — нечёткий поиск по алгоритму Левенштейна
        // возвращаем карточки с расстоянием редактирования ≤ 2
        // т.е. допускаем до 2 опечаток
        return cards.filter {
            levenshtein($0.word.lowercased(), q) <= 2 ||
            levenshtein($0.translation.lowercased(), q) <= 2
        }
    }

    // MARK: - Алгоритм Левенштейна (расстояние редактирования)
    //
    // Считает минимальное количество операций (вставка, удаление, замена)
    // чтобы превратить одну строку в другую
    //
    // Например: "cat" → "cut" = 1 операция (замена a→u)
    //           "hello" → "helo" = 1 операция (удаление l)
    //
    // В C++ это был бы двумерный массив с динамическим программированием:
    // int dp[n+1][m+1]; for(i...) for(j...) dp[i][j] = min(...)

    private func levenshtein(_ s: String, _ t: String) -> Int {
        let s = Array(s), t = Array(t)
        let n = s.count, m = t.count

        // если одна из строк пустая — расстояние = длина другой
        if n == 0 { return m }
        if m == 0 { return n }

        // создаём матрицу (n+1) × (m+1)
        // dp[i][j] = расстояние между первыми i символами s и j символами t
        var dp = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)

        // база: превратить пустую строку в t — нужно m вставок
        for i in 0...n { dp[i][0] = i }
        // база: превратить s в пустую — нужно n удалений
        for j in 0...m { dp[0][j] = j }

        // заполняем матрицу
        for i in 1...n {
            for j in 1...m {
                if s[i-1] == t[j-1] {
                    // символы совпадают — операция не нужна
                    dp[i][j] = dp[i-1][j-1]
                } else {
                    // берём минимум из трёх операций:
                    // dp[i-1][j]   — удаление символа из s
                    // dp[i][j-1]   — вставка символа в s
                    // dp[i-1][j-1] — замена символа
                    dp[i][j] = 1 + min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1])
                }
            }
        }

        return dp[n][m]
    }

    // MARK: - Сортировка

    private func sort(_ cards: [WordCard]) -> [WordCard] {
        switch sortOption {
        case .dateDesc: return cards.sorted { $0.createdAt > $1.createdAt }
        case .dateAsc:  return cards.sorted { $0.createdAt < $1.createdAt }
        case .wordAZ:   return cards.sorted { $0.word.lowercased() < $1.word.lowercased() }
        case .wordZA:   return cards.sorted { $0.word.lowercased() > $1.word.lowercased() }
        }
    }

    // MARK: - Синхронизация с Firestore

    func syncToFirestore(cards: [WordCard]) async {
        isSyncing = true
        await FirestoreService.shared.syncAll(cards)
        isSyncing = false
    }
}
