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
    private var hasUserInteracted = false
    private var currentRotationSpeed: CGFloat = 0.0
    private var hapticTimer: Timer?
    private var lastHapticUpdate: Date = Date()
    
    init(config: AppConfiguration) {
        self.config = config
        super.init()
        setupDisplayLink()
        setupHapticFeedback()
    }
    
    deinit {
        displayLink?.invalidate()
        stopContinuousHaptic()
        hapticTimer?.invalidate()
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
        guard config != nil else { return }
        guard !isHapticPlaying else { return }

        // Restart engine if needed
        if hapticEngine == nil {
            setupHapticFeedback()
        }
        guard let hapticEngine = hapticEngine else { return }

        do {
            // Ensure engine is started
            try hapticEngine.start()
            isHapticPlaying = true

            // Start the continuous haptic loop
            playHapticPulse()

        } catch {
            print("Failed to start continuous haptic: \(error)")
            resetHapticEngine()
        }
    }

    private func playHapticPulse() {
        guard isHapticPlaying, let config = config else { return }

        // Calculate frequency based on rotation speed
        // Map rotation speed (30-300+) to frequency multiplier (0.5x - 2.5x)
        // Use a slower scaling curve for more gradual changes
        let normalizedSpeed = (currentRotationSpeed - 30.0) / 270.0 // 0.0 at base speed, 1.0 at high speed
        let speedFactor = 0.5 + (min(max(normalizedSpeed, 0.0), 1.0) * 2.0) // 0.5x to 2.5x
        let dynamicFrequency = Float(config.hapticFrequency) * Float(speedFactor)
        let pulseInterval = 1.0 / Double(dynamicFrequency)

        do {
            // Create a single pulse
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: config.hapticIntensity)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: config.hapticSharpness)

            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: 0
            )

            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)

            // Schedule next pulse
            DispatchQueue.main.asyncAfter(deadline: .now() + pulseInterval) { [weak self] in
                self?.playHapticPulse()
            }

        } catch {
            print("Failed to play haptic pulse: \(error)")
        }
    }


    private func stopContinuousHaptic() {
        isHapticPlaying = false
        continuousPlayer = nil
    }

    private func forceStopAllHaptics() {
        isHapticPlaying = false
        continuousPlayer = nil
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
        guard let config = config, config.isHapticsEnabled else {
            // If haptics are disabled, stop any playing haptics
            if isHapticPlaying {
                stopContinuousHaptic()
            }
            return
        }

        // Calculate velocity without base rotation to determine if user has added significant movement
        let userAddedSpeed = sqrt(pow(addedVelocity.dx, 2) + pow(addedVelocity.dy, 2))
        let baseRotationSpeed = sqrt(pow(30.0, 2) + pow(20.0, 2)) // ≈ 36
        let significantlyAboveBase = velocity > (baseRotationSpeed + 5.0) // ~41, buffer above base rotation

        // Only start haptics if user has interacted AND velocity is significantly above base rotation
        if significantlyAboveBase && !isHapticPlaying && hasUserInteracted {
            startContinuousHaptic()
        }
        // Stop haptics when velocity returns close to base rotation speed
        else if !significantlyAboveBase && isHapticPlaying {
            stopContinuousHaptic()
        }

        // Reset interaction flag when velocity returns to near base rotation and user input stops
        if velocity <= (baseRotationSpeed + 2.0) && userAddedSpeed < 5.0 {
            hasUserInteracted = false
        }
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

        // Update haptic feedback based on total rotation velocity (for physics decay)
        // But only allow haptics to start if user is actively touching
        currentRotationSpeed = speed
        updateHapticForVelocity(speed)

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
            // Mark that user has started interacting
            
        case .changed:
            let deltaX = location.x - lastPanLocation.x
            let deltaY = location.y - lastPanLocation.y

            // User is actively moving - mark interaction
            hasUserInteracted = true
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