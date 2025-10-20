//
//  TiltableCardModifier.swift
//  CARDinal
//
//  View modifier that applies gyroscope-based tilt animation to cards.
//
//  Created by AI Assistant on 10/20/25.
//

import SwiftUI

struct TiltableCardModifier: ViewModifier {
    @StateObject private var motionManager = MotionManager()

    // Sensitivity multipliers for the tilt effect
    private let tiltSensitivity: Double = 15.0
    private let maxTiltAngle: Double = 10.0

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(calculateTiltX()),
                axis: (x: 1, y: 0, z: 0)
            )
            .rotation3DEffect(
                .degrees(calculateTiltY()),
                axis: (x: 0, y: 1, z: 0)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: motionManager.roll)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: motionManager.pitch)
    }

    private func calculateTiltX() -> Double {
        // Convert pitch (forward/backward tilt) to rotation angle
        let angle = -motionManager.pitch * tiltSensitivity
        return min(max(angle, -maxTiltAngle), maxTiltAngle)
    }

    private func calculateTiltY() -> Double {
        // Convert roll (left/right tilt) to rotation angle
        let angle = motionManager.roll * tiltSensitivity
        return min(max(angle, -maxTiltAngle), maxTiltAngle)
    }
}

extension View {
    func tiltable() -> some View {
        self.modifier(TiltableCardModifier())
    }
}
