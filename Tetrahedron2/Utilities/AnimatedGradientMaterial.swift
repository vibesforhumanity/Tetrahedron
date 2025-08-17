import SceneKit
import UIKit
import Foundation

class AnimatedGradientMaterial {
    
    static func createAnimatedGradientMaterial(for index: Int) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Very simple, visible material
        let tealColor = UIColor.cyan
        material.diffuse.contents = tealColor
        material.emission.contents = tealColor
        material.emission.intensity = 1.0
        
        // Use basic material properties
        material.lightingModel = .constant
        material.isDoubleSided = true
        
        return material
    }
    
    static func createMovingGradientTexture() -> UIImage {
        let size = CGSize(width: 400, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Create a gradient from dark teal -> bright cyan -> white -> bright cyan -> dark teal
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor(red: 0, green: 0.3, blue: 0.4, alpha: 1).cgColor,  // dark teal
                UIColor(red: 0, green: 0.8, blue: 1, alpha: 1).cgColor,    // bright cyan
                UIColor(red: 0.5, green: 1, blue: 1, alpha: 1).cgColor,    // bright white-cyan
                UIColor(red: 0, green: 0.8, blue: 1, alpha: 1).cgColor,    // bright cyan
                UIColor(red: 0, green: 0.3, blue: 0.4, alpha: 1).cgColor   // dark teal
            ]
            let locations: [CGFloat] = [0.0, 0.25, 0.5, 0.75, 1.0]
            
            guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) else {
                return
            }
            
            // Draw horizontal gradient
            cgContext.drawLinearGradient(gradient,
                                       start: CGPoint(x: 0, y: size.height/2),
                                       end: CGPoint(x: size.width, y: size.height/2),
                                       options: [])
        }
    }
    
    static func getColorComponents(for index: Int) -> (SCNVector3, SCNVector3, SCNVector3) {
        let colorSets: [(SCNVector3, SCNVector3, SCNVector3)] = [
            // Cyan to Purple to Pink
            (SCNVector3(0, 1, 1), SCNVector3(0.8, 0.4, 1), SCNVector3(1, 0.2, 0.8)),
            // Orange to Pink to Red
            (SCNVector3(1, 0.5, 0), SCNVector3(1, 0.3, 0.6), SCNVector3(1, 0, 0.4)),
            // Green to Teal to Blue
            (SCNVector3(0, 1, 0.5), SCNVector3(0.2, 1, 0.8), SCNVector3(0.2, 0.6, 1)),
            // Purple to Magenta to Red
            (SCNVector3(0.6, 0.2, 1), SCNVector3(0.8, 0.2, 0.8), SCNVector3(1, 0.2, 0.4)),
            // Teal to Yellow to Orange
            (SCNVector3(0.2, 0.8, 0.8), SCNVector3(0.8, 1, 0.4), SCNVector3(1, 0.7, 0.2)),
            // Pink to Blue to Cyan
            (SCNVector3(1, 0.4, 0.8), SCNVector3(0.4, 0.8, 1), SCNVector3(0.2, 0.9, 1))
        ]
        
        return colorSets[index % colorSets.count]
    }
    
    static func animateGradientMaterial(_ node: SCNNode, duration: Double = 1.5) {
        guard let material = node.geometry?.firstMaterial else { return }
        guard let edgeIndex = node.value(forKey: "edgeIndex") as? Int else { return }
        
        // Apply base material with bright teal color
        let baseColor = UIColor.cyan
        material.diffuse.contents = baseColor
        material.emission.contents = baseColor
        material.emission.intensity = 1.0
        material.lightingModel = .constant
        material.isDoubleSided = true
        
        // Create vertex shader for smooth traveling bulge
        let vertexShader = """
        uniform float u_time;
        uniform float u_bulgePosition;
        uniform float u_bulgeWidth;
        uniform float u_bulgeIntensity;
        
        #pragma body
        
        // Get the Y coordinate (along the cylinder height)
        float normalizedY = (_geometry.position.y + 0.5); // Convert from -0.5,0.5 to 0,1
        
        // Calculate distance from current bulge position
        float distanceFromBulge = abs(normalizedY - u_bulgePosition);
        
        // Create smooth bulge falloff using smoothstep
        float bulgeEffect = smoothstep(u_bulgeWidth, 0.0, distanceFromBulge);
        
        // Apply bulge to radial coordinates (x and z)
        float radiusMultiplier = 1.0 + bulgeEffect * u_bulgeIntensity;
        
        _geometry.position.x *= radiusMultiplier;
        _geometry.position.z *= radiusMultiplier;
        """
        
        material.shaderModifiers = [.geometry: vertexShader]
        
        // Set initial uniform values
        material.setValue(0.0, forKey: "u_time")
        material.setValue(0.0, forKey: "u_bulgePosition") 
        material.setValue(0.12, forKey: "u_bulgeWidth")    // Width of the bulge
        material.setValue(1.5, forKey: "u_bulgeIntensity") // How much it bulges
        
        // Create traveling bulge animation
        createSmoothTravelingBulge(for: material, duration: duration + Double(edgeIndex % 4) * 0.3)
    }
    
    static func createSmoothTravelingBulge(for material: SCNMaterial, duration: Double) {
        // Simple single bulge that travels along the edge
        let positionAnimation = CABasicAnimation(keyPath: "u_bulgePosition")
        positionAnimation.fromValue = 0.0
        positionAnimation.toValue = 1.0
        positionAnimation.duration = duration
        positionAnimation.repeatCount = .infinity
        positionAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        material.addAnimation(positionAnimation, forKey: "bulgePosition")
        
        // Create 2 traveling bulges by having 2 bright spots per cycle
        let brightAnimation = CAKeyframeAnimation(keyPath: "emission.intensity")
        brightAnimation.values = [0.8, 2.0, 4.0, 2.0, 0.8, 2.0, 4.0, 2.0, 0.8]
        brightAnimation.keyTimes = [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1.0]
        brightAnimation.duration = duration
        brightAnimation.repeatCount = .infinity
        brightAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        material.addAnimation(brightAnimation, forKey: "brightness")
        
        // Color animation with 2 bright cycles to match the bulges
        let colorAnimation = CAKeyframeAnimation(keyPath: "emission.contents")
        let darkTeal = UIColor(red: 0, green: 0.6, blue: 0.8, alpha: 1)
        let brightCyan = UIColor.cyan
        let whiteCyan = UIColor(red: 0.7, green: 1, blue: 1, alpha: 1)
        
        colorAnimation.values = [darkTeal, brightCyan, whiteCyan, brightCyan, darkTeal, brightCyan, whiteCyan, brightCyan, darkTeal]
        colorAnimation.keyTimes = [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1.0]
        colorAnimation.duration = duration
        colorAnimation.repeatCount = .infinity
        colorAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        material.addAnimation(colorAnimation, forKey: "color")
    }
}