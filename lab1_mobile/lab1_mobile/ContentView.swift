
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: CardStore
    @EnvironmentObject private var network: NetworkMonitor
    @StateObject private var vm = ContentViewModel()
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if store.cards.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "rectangle.stack.badge.plus")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text(NSLocalizedString("empty_state", comment: ""))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(vm.filtered(cards: store.cards)) { card in
                            NavigationLink(destination: CardDetailView(card: card)) {
                                CardRowView(card: card)
                            }
                        }
                        .onDelete { offsets in
                            let filtered = vm.filtered(cards: store.cards)
                            offsets.map { filtered[$0] }.forEach { store.delete(card: $0) }
                        }
                    }
                    .searchable(text: $vm.searchText,
                                prompt: NSLocalizedString("search_placeholder", comment: ""))
                }
            }
            .navigationTitle("FlashWords")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
                // Индикатор офлайн-режима
                ToolbarItem(placement: .navigationBarLeading) {
                    if !network.isConnected {
                        Label(NSLocalizedString("offline_mode", comment: ""), systemImage: "wifi.slash")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddCardView()
            }
        }
    }
}

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

#Preview {
    ContentView()
        .environmentObject(CardStore())
        .environmentObject(NetworkMonitor.shared)
}
