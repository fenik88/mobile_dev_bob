//
//  SplashView.swift
//  FlashWords
//

import SwiftUI

struct SplashView: View {
    @State private var isActive    = false
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0
    @State private var isLoggedIn  = false

    var body: some View {
        if isActive {
            if isLoggedIn {
                // пользователь залогинен — показываем основной экран
                MainTabView()
            } else {
                // не залогинен — показываем экран входа
                AuthView {
                    // после успешного входа переходим на основной экран
                    isLoggedIn = true
                }
            }
        } else {
            // сплеш-экран
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "rectangle.stack.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .foregroundStyle(.blue)

                    Text("FlashWords")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(NSLocalizedString("splash_subtitle", comment: ""))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    // анимация появления
                    withAnimation(.easeOut(duration: 0.6)) {
                        scale   = 1.0
                        opacity = 1.0
                    }

                    // проверяем авторизацию и переходим дальше через 2 сек
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        // проверяем залогинен ли пользователь в Firebase
                        isLoggedIn = AuthService.shared.isLoggedIn
                        withAnimation(.easeIn(duration: 0.3)) {
                            isActive = true
                        }
                    }
                }
            }
        }
    }
}
