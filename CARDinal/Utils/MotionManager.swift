//
//  MotionManager.swift
//  CARDinal
//
//  Manager for handling device motion and gyroscope data.
//
//  Created by AI Assistant on 10/20/25.
//

import Foundation
import CoreMotion
import Combine

@MainActor
class MotionManager: ObservableObject {
    nonisolated(unsafe) private let motionManager = CMMotionManager()

    @Published var roll: Double = 0.0
    @Published var pitch: Double = 0.0

    init() {
        startMotionUpdates()
    }

    func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available")
            return
        }

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 Hz
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion, error == nil else { return }

            Task { @MainActor in
                // Get attitude (device orientation)
                // Roll is rotation around the z-axis (tilting left/right)
                // Pitch is rotation around the x-axis (tilting forward/backward)
                self?.roll = motion.attitude.roll
                self?.pitch = motion.attitude.pitch
            }
        }
    }

    nonisolated func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }

    deinit {
        stopMotionUpdates()
    }
}
