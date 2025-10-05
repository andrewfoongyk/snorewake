//
//  SnoreWakeApp.swift
//  SnoreWake
//
//  Created by Andrew Foong on 05/10/2025.
//

import SwiftUI
import UserNotifications

@main
struct SnoreWakeApp: App {
    @StateObject private var monitor = AudioSnoreMonitor()

    init() {
        let center = UNUserNotificationCenter.current()
        center.delegate = NotificationDelegate.shared
        NotificationCategories.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(monitor)
                .onAppear {
                    NotificationAuthorizer.ensureAuthorization()
                }
        }
    }
}


