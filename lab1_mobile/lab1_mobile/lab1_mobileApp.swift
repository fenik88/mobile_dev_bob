//
//  lab1_mobileApp.swift
//  FlashWords
//

import SwiftUI
import FirebaseCore

@main
struct lab1_mobileApp: App {
    @StateObject private var store = CardStore.shared
    @StateObject private var network = NetworkMonitor.shared
    @AppStorage("appTheme") private var appTheme: String = "system"

    // инициализируем Firebase при запуске приложения
    init() {
        FirebaseApp.configure()
    }

    var preferredColorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(store)
                .environmentObject(network)
                .preferredColorScheme(preferredColorScheme)
        }
    }
}
