import UIKit
import SceneKit
import CoreHaptics

class SceneCoordinator: NSObject {
    weak var scnView: SCNView?
    weak var shapeContainer: SCNNode?
    weak var config: AppConfiguration?

    private var lastPanLocation: CGPoint = .zero
    private var currentVelocity: CGVector = .zero
    private var baseRotationSpeed: CGVector = CGVector(dx: 30, dy: 20)
    private var addedVelocity: CGVector = .zero
    private var displayLink: CADisplayLink?

    // Haptic feedback properties
    private var hapticEngine: CHHapticEngine?
    private var continuousPlayer: CHHapticAdvancedPatternPlayer?
    private var isHapticPlaying = false
    private var isUserTouching = false
    private var currentRotationSpeed: CGFloat = 0.0
    
    init(config: AppConfiguration) {
        self.config = config
        super.init()
        setupDisplayLink()
        setupHapticFeedback()
    }
    
    deinit {
        displayLink?.invalidate()
        stopContinuousHaptic()
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateRotation))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func setupHapticFeedback() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()

            hapticEngine?.stoppedHandler = { reason in
                print("Haptic Engine Stopped: \(reason)")
            }

            hapticEngine?.resetHandler = {
                print("Haptic Engine Reset")
                do {
                    try self.hapticEngine?.start()
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }
        } catch {
            print("Failed to initialize haptic engine: \(error)")
        }
    }


    private func startContinuousHaptic() {
        guard let config = config else { return }

        // Always ensure clean state before starting
        forceStopAllHaptics()

        // Restart engine if needed
        if hapticEngine == nil {
            setupHapticFeedback()
        }
        guard let hapticEngine = hapticEngine else { return }

        do {
            // Ensure engine is started
            try hapticEngine.start()

            // Create a pulsed pattern based on config frequency
            var events: [CHHapticEvent] = []
            let pulseInterval: Double = 1.0 / Double(config.hapticFrequency) // Convert Hz to interval
            let totalDuration: Double = max(1.0, Double(config.hapticDuration) / 1000.0) // Use config duration or minimum 1 second
            let numberOfPulses = max(1, Int(totalDuration / pulseInterval)) // Ensure at least 1 pulse

            for i in 0..<numberOfPulses {
                let startTime = Double(i) * pulseInterval

                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: config.hapticIntensity)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: config.hapticSharpness)

                let pulseEvent = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: startTime
                )

                events.append(pulseEvent)
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            continuousPlayer = try hapticEngine.makeAdvancedPlayer(with: pattern)

            try continuousPlayer?.start(atTime: CHHapticTimeImmediate)
            isHapticPlaying = true

        } catch {
            print("Failed to start continuous haptic: \(error)")
            // Try to recover by resetting the engine
            resetHapticEngine()
        }
    }


    private func stopContinuousHaptic() {
        guard isHapticPlaying else { return }

        do {
            try continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to stop continuous haptic gracefully: \(error)")
        }

        continuousPlayer = nil
        isHapticPlaying = false
    }

    private func forceStopAllHaptics() {
        // Force stop any playing haptics
        if let player = continuousPlayer {
            do {
                try player.stop(atTime: CHHapticTimeImmediate)
            } catch {
                // Ignore errors during force stop
            }
        }

        continuousPlayer = nil
        isHapticPlaying = false
    }

    private func resetHapticEngine() {
        print("Resetting haptic engine due to error")

        // Clean up everything
        forceStopAllHaptics()

        // Stop and release the current engine
        hapticEngine?.stop { error in
            if let error = error {
                print("Error stopping haptic engine: \(error)")
            }
        }
        hapticEngine = nil

        // Recreate the engine
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setupHapticFeedback()
        }
    }

    // MARK: - Velocity-Based Haptic Methods

    private func updateHapticForVelocity(_ velocity: CGFloat) {
        guard let config = config else { return }

        // Only start haptics if there's significant velocity AND user is actively spinning
        let significantVelocity = velocity > 30.0

        if significantVelocity && !isHapticPlaying {
            // Start continuous haptics with base frequency - no restarts
            startContinuousHaptic()
        } else if !significantVelocity && isHapticPlaying {
            // Stop haptics when velocity drops too low
            stopContinuousHaptic()
        }

        // No frequency updates or restarts - keep it simple and continuous
    }

    // Simplified - no complex frequency updates or restarts needed
    
    @objc private func updateRotation() {
        guard let shapeContainer = shapeContainer else { return }
        
        let totalVelocityX = baseRotationSpeed.dx + addedVelocity.dx
        let totalVelocityY = baseRotationSpeed.dy + addedVelocity.dy
        
        let rotationX = Float(totalVelocityY) * 0.0001
        let rotationY = Float(totalVelocityX) * 0.0001
        
        let currentTransform = shapeContainer.transform
        let rotationMatrix = SCNMatrix4MakeRotation(rotationX, 1, 0, 0)
        let rotationMatrix2 = SCNMatrix4MakeRotation(rotationY, 0, 1, 0)
        
        shapeContainer.transform = SCNMatrix4Mult(SCNMatrix4Mult(currentTransform, rotationMatrix), rotationMatrix2)
        
        let speed = sqrt(pow(totalVelocityX, 2) + pow(totalVelocityY, 2))

        // For haptics, only use the user-added velocity, not base rotation
        let userAddedSpeed = sqrt(pow(addedVelocity.dx, 2) + pow(addedVelocity.dy, 2))

        // Update haptic feedback based on USER velocity only
        currentRotationSpeed = speed  // Keep this for star field effects
        updateHapticForVelocity(userAddedSpeed)  // Use user speed for haptics

        addedVelocity.dx *= 0.985
        addedVelocity.dy *= 0.985

        if abs(addedVelocity.dx) < 0.1 && abs(addedVelocity.dy) < 0.1 {
            addedVelocity = .zero
        }

        updateStarFieldVelocity(speed: speed)
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let scnView = scnView else { return }
        
        let location = gesture.location(in: scnView)
        let velocity = gesture.velocity(in: scnView)
        
        switch gesture.state {
        case .began:
            lastPanLocation = location
            currentVelocity = .zero
            isUserTouching = true
            // Don't start haptics until user actually moves
            
        case .changed:
            let deltaX = location.x - lastPanLocation.x
            let deltaY = location.y - lastPanLocation.y
            
            currentVelocity = CGVector(dx: velocity.x, dy: velocity.y)
            
            addedVelocity.dx += deltaX * 3
            addedVelocity.dy += deltaY * 3
            
            let maxAddedVelocity: CGFloat = 3000
            addedVelocity.dx = max(-maxAddedVelocity, min(maxAddedVelocity, addedVelocity.dx))
            addedVelocity.dy = max(-maxAddedVelocity, min(maxAddedVelocity, addedVelocity.dy))
            
            lastPanLocation = location
            
        case .ended, .cancelled:
            let boostFactor: CGFloat = 1.5
            addedVelocity.dx += currentVelocity.dx * boostFactor
            addedVelocity.dy += currentVelocity.dy * boostFactor
            isUserTouching = false
            // Don't stop haptics here - let the velocity updates handle it
            
            let maxMomentum: CGFloat = 4000
            addedVelocity.dx = max(-maxMomentum, min(maxMomentum, addedVelocity.dx))
            addedVelocity.dy = max(-maxMomentum, min(maxMomentum, addedVelocity.dy))
            
        default:
            break
        }
    }
    
    private func updateStarFieldVelocity(speed: CGFloat) {
        guard let rootNode = scnView?.scene?.rootNode else { return }
        
        let baseSpeed: CGFloat = 36
        let speedMultiplier = speed / baseSpeed
        
        for i in 0..<3 {
            if let particleNode = rootNode.childNode(withName: "starField\(i)", recursively: false),
               let particleSystem = particleNode.particleSystems?.first {
                
                let baseVelocity = CGFloat(0.5 + Float(i) * 0.3)
                let baseBirthRate = 50 + CGFloat(i * 30)
                
                let effectiveMultiplier = max(1, speedMultiplier)
                
                particleSystem.particleVelocity = baseVelocity * effectiveMultiplier
                particleSystem.birthRate = baseBirthRate * (1 + (effectiveMultiplier - 1) * 0.3)
                
                let accel = 2 + Float(effectiveMultiplier - 1) * 1.5
                particleSystem.acceleration = SCNVector3(0, 0, accel)
            }
        }
    }
}