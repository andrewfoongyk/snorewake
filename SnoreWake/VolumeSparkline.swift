//
//  VolumeSparkline.swift
//  SnoreWake
//
//  Created by Andrew Foong on 06/10/2025.
//

import SwiftUI

let textPri  = Color(red: 0xE5/255.0, green: 0xE1/255.0, blue: 0xDA/255.0) // #E5E1DA

/// Tufte-style sparkline that always spans a fixed time window.
/// Newest sample is pinned to the right edge; older samples slide left.
/// If fewer than capacity points exist, the left side is empty.
struct VolumeSparkline: View {
    let values: [Double]          // oldest → newest
    var minDb: Double = -70
    var maxDb: Double = -20
    var threshold: Double? = nil

    /// Must match your monitor settings
    var windowSeconds: Int = 30   // visible duration
    var samplesPerSecond: Int = 10 // 5 or 10
    
    var lineColor: Color = textPri //.accentColor
    var refColor: Color = .secondary.opacity(0.4)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Optional threshold/reference line
                if let t = threshold {
                    let y = yPos(for: t, height: geo.size.height)
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                    .stroke(refColor, style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [3,3]))
                }

                // Sparkline path, fixed-capacity x-axis
                Path { path in
                    let n = values.count
                    guard n > 1 else { return }

                    let capacity = max(2, windowSeconds * samplesPerSecond)
                    let w = geo.size.width
                    let h = geo.size.height

                    // Fixed step based on full capacity (not current count)
                    let stepX = w / CGFloat(capacity - 1)

                    // Start so the newest sample lands at the right edge
                    let startX = w - CGFloat(n - 1) * stepX

                    for i in 0..<n {
                        let x = startX + CGFloat(i) * stepX
                        let y = yPos(for: values[i], height: h)
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(lineColor, lineWidth: 1)
                .drawingGroup()
            }
        }
        .accessibilityLabel("Live volume sparkline")
    }

    private func yPos(for db: Double, height: CGFloat) -> CGFloat {
        let clamped = min(max(db, minDb), maxDb)
        let norm = (clamped - minDb) / (maxDb - minDb) // 0…1
        return height * CGFloat(1 - norm) // higher dB near top
    }
}
