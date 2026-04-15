//
//  MainTabView.swift
//  FlashWords
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: CardStore

    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label(NSLocalizedString("tab_cards", comment: ""),
                          systemImage: "rectangle.stack.fill")
                }
            SettingsView()
                .tabItem {
                    Label(NSLocalizedString("tab_settings", comment: ""),
                          systemImage: "gearshape.fill")
                }
        }
        .onAppear {
            // запускаем realtime подписку на Firestore когда открылось основное окно (ЛР4)
            RealtimeSync.shared.startListening(store: store)
        }
        .onDisappear {
            // отписываемся когда закрылось
            RealtimeSync.shared.stopListening()
        }
    }
}
