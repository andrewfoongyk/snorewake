//
//  AudioSnoreMonitor.swift
//  SnoreWake
//
//  Created by Andrew Foong on 05/10/2025.
//

import Foundation
import AVFoundation
import UserNotifications
import Accelerate
import Combine

final class AudioSnoreMonitor: NSObject, ObservableObject {
    private let engine = AVAudioEngine()
    private let session = AVAudioSession.sharedInstance()

    // Rolling window of last 2 samples (1 per second)
    private var recentDb: [Float] = []
    private let windowSeconds = 2
    private var sampleRate: Double = 48000

    // UI-published state
    @Published var avgDb: Float = -80
    @Published var cooldownRemaining: Int = 0

    // Config
    var thresholdDb: Float = -35.0

    // Cooldown tracking
    private var cooldownUntil: Date?
    private var tickerCancellable: AnyCancellable?

    private var isRunning = false
    private var accumSamples: [Float] = []
    
    // Snore burst detection state
    private var burstActive = false
    private var burstStart: Date?
    private var lastBurstEnd: Date?
    private var burstTimestamps: [Date] = []   // recent valid bursts within 30 s

    // Tunables
    private let minBurstSec: TimeInterval = 0.7
    private let maxBurstSec: TimeInterval = 3.0
    private let minQuietSec: TimeInterval = 1.0
    private let burstsToTrigger = 3

    func start() throws {
        guard !isRunning else { return }

        try session.setCategory(.playAndRecord,
                                mode: .measurement,
                                options: [.allowBluetooth, .allowBluetoothA2DP, .mixWithOthers])
        try session.setActive(true, options: [])

        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)
        sampleRate = format.sampleRate

        input.removeTap(onBus: 0)
        let framesPerBuffer: AVAudioFrameCount = AVAudioFrameCount(sampleRate / 2) // ~0.5 s

        input.installTap(onBus: 0, bufferSize: framesPerBuffer, format: format) { [weak self] buffer, _ in
            self?.process(buffer: buffer)
        }

        engine.prepare()
        try engine.start()
        isRunning = true

        startTicker()
    }

    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? session.setActive(false)
        isRunning = false
        stopTicker()
    }

    private func process(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        accumSamples.append(contentsOf: UnsafeBufferPointer(start: channelData, count: frameCount))

        let framesPerSecond = Int(sampleRate)
        if accumSamples.count >= framesPerSecond {
            let oneSecond = Array(accumSamples.prefix(framesPerSecond))
            accumSamples.removeFirst(framesPerSecond)

            var rms: Float = 0
            vDSP_rmsqv(oneSecond, 1, &rms, vDSP_Length(oneSecond.count))
            let db = 20.0 * log10f(max(rms, 1e-7))

            DispatchQueue.main.async {
                // Show live level in your UI if you want
                self.avgDb = db
                // Use burst heuristic instead of 30 s rolling average
                self.stepSnoreHeuristic(db: db)
            }
        }
    }

    private func stepSnoreHeuristic(db: Float) {
        let now = Date()

        if burstActive {
            if let s = burstStart, now.timeIntervalSince(s) > maxBurstSec {
                // Too long above threshold, treat as steady noise and reset
                burstActive = false
                burstStart = nil
                lastBurstEnd = now
                return
            }
            if db < thresholdDb {
                if let s = burstStart {
                    let dur = now.timeIntervalSince(s)
                    if dur >= minBurstSec {
                        burstTimestamps.append(now)
                        // keep only last 30 s
                        burstTimestamps = burstTimestamps.filter { now.timeIntervalSince($0) <= 30 }

                        if burstTimestamps.count >= burstsToTrigger {
                            startPersistentAlarm()       // your 5 s cadence alarm
                            startCooldown(seconds: 60)   // or 300 if you prefer
                            burstTimestamps.removeAll()
                        }
                    }
                }
                burstActive = false
                burstStart = nil
                lastBurstEnd = now
            }
        } else {
            let quietOk: Bool = {
                guard let q = lastBurstEnd else { return true }
                return now.timeIntervalSince(q) >= minQuietSec
            }()
            if db >= thresholdDb && quietOk {
                burstActive = true
                burstStart = now
            }
        }
    }
    
    // MARK: - Alerts
    func fireSingleAlert() {
        let content = UNMutableNotificationContent()
        content.title = "Snore Wake"
        content.body  = "Test alert."
        if #available(iOS 15.0, *) { content.interruptionLevel = .timeSensitive }
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }

    // Schedules one notification per 3 seconds for 3 minutes.
    // Use a constant thread so STOP can cancel them all.
    func startPersistentAlarm() {
        let thread = "snore_alarm"
        AlarmScheduler.scheduleRepeating(thread: thread,
                                         startInSeconds: 1,
                                         intervalSeconds: 3,
                                         totalDurationSeconds: 180) // 3 minutes
    }


    func startCooldown(seconds: Int) {
        cooldownUntil = Date().addingTimeInterval(TimeInterval(seconds))
        updateCooldownRemaining()
    }

    private func startTicker() {
        stopTicker()
        tickerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCooldownRemaining()
            }
    }

    private func stopTicker() {
        tickerCancellable?.cancel()
        tickerCancellable = nil
        cooldownRemaining = 0
    }

    private func updateCooldownRemaining() {
        if let until = cooldownUntil {
            let r = max(0, Int(ceil(until.timeIntervalSinceNow)))
            cooldownRemaining = r
            if r == 0 { cooldownUntil = nil }
        } else {
            cooldownRemaining = 0
        }
    }
}

enum NotificationAuthorizer {
    static func ensureAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { _, _ in
            // criticalAlert is ignored without entitlement. Harmless to request.
        }
    }
}
