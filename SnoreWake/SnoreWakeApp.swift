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
        for family in UIFont.familyNames {
            print("Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  \(name)")
            }
        }

        let center = UNUserNotificationCenter.current()
        center.delegate = NotificationDelegate.shared
        NotificationCategories.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(monitor)
                .environment(\.font, .custom("AlegreyaSans-Regular", size: 24)) // 👈 global font
                .onAppear {
                    NotificationAuthorizer.ensureAuthorization()
                }
        }
    }
}


