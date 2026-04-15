//
//  NotificationManager.swift
//  FlashWords
//
//  Управление локальными уведомлениями по расписанию
//  Напоминает пользователю учить слова каждый день
//

import Foundation
import UserNotifications

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private init() {}

    // id уведомления — нужен чтобы отменять и перепланировать
    private let notificationID = "daily_reminder"

    // MARK: - Запросить разрешение на уведомления

    // iOS требует явного согласия пользователя
    // вызывается один раз при первом запуске
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            // просим разрешение на показ уведомлений со звуком и бейджем
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Запланировать ежедневное уведомление

    func scheduleDailyReminder(hour: Int, minute: Int) async {
        let center = UNUserNotificationCenter.current()

        // сначала отменяем старое уведомление если было
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])

        // содержимое уведомления
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification_title", comment: "")
        content.body  = NSLocalizedString("notification_body", comment: "")
        content.sound = .default

        // триггер по времени — срабатывает каждый день в заданное время
        // DateComponents — указываем только час и минуту, без даты
        // iOS сам разберётся "следующее вхождение этого времени"
        var components = DateComponents()
        components.hour   = hour
        components.minute = minute

        // repeats: true — повторяется каждый день
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        // создаём запрос на уведомление
        let request = UNNotificationRequest(
            identifier: notificationID,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            print("Notification scheduled for \(hour):\(String(format: "%02d", minute))")
        } catch {
            print("Notification error: \(error.localizedDescription)")
        }
    }

    // MARK: - Отменить уведомление

    func cancelReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationID])
    }

    // MARK: - Проверить есть ли активное уведомление

    func isScheduled() async -> Bool {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.contains { $0.identifier == notificationID }
    }
}
