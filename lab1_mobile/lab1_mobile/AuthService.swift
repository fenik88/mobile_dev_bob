//
//  AuthService.swift
//  FlashWords
//
//  Аутентификация через Firebase Auth
//  Регистрация и вход по email + пароль
//

import Foundation
import FirebaseAuth

// состояние аутентификации — что сейчас происходит
enum AuthState {
    case idle           // ничего не происходит
    case loading        // идёт запрос
    case success        // успешно
    case error(String)  // ошибка с текстом
}

final class AuthService: ObservableObject {
    static let shared = AuthService()
    private init() {}

    // текущий пользователь — nil если не залогинен
    // Auth.auth().currentUser — системный объект Firebase
    var currentUser: FirebaseAuth.User? {
        Auth.auth().currentUser
    }

    // залогинен ли пользователь сейчас
    var isLoggedIn: Bool {
        currentUser != nil
    }

    // MARK: - Регистрация

    func register(email: String, password: String) async -> AuthState {
        do {
            // createUser — создаёт аккаунт в Firebase Auth
            // throws если email занят или пароль слабый
            try await Auth.auth().createUser(withEmail: email, password: password)
            return .success
        } catch {
            // localizedDescription — человекочитаемое сообщение об ошибке от Firebase
            return .error(error.localizedDescription)
        }
    }

    // MARK: - Вход

    func login(email: String, password: String) async -> AuthState {
        do {
            // signIn — входит в существующий аккаунт
            try await Auth.auth().signIn(withEmail: email, password: password)
            return .success
        } catch {
            return .error(error.localizedDescription)
        }
    }

    // MARK: - Выход

    func logout() {
        try? Auth.auth().signOut()
    }

    // MARK: - Email текущего пользователя

    var userEmail: String {
        currentUser?.email ?? ""
    }
}
