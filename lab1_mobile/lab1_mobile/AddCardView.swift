
import SwiftUI

struct AddCardView: View {
    @EnvironmentObject private var store: CardStore
    @EnvironmentObject private var network: NetworkMonitor
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm = AddCardViewModel()

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Секция слова
                Section(header: Text(NSLocalizedString("section_word", comment: ""))) {

                    // поле ввода слова + кнопка камеры (ЛР4)
                    HStack {
                        TextField(NSLocalizedString("field_word", comment: ""), text: $vm.word)
                            .autocorrectionDisabled()
                            .onChange(of: vm.word) {
                                vm.onWordChanged(isConnected: network.isConnected)
                            }

                        // кнопка камеры — Platform API (ЛР4)
                        CameraButton { detectedText in
                            // когда сфотографировали — подставляем слово
                            vm.word = detectedText
                            vm.onWordChanged(isConnected: network.isConnected)
                        }
                    }

                    // транскрипция или спиннер загрузки
                    if vm.isLookingUp {
                        HStack(spacing: 8) {
                            ProgressView().scaleEffect(0.8)
                            Text(NSLocalizedString("lookup_loading", comment: ""))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else if !vm.phonetic.isEmpty {
                        Text(vm.phonetic)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }

                    // поле перевода
                    TextField(NSLocalizedString("field_translation", comment: ""),
                              text: $vm.translation, axis: .vertical)
                        .lineLimit(1...3)
                        .onChange(of: vm.translation) {
                            if !vm.word.trimmingCharacters(in: .whitespaces).isEmpty {
                                vm.onTranslationEditedByUser()
                            }
                        }
                }

                // MARK: - Секция definition / example
                Section {
                    Picker("", selection: $vm.useDefinition) {
                        Text(NSLocalizedString("picker_definition", comment: "")).tag(true)
                        Text(NSLocalizedString("picker_example", comment: "")).tag(false)
                    }
                    .pickerStyle(.segmented)

                    if vm.useDefinition {
                        TextField(NSLocalizedString("field_definition", comment: ""),
                                  text: $vm.definition, axis: .vertical)
                            .lineLimit(2...6)
                    } else {
                        TextField(NSLocalizedString("field_example", comment: ""),
                                  text: $vm.example, axis: .vertical)
                            .lineLimit(2...6)
                    }
                } header: {
                    Text(vm.useDefinition
                         ? NSLocalizedString("section_definition", comment: "")
                         : NSLocalizedString("section_example", comment: ""))
                }

                // MARK: - Статус сети
                if !network.isConnected {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "wifi.slash").foregroundStyle(.orange)
                            Text(NSLocalizedString("offline_mode", comment: ""))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: - Ошибка поиска
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
