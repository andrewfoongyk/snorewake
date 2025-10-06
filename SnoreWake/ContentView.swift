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
            Text("snorewake")
                .font(.custom("AlegreyaSansSC-Regular", size: 32))
                .tracking(4)

            Divider()


            Group {
                Text("Volume: \(String(format: "%.1f", Double(monitor.avgDb))) dBFS")
                    .monospacedDigit()
                    .italic()
                if monitor.cooldownRemaining > 0 {
                    Text("Cooldown: \(monitor.cooldownRemaining)s")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            HStack {
                Text("Sensitivity")
                // Now the Slider binding is native Double → no custom Binding needed
                Slider(value: $thresholdDb, in: -70 ... -20, step: 1)
                    .onChange(of: thresholdDb) { newVal in
                        monitor.thresholdDb = Float(newVal)
                        thresholdDbStored = newVal
                    }
                Text("\(Int(thresholdDb)) dB")
                    .monospacedDigit()
                    .frame(width: 60, alignment: .trailing)
            }

            Toggle(isOn: $armed) {
                Text(armed ? "Monitoring ON" : "Monitoring OFF")
            }
            .onChange(of: armed) { on in
                if on { try? monitor.start() } else { monitor.stop() }
            }

            HStack(spacing: 12) {
                Button("alert") { monitor.fireSingleAlert() }
                    .buttonStyle(.bordered)
                    .font(.custom("AlegreyaSansSC-Regular", size: 20))
                    .tracking(3)

                Button("alarm") { monitor.startPersistentAlarm() }
                    .buttonStyle(.bordered)
                    .font(.custom("AlegreyaSansSC-Regular", size: 20))
                    .tracking(3)

                Button(monitor.cooldownRemaining > 0 ? "reset cooldown" : "cooldown") {
                    monitor.startCooldown(seconds: 60)
                }
                .buttonStyle(.bordered)
                .font(.custom("AlegreyaSansSC-Regular", size: 20))
                .tracking(3)

            }

            Divider()

            Text("Grant microphone and notifications. Keep iPhone on power overnight. Watch app → Notifications → mirror this app.")
                .foregroundStyle(.secondary)
                .font(.custom("AlegreyaSans-Regular", size: 16))
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .italic()

            Spacer()
        }
        .padding(20)
        .onAppear {
            thresholdDb = thresholdDbStored
            monitor.thresholdDb = Float(thresholdDbStored)
        }
    }
}
