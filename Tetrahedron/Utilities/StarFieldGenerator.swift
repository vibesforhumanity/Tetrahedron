import SceneKit
import UIKit

struct StarFieldGenerator {
    
    static func addStarField(to rootNode: SCNNode) {
        for i in 0..<3 {
            let particleSystem = SCNParticleSystem()
            particleSystem.birthRate = 50 + CGFloat(i * 30)
            particleSystem.particleLifeSpan = 10
            particleSystem.particleLifeSpanVariation = 2
            
            particleSystem.particleSize = CGFloat(0.02 - Float(i) * 0.005)
            particleSystem.particleSizeVariation = 0.01
            
            particleSystem.particleColor = UIColor.white.withAlphaComponent(0.8)
            particleSystem.particleColorVariation = SCNVector4(0, 0, 0, 0.2)
            particleSystem.blendMode = .alpha // Use alpha blending instead of default
            
            particleSystem.emitterShape = SCNSphere(radius: 10)
            particleSystem.birthLocation = .surface
            particleSystem.birthDirection = .surfaceNormal
            
            particleSystem.particleVelocity = CGFloat(0.5 + Float(i) * 0.3)
            particleSystem.particleVelocityVariation = 0.2
            particleSystem.acceleration = SCNVector3(0, 0, 2)
            
            let twinkleAnimation = CAKeyframeAnimation(keyPath: "opacity")
            twinkleAnimation.values = [1.0, 0.3, 1.0]
            twinkleAnimation.keyTimes = [0, 0.5, 1]
            twinkleAnimation.duration = 3
            twinkleAnimation.repeatCount = .infinity
            
            let controller = SCNParticlePropertyController(animation: twinkleAnimation)
            particleSystem.propertyControllers = [.opacity: controller]
            
            let particleNode = SCNNode()
            particleNode.name = "starField\(i)"
            particleNode.addParticleSystem(particleSystem)
            rootNode.addChildNode(particleNode)
        }
    }
}