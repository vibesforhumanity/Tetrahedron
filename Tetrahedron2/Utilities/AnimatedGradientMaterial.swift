import SceneKit
import UIKit
import Foundation

class AnimatedGradientMaterial {
    
    static func createAnimatedGradientMaterial(for index: Int) -> SCNMaterial {
        let material = SCNMaterial()
        
        // Very simple, visible material
        let tealColor = UIColor.cyan
        material.diffuse.contents = tealColor
        material.emission.contents = UIColor.white //tealColor
        material.emission.intensity = 1.0
        
        // Use basic material properties
        material.lightingModel = .constant
        material.isDoubleSided = true
        
        return material
    }
    
    static func createMovingGradientTexture() -> UIImage {
        let size = CGSize(width: 200, height: 50)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Create a gradient from dark teal -> bright cyan -> white -> bright cyan -> dark teal
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor(red: 0, green: 0.3, blue: 0.4, alpha: 1).cgColor,  // dark teal
                UIColor(red: 0, green: 0.8, blue: 1, alpha: 1).cgColor,    // bright cyan
                UIColor(red: 0.5, green: 1, blue: 1, alpha: 1).cgColor,    // bright white-cyan
                UIColor(red: 0.8, green: 0, blue: 1, alpha: 1).cgColor,    // purple
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
        
        // Create combined vertex and surface shaders for traveling bulge with color
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
        
        let surfaceShader = """
        uniform float u_bulgePosition;
        uniform float u_bulgeWidth;
        
        #pragma body
        
        // Get the texture coordinate Y and flip it to match geometry coordinate system
        float normalizedY = 1.0 - _surface.diffuseTexcoord.y;
        
        // Calculate distance from current bulge position - same as vertex shader
        float distanceFromBulge = abs(normalizedY - u_bulgePosition);
        
        // Create brightness effect that matches the bulge exactly
        float brightness = smoothstep(u_bulgeWidth, 0.0, distanceFromBulge);
        
        // Base colors
        vec3 darkTeal = vec3(0.0, 0.6, 0.8);
        vec3 brightCyan = vec3(0.0, 1.0, 1.0);
        vec3 whiteCyan = vec3(0.8, 1.0, 1.0);
        
        // Mix colors based on brightness - bulge areas are bright white/cyan
        vec3 finalColor = mix(darkTeal, brightCyan, brightness);
        finalColor = mix(finalColor, whiteCyan, brightness * brightness); // Extra white at peak
        
        // Set emission intensity that matches bulge presence
        float intensity = 1.0 + brightness * 3.0;
        
        _surface.diffuse = vec4(finalColor, 1.0);
        _surface.emission = vec4(finalColor * intensity, 1.0);
        """
        
        material.shaderModifiers = [.geometry: vertexShader, .surface: surfaceShader]
        
        // Set initial uniform values
        material.setValue(0.0, forKey: "u_time")
        material.setValue(0.0, forKey: "u_bulgePosition") 
        material.setValue(0.1, forKey: "u_bulgeWidth")    // Width of the bulge
        material.setValue(1.0, forKey: "u_bulgeIntensity") // How much it bulges
        
        // Create traveling bulge animation with realistic light reflection timing
        let randomDelay = Double.random(in: 0.0...0.8)
        let randomSpeed = Double.random(in: 0.8...1.4) 
        createSmoothTravelingBulge(for: material, duration: duration * randomSpeed, delay: randomDelay)
    }
    
    static func createSmoothTravelingBulge(for material: SCNMaterial, duration: Double, delay: Double = 0.0) {
        // Single animation that controls both geometry and color
        // The surface shader will automatically make the bulge bright white/cyan
        let positionAnimation = CABasicAnimation(keyPath: "u_bulgePosition")
        positionAnimation.fromValue = 0.0
        positionAnimation.toValue = 1.0
        positionAnimation.duration = duration
        positionAnimation.repeatCount = .infinity
        positionAnimation.beginTime = CACurrentMediaTime() + delay
        positionAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut) // More realistic reflection timing
        
        material.addAnimation(positionAnimation, forKey: "bulgePosition")
    }
}
