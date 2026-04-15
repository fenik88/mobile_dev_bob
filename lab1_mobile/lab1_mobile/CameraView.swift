//
//  CameraView.swift
//  FlashWords
//
//  Доступ к камере устройства (Platform API)
//  Позволяет сфотографировать слово из книги или учебника
//

import SwiftUI
import PhotosUI

// MARK: - Обёртка над UIImagePickerController для SwiftUI

// UIViewControllerRepresentable — мост между UIKit и SwiftUI
// Нужен потому что камера в iOS — это UIKit контроллер
// В Java/Android это был бы startActivityForResult с Intent.ACTION_IMAGE_CAPTURE
struct CameraView: UIViewControllerRepresentable {
    // замыкание — вызывается когда пользователь сделал фото
    var onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    // Coordinator — вспомогательный класс для обработки событий
    // аналог callback/listener в Java
    // нужен потому что UIImagePickerController работает через делегат (паттерн Delegate)
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        // вызывается когда пользователь выбрал/сфотографировал изображение
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            // достаём изображение из словаря info
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }

        // вызывается если пользователь нажал Отмена
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // создаём UIImagePickerController — системный экран камеры
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType  = .camera        // используем камеру, не галерею
        picker.delegate    = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    // обновление не нужно — камера не меняет состояние
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// MARK: - Кнопка для открытия камеры

struct CameraButton: View {
    @State private var showCamera  = false
    @State private var capturedImage: UIImage?
    @State private var showPreview = false

    // обратный вызов — что делать с текстом распознанным на фото
    var onTextDetected: (String) -> Void

    var body: some View {
        Button {
            // проверяем доступна ли камера (нет на симуляторе)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                showCamera = true
            }
        } label: {
            Image(systemName: "camera")
                .font(.system(size: 18))
        }
        .sheet(isPresented: $showCamera) {
            CameraView { image in
                capturedImage = image
                // передаём заглушку — в реальном приложении тут был бы OCR
                // для лабораторной достаточно показать что камера работает
                onTextDetected("photo_word")
            }
            .ignoresSafeArea()
        }
    }
}
