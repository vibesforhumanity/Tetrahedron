import UIKit
import SceneKit

class SceneCoordinator: NSObject {
    weak var scnView: SCNView?
    weak var shapeContainer: SCNNode?
    
    private var lastPanLocation: CGPoint = .zero
    private var currentVelocity: CGVector = .zero
    private var baseRotationSpeed: CGVector = CGVector(dx: 30, dy: 20)
    private var addedVelocity: CGVector = .zero
    private var displayLink: CADisplayLink?
    
    override init() {
        super.init()
        setupDisplayLink()
    }
    
    deinit {
        displayLink?.invalidate()
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateRotation))
        displayLink?.add(to: .main, forMode: .common)
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
        
        addedVelocity.dx *= 0.985
        addedVelocity.dy *= 0.985
        
        if abs(addedVelocity.dx) < 0.1 && abs(addedVelocity.dy) < 0.1 {
            addedVelocity = .zero
        }
        
        let speed = sqrt(pow(totalVelocityX, 2) + pow(totalVelocityY, 2))
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