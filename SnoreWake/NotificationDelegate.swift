//
//  NotificationDelegate.swift
//  SnoreWake
//
//  Created by Andrew Foong on 05/10/2025.
//

import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let thread = response.notification.request.content.threadIdentifier
        switch response.actionIdentifier {
        case "STOP_ALARM":
            AlarmScheduler.cancelThread(thread)
        case "SNOOZE_5":
            AlarmScheduler.cancelThread(thread) {
                AlarmScheduler.scheduleRepeating(thread: thread,
                                                 startInSeconds: 300,
                                                 intervalSeconds: 3,
                                                 totalDurationSeconds: 180)
            }
        default:
            break
        }
        completionHandler()
    }
}

enum NotificationCategories {
    static let alarm = "ALARM_CAT"

    static func register() {
        let stop = UNNotificationAction(identifier: "STOP_ALARM", title: "Stop", options: [.destructive])
        let snooze = UNNotificationAction(identifier: "SNOOZE_5", title: "Snooze 5 min", options: [])
        let cat = UNNotificationCategory(identifier: alarm, actions: [stop, snooze], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([cat])
    }
}
