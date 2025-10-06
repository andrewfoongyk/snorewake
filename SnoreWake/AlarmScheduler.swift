//
//  AlarmScheduler.swift
//  SnoreWake
//
//  Created by Andrew Foong on 05/10/2025.
//

import UserNotifications

enum AlarmScheduler {
    /// Schedule notifications at a fixed interval until totalDurationSeconds elapses.
    /// Example: interval=5, totalDurationSeconds=180 -> 36 notifications.
    static func scheduleRepeating(
        thread: String,
        startInSeconds: TimeInterval = 1,
        intervalSeconds: Int = 3,
        totalDurationSeconds: Int = 180
    ) {
        precondition(intervalSeconds >= 1, "iOS requires >= 1s trigger interval")
        let center = UNUserNotificationCenter.current()

        let count = max(1, Int(ceil(Double(totalDurationSeconds) / Double(intervalSeconds))))
        for i in 0..<count {
            let id = "\(thread)#\(i)"
            let content = UNMutableNotificationContent()
            content.title = "Snore Wake"
            content.body  = "Snore detected — wake and reposition."
            content.categoryIdentifier = NotificationCategories.alarm
            content.threadIdentifier = thread
            if #available(iOS 15.0, *) { content.interruptionLevel = .timeSensitive }
            content.sound = .default // you can ship a short, loud .caf if you want

            let t = startInSeconds + TimeInterval(i * intervalSeconds)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, t), repeats: false)
            let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(req, withCompletionHandler: nil)
        }
    }

    /// Cancel every pending request in a given thread.
    static func cancelThread(_ thread: String, completion: (() -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { reqs in
            let ids = reqs.filter { $0.content.threadIdentifier == thread }.map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: ids)
            completion?()
        }
    }
}
