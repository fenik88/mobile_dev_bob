import SwiftUI

struct SettingsView: View {
    @AppStorage("appTheme") private var appTheme: String = "system"

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(NSLocalizedString("settings_appearance", comment: ""))) {
                    Picker(NSLocalizedString("settings_theme", comment: ""), selection: $appTheme) {
                        Text(NSLocalizedString("theme_system", comment: "")).tag("system")
                        Text(NSLocalizedString("theme_light", comment: "")).tag("light")
                        Text(NSLocalizedString("theme_dark", comment: "")).tag("dark")
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text(NSLocalizedString("settings_about", comment: ""))) {
                    HStack {
                        Text(NSLocalizedString("about_app", comment: ""))
                        Spacer()
                        Text("FlashWords")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text(NSLocalizedString("about_version", comment: ""))
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("tab_settings", comment: ""))
        }
    }
}
