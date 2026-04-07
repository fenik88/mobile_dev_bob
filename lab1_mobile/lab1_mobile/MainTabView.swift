import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label(NSLocalizedString("tab_cards", comment: ""), systemImage: "rectangle.stack.fill")
                }
            SettingsView()
                .tabItem {
                    Label(NSLocalizedString("tab_settings", comment: ""), systemImage: "gearshape.fill")
                }
        }
    }
}
