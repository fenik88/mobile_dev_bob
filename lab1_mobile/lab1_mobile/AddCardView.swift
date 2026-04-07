
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
                    // поле ввода слова
                    TextField(NSLocalizedString("field_word", comment: ""), text: $vm.word)
                        .autocorrectionDisabled()
                        .onChange(of: vm.word) {
                            vm.onWordChanged(isConnected: network.isConnected)
                        }

                    // транскрипция или спиннер загрузки
                    if vm.isLookingUp {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(NSLocalizedString("lookup_loading", comment: ""))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else if !vm.phonetic.isEmpty {
                        // транскрипция пришла из API
                        Text(vm.phonetic)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }

                    // поле перевода заполняется из API, можно редактировать вручную
                    // если пользователь редактирует сам API больше не перезаписывает
                    TextField(NSLocalizedString("field_translation", comment: ""), text: $vm.translation, axis: .vertical)
                        .lineLimit(1...3)
                        .onChange(of: vm.translation) {
                            // сообщаем вьюмодели что пользователь сам трогал поле
                            // но только если слово уже есть — иначе это просто очистка при смене слова
                            if !vm.word.trimmingCharacters(in: .whitespaces).isEmpty {
                                vm.onTranslationEditedByUser()
                            }
                        }
                }

                Section {
                    // переключатель: definition из API или свой пример
                    Picker("", selection: $vm.useDefinition) {
                        Text(NSLocalizedString("picker_definition", comment: "")).tag(true)
                        Text(NSLocalizedString("picker_example", comment: "")).tag(false)
                    }
                    .pickerStyle(.segmented)

                    if vm.useDefinition {
                        // definition из API — показываем как текст, можно редактировать
                        TextField(
                            NSLocalizedString("field_definition", comment: ""),
                            text: $vm.definition,
                            axis: .vertical
                        )
                        .lineLimit(2...6)
                        .foregroundStyle(vm.definition.isEmpty ? .secondary : .primary)
                    } else {
                        // пользователь пишет свой пример использования
                        TextField(
                            NSLocalizedString("field_example", comment: ""),
                            text: $vm.example,
                            axis: .vertical
                        )
                        .lineLimit(2...6)
                    }
                } header: {
                    Text(vm.useDefinition
                         ? NSLocalizedString("section_definition", comment: "")
                         : NSLocalizedString("section_example", comment: ""))
                }
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
