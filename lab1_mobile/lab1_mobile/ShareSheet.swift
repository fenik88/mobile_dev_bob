//
//  ShareSheet.swift
//  FlashWords
//
//  Интеграция с соцсетями через системный Share Sheet
//  Позволяет поделиться карточкой в любом приложении (Telegram, VK, почта и др.)
//

import SwiftUI

// MARK: - Обёртка над UIActivityViewController для SwiftUI

// UIActivityViewController — системный шаринг iOS
// При нажатии "Поделиться" появляется стандартный попап с иконками соцсетей
// В Java/Android аналог — Intent.ACTION_SEND + startActivity(Intent.createChooser(...))
struct ShareSheet: UIViewControllerRepresentable {
    // что шарим — массив объектов (текст, изображения, URL)
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        // UIActivityViewController сам определяет какие приложения могут принять эти данные
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil // nil = использовать системные активности
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Кнопка "Поделиться" для карточки

struct ShareCardButton: View {
    let card: WordCard
    @State private var showShare = false

    var body: some View {
        Button {
            showShare = true
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: [shareText])
                .presentationDetents([.medium, .large]) // высота попапа
        }
    }

    // текст который будет отправлен в соцсети
    private var shareText: String {
        var text = "📚 \(card.word) — \(card.translation)"

        if !card.definition.isEmpty {
            text += "\n\n\(card.definition)"
        }

        if !card.example.isEmpty {
            text += "\n\nExample: \(card.example)"
        }

        text += "\n\n#FlashWords #English"
        return text
    }
}
