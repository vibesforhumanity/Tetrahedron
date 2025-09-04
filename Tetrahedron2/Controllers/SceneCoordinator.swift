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
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private var hapticEngine: CHHapticEngine?
    private var hapticTimer: Timer?
    private var lastSpeed: CGFloat = 0
    
    override init() {
        super.init()
        setupDisplayLink()
        setupHaptics()
        impactFeedback.prepare()
        selectionFeedback.prepare()
    }
    
    deinit {
        displayLink?.invalidate()
        hapticTimer?.invalidate()
        hapticEngine?.stop()
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateRotation))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Failed to create haptic engine: \(error)")
        }
    }
    
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
        updateHapticFeedback(for: speed)
        
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
            if config?.isHapticsEnabled == true {
                selectionFeedback.selectionChanged()
            }
            
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
            
            let maxMomentum: CGFloat = 4000
            addedVelocity.dx = max(-maxMomentum, min(maxMomentum, addedVelocity.dx))
            addedVelocity.dy = max(-maxMomentum, min(maxMomentum, addedVelocity.dy))
            
        default:
            break
        }
    }
    
    private func updateHapticFeedback(for speed: CGFloat) {
        // Check if haptics are enabled
        guard config?.isHapticsEnabled == true else {
            hapticTimer?.invalidate()
            hapticTimer = nil
            lastSpeed = 0
            return
        }
        
        // Only trigger haptics when there's meaningful rotation (not just base rotation)
        let addedSpeed = sqrt(pow(addedVelocity.dx, 2) + pow(addedVelocity.dy, 2))
        
        if addedSpeed < 50 { // No haptics for gentle base rotation
            hapticTimer?.invalidate()
            hapticTimer = nil
            lastSpeed = 0
            return
        }
        
        // Calculate haptic frequency based on actual spin velocity (like Fidgetable)
        let maxFrequency: TimeInterval = 0.05  // 20 haptics per second at max speed
        let minFrequency: TimeInterval = 0.2   // 5 haptics per second at min speed
        let speedNormalized = min(1.0, max(0.0, addedSpeed / 3000))
        let hapticInterval = minFrequency - (speedNormalized * (minFrequency - maxFrequency))
        
        // Update timer when speed changes or no timer exists
        if hapticTimer == nil || abs(addedSpeed - lastSpeed) > 100 {
            hapticTimer?.invalidate()
            
            if addedSpeed > 50 { // Only start timer if there's meaningful spin
                hapticTimer = Timer.scheduledTimer(withTimeInterval: hapticInterval, repeats: true) { [weak self] _ in
                    // Check current speed each time to scale intensity
                    let currentAddedSpeed = sqrt(pow(self?.addedVelocity.dx ?? 0, 2) + pow(self?.addedVelocity.dy ?? 0, 2))
                    let currentIntensity = min(1.0, max(0.0, currentAddedSpeed / 3000))
                    self?.triggerSpinHaptic(intensity: currentIntensity)
                }
            }
            
            lastSpeed = addedSpeed
        }
    }
    
    private func triggerSpinHaptic(intensity: CGFloat) {
        // Use Core Haptics for more pronounced feedback like Fidgetable
        guard let hapticEngine = hapticEngine else {
            // Fallback to UIKit haptics
            if intensity > 0.7 {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            } else if intensity > 0.4 {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } else {
                impactFeedback.impactOccurred()
            }
            return
        }
        
        do {
            // Create a sharp, pronounced haptic like Fidgetable's spinning toys
            let sharpness = Float(0.8 + intensity * 0.2) // 0.8 to 1.0
            let intensityValue = Float(0.6 + intensity * 0.4) // 0.6 to 1.0
            
            let hapticEvent = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensityValue)
                ],
                relativeTime: 0
            )
            
            let pattern = try CHHapticPattern(events: [hapticEvent], parameters: [])
            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            
        } catch {
            // Fallback to UIKit haptics
            impactFeedback.impactOccurred()
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