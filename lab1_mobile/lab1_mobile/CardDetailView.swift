
import SwiftUI

struct CardDetailView: View {
    @EnvironmentObject private var store: CardStore
    @ObservedObject var card: WordCard

    @State private var isEditing      = false
    @State private var editWord       = ""
    @State private var editTranslation = ""
    @State private var editDefinition = ""
    @State private var editExample    = ""
    @State private var showTranslation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - Карточка (переворот по тапу)
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(radius: 6)

                    VStack(spacing: 12) {
                        Text(showTranslation ? card.translation : card.word)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding()

                        Text(showTranslation
                             ? NSLocalizedString("label_translation", comment: "")
                             : NSLocalizedString("label_word", comment: ""))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .frame(height: 180)
                .padding(.horizontal)
                .onTapGesture {
                    withAnimation(.spring()) { showTranslation.toggle() }
                }

                Text(NSLocalizedString("tap_to_flip", comment: ""))
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                // MARK: - Определение
                if !card.definition.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(NSLocalizedString("section_definition", comment: ""))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(card.definition)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }

                // MARK: - Пример
                if !card.example.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(NSLocalizedString("section_example", comment: ""))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(card.example)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }

                // MARK: - Тоггл "Выучено"
                Toggle(isOn: Binding(
                    get: { card.isLearned },
                    set: { _ in store.toggleLearned(card) }
                )) {
                    Label(NSLocalizedString("mark_learned", comment: ""),
                          systemImage: "checkmark.circle")
                }
                .padding(.horizontal)

                // MARK: - Дата
                Text(String(format: NSLocalizedString("added_date", comment: ""),
                            card.createdAt.formatted(date: .long, time: .omitted)))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            .padding(.top)
        }
        .navigationTitle(card.word)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // кнопка "Поделиться" — соцсети (ЛР4)
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareCardButton(card: card)
            }
            // кнопка редактирования
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(NSLocalizedString("edit", comment: "")) {
                    editWord        = card.word
                    editTranslation = card.translation
                    editDefinition  = card.definition
                    editExample     = card.example
                    isEditing       = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditCardSheet(
                word:        $editWord,
                translation: $editTranslation,
                definition:  $editDefinition,
                example:     $editExample,
                onSave: {
                    store.update(
                        card,
                        word:        editWord.trimmingCharacters(in: .whitespaces),
                        translation: editTranslation.trimmingCharacters(in: .whitespaces),
                        definition:  editDefinition.trimmingCharacters(in: .whitespaces),
                        example:     editExample.trimmingCharacters(in: .whitespaces)
                    )
                    isEditing = false
                },
                onCancel: { isEditing = false }
            )
        }
    }
}

// MARK: - Лист редактирования

struct EditCardSheet: View {
    @Binding var word: String
    @Binding var translation: String
    @Binding var definition: String
    @Binding var example: String
    var onSave: () -> Void
    var onCancel: () -> Void

    var isValid: Bool {
        !word.trimmingCharacters(in: .whitespaces).isEmpty &&
        !translation.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(NSLocalizedString("section_word", comment: ""))) {
                    TextField(NSLocalizedString("field_word", comment: ""), text: $word)
                    TextField(NSLocalizedString("field_translation", comment: ""), text: $translation)
                }
                if !definition.isEmpty {
                    Section(header: Text(NSLocalizedString("section_definition", comment: ""))) {
                        TextField(NSLocalizedString("field_definition", comment: ""),
                                  text: $definition, axis: .vertical)
                            .lineLimit(2...6)
                    }
                }
                Section(header: Text(NSLocalizedString("section_example", comment: ""))) {
                    TextField(NSLocalizedString("field_example", comment: ""),
                              text: $example, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(NSLocalizedString("edit_card_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: ""), action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("save", comment: ""), action: onSave)
                        .disabled(!isValid)
                }
            }
        }
    }
}
