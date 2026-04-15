//
//  SettingsView.swift
//  FlashWords
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("appTheme")            private var appTheme: String = "system"
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    @AppStorage("notificationHour")    private var notificationHour: Int = 9
    @AppStorage("notificationMinute")  private var notificationMinute: Int = 0

    @State private var notificationTime: Date = Calendar.current.date(
        bySettingHour: 9, minute: 0, second: 0, of: Date()
    ) ?? Date()

    @State private var showLogoutAlert = false

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Тема
                Section(header: Text(NSLocalizedString("settings_appearance", comment: ""))) {
                    Picker(NSLocalizedString("settings_theme", comment: ""), selection: $appTheme) {
                        Text(NSLocalizedString("theme_system", comment: "")).tag("system")
                        Text(NSLocalizedString("theme_light", comment: "")).tag("light")
                        Text(NSLocalizedString("theme_dark", comment: "")).tag("dark")
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: - Уведомления
                Section(header: Text(NSLocalizedString("settings_notifications", comment: ""))) {
                    Toggle(NSLocalizedString("notifications_daily", comment: ""),
                           isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) {
                            handleNotificationToggle(notificationsEnabled)
                        }

                    if notificationsEnabled {
                        DatePicker(
                            NSLocalizedString("notifications_time", comment: ""),
                            selection: $notificationTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: notificationTime) {
                            let cal = Calendar.current
                            notificationHour   = cal.component(.hour,   from: notificationTime)
                            notificationMinute = cal.component(.minute, from: notificationTime)
                            Task {
                                await NotificationManager.shared.scheduleDailyReminder(
                                    hour: notificationHour,
                                    minute: notificationMinute
                                )
                            }
                        }
                    }
                }

                // MARK: - Аккаунт
                Section(header: Text(NSLocalizedString("settings_account", comment: ""))) {
                    HStack {
                        Text(NSLocalizedString("account_email", comment: ""))
                        Spacer()
                        Text(AuthService.shared.userEmail)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Button(NSLocalizedString("account_logout", comment: "")) {
                        showLogoutAlert = true
                    }
                    .foregroundStyle(Color.red)
                }

                // MARK: - О приложении
                Section(header: Text(NSLocalizedString("settings_about", comment: ""))) {
                    HStack {
                        Text(NSLocalizedString("about_app", comment: ""))
                        Spacer()
                        Text("FlashWords").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text(NSLocalizedString("about_version", comment: ""))
                        Spacer()
                        Text("4.1.3").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("tab_settings", comment: ""))
            .onAppear {
                notificationTime = Calendar.current.date(
                    bySettingHour: notificationHour,
                    minute: notificationMinute,
                    second: 0,
                    of: Date()
                ) ?? Date()
            }
            .alert(NSLocalizedString("account_logout", comment: ""),
                   isPresented: $showLogoutAlert) {
                Button(NSLocalizedString("account_logout_confirm", comment: ""), role: .destructive) {
                    AuthService.shared.logout()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NotificationManager.shared.cancelReminder()
                        exit(0)
                    }
                }
                Button(NSLocalizedString("cancel", comment: ""), role: .cancel) {}
            } message: {
                Text(NSLocalizedString("account_logout_message", comment: ""))
            }
        }
    }

    private func handleNotificationToggle(_ enabled: Bool) {
        Task {
            if enabled {
                let granted = await NotificationManager.shared.requestPermission()
                if granted {
                    await NotificationManager.shared.scheduleDailyReminder(
                        hour: notificationHour,
                        minute: notificationMinute
                    )
                } else {
                    await MainActor.run { notificationsEnabled = false }
                }
            } else {
                NotificationManager.shared.cancelReminder()
            }
        }
    }
}
