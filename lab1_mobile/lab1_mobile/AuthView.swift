//
//  AuthView.swift
//  FlashWords
//
//  Экран входа и регистрации
//

import SwiftUI

struct AuthView: View {
    @State private var email: String    = ""
    @State private var password: String = ""
    @State private var isLogin: Bool    = true   // true = вход, false = регистрация
    @State private var isLoading: Bool  = false
    @State private var errorMessage: String? = nil

    // замыкание которое вызывается после успешного входа
    // передаётся из SplashView
    var onSuccess: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                // MARK: - Логотип
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.stack.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(.blue)
                    Text("FlashWords")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }
                .padding(.top, 40)

                // MARK: - Переключатель Вход / Регистрация
                Picker("", selection: $isLogin) {
                    Text(NSLocalizedString("auth_login", comment: "")).tag(true)
                    Text(NSLocalizedString("auth_register", comment: "")).tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // MARK: - Поля ввода
                VStack(spacing: 12) {
                    TextField(NSLocalizedString("auth_email", comment: ""), text: $email)
                        .keyboardType(.emailAddress)       // показывает клавиатуру с @
                        .autocapitalization(.none)         // не делать заглавной первую букву
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                    SecureField(NSLocalizedString("auth_password", comment: ""), text: $password)
                        .textFieldStyle(.roundedBorder)    // SecureField — скрывает символы
                }
                .padding(.horizontal)

                // MARK: - Сообщение об ошибке
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // MARK: - Кнопка действия
                Button {
                    Task { await handleAuth() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    } else {
                        Text(isLogin
                             ? NSLocalizedString("auth_login", comment: "")
                             : NSLocalizedString("auth_register", comment: ""))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }

    // MARK: - Обработка входа/регистрации

    private func handleAuth() async {
        // убираем ошибку и показываем спиннер
        errorMessage = nil
        isLoading    = true

        let state: AuthState

        if isLogin {
            state = await AuthService.shared.login(email: email, password: password)
        } else {
            state = await AuthService.shared.register(email: email, password: password)
        }

        isLoading = false

        switch state {
        case .success:
            onSuccess() // сообщаем родителю что всё ок
        case .error(let msg):
            errorMessage = msg
        default:
            break
        }
    }
}
