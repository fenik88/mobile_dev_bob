
import SwiftUI

struct AddCardView: View {
    @EnvironmentObject private var store: CardStore
    @EnvironmentObject private var network: NetworkMonitor
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm = AddCardViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(NSLocalizedString("section_word", comment: ""))) {
                    TextField(NSLocalizedString("field_word", comment: ""), text: $vm.word)
                        .autocorrectionDisabled()
                        .onChange(of: vm.word) {
                            vm.onWordChanged(isConnected: network.isConnected)
                        }

                    // Фонетика + индикатор загрузки
                    if vm.isLookingUp {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(NSLocalizedString("lookup_loading", comment: ""))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else if !vm.phonetic.isEmpty {
                        Text(vm.phonetic)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }

                    TextField(NSLocalizedString("field_translation", comment: ""), text: $vm.translation, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section(header: Text(NSLocalizedString("section_example", comment: ""))) {
                    TextField(NSLocalizedString("field_example", comment: ""), text: $vm.example, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Статус сети
                if !network.isConnected {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "wifi.slash")
                                .foregroundStyle(.orange)
                            Text(NSLocalizedString("offline_mode", comment: ""))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Ошибка поиска
                if let error = vm.lookupError {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("add_card_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("save", comment: "")) {
                        vm.save(to: store)
                        dismiss()
                    }
                    .disabled(!vm.isValid)
                }
            }
        }
    }
}
