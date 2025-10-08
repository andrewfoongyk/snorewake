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

    // --- Japandi-inspired palette ---
    private let bg       = Color(red: 0x1B/255.0, green: 0x1B/255.0, blue: 0x1A/255.0) // #1B1B1A
    private let surface  = Color(red: 0x2A/255.0, green: 0x2A/255.0, blue: 0x28/255.0) // #2A2A28
    private let textPri  = Color(red: 0xE5/255.0, green: 0xE1/255.0, blue: 0xDA/255.0) // #E5E1DA
    private let textSec  = Color(red: 0xA8/255.0, green: 0xA3/255.0, blue: 0x98/255.0) // #A8A398
    private let accent1  = Color(red: 0xC1/255.0, green: 0x6C/255.0, blue: 0x5B/255.0) // #C16C5B terracotta
    private let accent2  = Color(red: 0x5E/255.0, green: 0x72/255.0, blue: 0x60/255.0) // #5E7260 sage
    private let accent3  = Color(red: 0xD9/255.0, green: 0xA4/255.0, blue: 0x41/255.0) // #D9A441 ochre
    
    func formatDbEnDash(_ v: Double) -> String {
        let s = String(format: "%.1f", v)
        // replace only a leading '-' with an en-dash
        return s.replacingOccurrences(of: "^-", with: "–", options: .regularExpression)
    }
    
    func formatIntWithTrueMinus(_ v: Int) -> String {
        String(v).replacingOccurrences(of: "^-", with: "−", options: .regularExpression)
        // swap "−" for "–" if you insist on en-dash
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("snorewake")
                .font(.custom("AlegreyaSansSC-Regular", size: 40))
                .tracking(6)
                .foregroundStyle(textPri)

            // --- Live sparkline (Tufte style) ---
            VolumeSparkline(
                values: monitor.recentDbHistory,
                minDb: -70, maxDb: -20,
                threshold: Double(thresholdDb),
                windowSeconds: 30,
                samplesPerSecond: 10   // or 5
            )
            .frame(height: 80)
            .padding(.vertical, 4)
            .tint(accent2) // not strictly needed; our view uses lineColor parameter
            // use our palette explicitly:
            .environment(\.colorScheme, .dark) // keep dark vibe
            // Color the line and reference with our palette via .foregroundStyle if desired:
            .foregroundStyle(accent2)

            Group {
                HStack(spacing: 0) {
                    Text("\(formatDbEnDash(Double(monitor.avgDb))) d")
                        .monospacedDigit()

                    Text("bfs")
                        .font(.custom("AlegreyaSansSC-Regular", size: 24)) // match your body size
                        .foregroundStyle(textPri)
                }
                if monitor.cooldownRemaining > 0 {
                    Text("Cooldown: \(monitor.cooldownRemaining)s")
                        .foregroundStyle(textSec)
                        .monospacedDigit()
                }
            }

            HStack {
                Text("Sensitivity")
                    .foregroundStyle(textPri)
                Slider(value: $thresholdDb, in: -70 ... -20, step: 1)
                    .onChange(of: thresholdDb) { newVal in
                        monitor.thresholdDb = Float(newVal)
                        thresholdDbStored = newVal
                    }
                    .tint(accent2)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(formatIntWithTrueMinus(Int(thresholdDb)))
                        .monospacedDigit()
                        .foregroundStyle(textPri)
                        .lineLimit(1)
                        .fixedSize()

                    Text(" d")
                        .foregroundStyle(textPri)
                        .lineLimit(1)
                        .fixedSize()

                    Text("b")
                        .font(.custom("AlegreyaSansSC-Regular", size: 24)) // small-caps, same size
                        .foregroundStyle(textPri)
                        .lineLimit(1)
                        .fixedSize()
                }
                .frame(width: 60, alignment: .trailing)
            }

            Toggle(isOn: $armed) {
                HStack(spacing: 0) {
                    Text("Monitoring ")
                        .foregroundStyle(textPri)

                    Text(armed ? "on" : "off")
                        .font(.custom("AlegreyaSansSC-Regular", size: 24)) // adjust size to match your body text
                        .foregroundStyle(textPri)
                }
            }
            .onChange(of: armed) { on in
                if on { try? monitor.start() } else { monitor.stop() }
            }
            .tint(accent2)

            HStack(spacing: 12) {

                Button("test alarm") { monitor.startPersistentAlarm() }
                    .buttonStyle(.bordered)
                    .tint(accent1)
                    .font(.custom("AlegreyaSansSC-Regular", size: 20))
                    .tracking(3)

                .buttonStyle(.bordered)
                .tint(accent2)
                .font(.custom("AlegreyaSansSC-Regular", size: 20))
                .tracking(3)
            }

            Text("Grant microphone and notifications. Keep iPhone on power overnight. Watch app → Notifications → mirror this app.")
                .foregroundStyle(textSec)
                .font(.custom("AlegreyaSans-Regular", size: 16))
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .italic()

            Spacer()
        }
        .padding(20)
        .background(bg.ignoresSafeArea())
        .onAppear {
            thresholdDb = thresholdDbStored
            monitor.thresholdDb = Float(thresholdDbStored)
        }
    }
}
