//
//  ContentView.swift
//  FlashWords
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: CardStore
    @EnvironmentObject private var network: NetworkMonitor
    @StateObject private var vm = ContentViewModel()
    @State private var showingAdd = false
    @State private var showingFilters = false

    var body: some View {
        NavigationStack {
            cardListContent
                .navigationTitle("FlashWords")
                .toolbar { toolbarContent }
                .sheet(isPresented: $showingAdd) { AddCardView() }
                .sheet(isPresented: $showingFilters) { FilterSortView(vm: vm) }
        }
    }

    // MARK: - Основной контент

    @ViewBuilder
    private var cardListContent: some View {
        if store.cards.isEmpty {
            emptyState
        } else {
            cardList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text(NSLocalizedString("empty_state", comment: ""))
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var cardList: some View {
        List {
            ForEach(vm.filtered(cards: store.cards)) { card in
                NavigationLink(destination: CardDetailView(card: card)) {
                    CardRowView(card: card)
                }
            }
            .onDelete(perform: deleteCards)
        }
        .searchable(text: $vm.searchText,
                    prompt: NSLocalizedString("search_placeholder", comment: ""))
    }

    private func deleteCards(at offsets: IndexSet) {
        let filtered = vm.filtered(cards: store.cards)
        offsets.map { filtered[$0] }.forEach { card in
            store.delete(card: card)
        }
    }

    // MARK: - Тулбар

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { showingAdd = true } label: {
                Image(systemName: "plus")
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            filterButton
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            syncButton
        }
        ToolbarItem(placement: .navigationBarLeading) {
            offlineLabel
        }
    }

    private var filterButton: some View {
        // явно указываем Color чтобы Swift не путал .primary (HierarchicalShapeStyle) и .blue (Color)
        let color: Color = vm.filterOption == .all ? .primary : .blue
        return Button { showingFilters = true } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundStyle(color)
        }
    }

    private var syncButton: some View {
        Button {
            Task { await vm.syncToFirestore(cards: store.cards) }
        } label: {
            if vm.isSyncing {
                ProgressView().scaleEffect(0.8)
            } else {
                Image(systemName: "icloud.and.arrow.up")
            }
        }
        .disabled(vm.isSyncing || !network.isConnected)
    }

    @ViewBuilder
    private var offlineLabel: some View {
        if !network.isConnected {
            Label(NSLocalizedString("offline_mode", comment: ""),
                  systemImage: "wifi.slash")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }
}

// MARK: - Строка карточки в списке

struct CardRowView: View {
    @ObservedObject var card: WordCard

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(card.word)
                    .font(.headline)
                Text(card.translation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if card.isLearned {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Sheet с фильтрами и сортировкой

struct FilterSortView: View {
    @ObservedObject var vm: ContentViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                sortSection
                filterSection
                resetSection
            }
            .navigationTitle(NSLocalizedString("filter_sheet_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("done", comment: "")) { dismiss() }
                }
            }
        }
    }

    private var sortSection: some View {
        Section(header: Text(NSLocalizedString("sort_title", comment: ""))) {
            ForEach(SortOption.allCases, id: \.self) { option in
                HStack {
                    Text(NSLocalizedString(option.rawValue, comment: ""))
                    Spacer()
                    if vm.sortOption == option {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { vm.sortOption = option }
            }
        }
    }

    private var filterSection: some View {
        Section(header: Text(NSLocalizedString("filter_title", comment: ""))) {
            ForEach(FilterOption.allCases, id: \.self) { option in
                HStack {
                    Text(NSLocalizedString(option.rawValue, comment: ""))
                    Spacer()
                    if vm.filterOption == option {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { vm.filterOption = option }
            }
        }
    }

    private var resetSection: some View {
        Section {
            Button(NSLocalizedString("filter_reset", comment: "")) {
                vm.sortOption   = .dateDesc
                vm.filterOption = .all
            }
            .foregroundStyle(Color.red)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CardStore())
        .environmentObject(NetworkMonitor.shared)
}
