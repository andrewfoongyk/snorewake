//
//  ContentView.swift
//  SnoreWake
//
//  Created by Andrew Foong on 05/10/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var monitor: AudioSnoreMonitor

    // Use Double here (AppStorage supports Bool/Int/Double/String/Data/URL)
    @AppStorage("snore_threshold_db") private var thresholdDbStored: Double = -35.0

    @State private var armed = false
    @State private var thresholdDb: Double = -35.0

    var body: some View {
        VStack(spacing: 16) {
            Text("SnoreWake")
              .font(.system(.title2, design: .serif))


            Group {
                Text("15s average: \(String(format: "%.1f", Double(monitor.avgDb))) dBFS")
                    .monospacedDigit()
                    .font(.system(.body))
                if monitor.cooldownRemaining > 0 {
                    Text("Cooldown: \(monitor.cooldownRemaining)s")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            HStack {
                Text("Sensitivity")
                // Now the Slider binding is native Double → no custom Binding needed
                Slider(value: $thresholdDb, in: -60 ... -20, step: 1)
                    .onChange(of: thresholdDb) { newVal in
                        monitor.thresholdDb = Float(newVal)
                        thresholdDbStored = newVal
                    }
                Text("\(Int(thresholdDb)) dB")
                    .monospacedDigit()
                    .font(.system(.body))
                    .frame(width: 60, alignment: .trailing)
            }

            Toggle(isOn: $armed) {
                Text(armed ? "Monitoring ON" : "Monitoring OFF")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .onChange(of: armed) { on in
                if on { try? monitor.start() } else { monitor.stop() }
            }

            HStack(spacing: 12) {
                Button("Test alert (single)") { monitor.fireSingleAlert() }
                    .buttonStyle(.bordered)

                Button("Test persistent alert") { monitor.startPersistentAlarm() }
                    .buttonStyle(.bordered)

                Button(monitor.cooldownRemaining > 0 ? "Reset cooldown" : "Start cooldown") {
                    monitor.startCooldown(seconds: 60)
                }
                .buttonStyle(.bordered)
            }


            Text("Grant microphone and notifications. Keep iPhone on power overnight. Watch app → Notifications → mirror this app.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Spacer()
        }
        .padding(20)
        .onAppear {
            thresholdDb = thresholdDbStored
            monitor.thresholdDb = Float(thresholdDbStored)
        }
    }
}
