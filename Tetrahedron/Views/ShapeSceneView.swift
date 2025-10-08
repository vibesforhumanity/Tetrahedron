import SwiftUI
import SceneKit

struct ShapeSceneView: UIViewRepresentable {
    @Binding var selectedShape: ShapeType
    let selectedColor: NeonColor
    let config: AppConfiguration
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .black
        scnView.antialiasingMode = .multisampling4X
        scnView.allowsCameraControl = false
        
        let scene = SCNScene()
        scnView.scene = scene
        
        scene.background.contents = GeometryUtils.createGradientImage()
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 5)
        scene.rootNode.addChildNode(cameraNode)
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .ambient
        lightNode.light!.color = UIColor.white.withAlphaComponent(0.3)
        scene.rootNode.addChildNode(lightNode)
        
        let shapeContainer = SCNNode()
        shapeContainer.name = "shapeContainer"
        scene.rootNode.addChildNode(shapeContainer)
        
        addShape(selectedShape, color: selectedColor, to: shapeContainer)
        StarFieldGenerator.addStarField(to: scene.rootNode)
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(SceneCoordinator.handlePan(_:)))
        scnView.addGestureRecognizer(panGesture)
        
        context.coordinator.scnView = scnView
        context.coordinator.shapeContainer = shapeContainer
        context.coordinator.config = config
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        guard let shapeContainer = uiView.scene?.rootNode.childNode(withName: "shapeContainer", recursively: false) else { return }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        
        shapeContainer.enumerateChildNodes { node, _ in
            if node.name == "shape" {
                node.opacity = 0
                node.runAction(SCNAction.sequence([
                    SCNAction.wait(duration: 0.3),
                    SCNAction.removeFromParentNode()
                ]))
            }
        }
        
        addShape(selectedShape, color: selectedColor, to: shapeContainer)
        
        SCNTransaction.commit()
    }
    
    func makeCoordinator() -> SceneCoordinator {
        SceneCoordinator(config: config)
    }
    
    private func addShape(_ type: ShapeType, color: NeonColor, to container: SCNNode) {
        let shapeNode = SCNNode()
        shapeNode.name = "shape"
        
        let (vertices, edges) = ShapeGenerator.getVerticesAndEdges(for: type)
        
        for (index, edge) in edges.enumerated() {
            let edgeNode = GeometryUtils.createEdge(from: vertices[edge.0], to: vertices[edge.1])
            let material = ShapeGenerator.createEdgeMaterial(for: index, color: color)
            edgeNode.geometry?.firstMaterial = material
            
            // Store edge index for animation reference
            edgeNode.setValue(index, forKey: "edgeIndex")
            
            // COMMENTED OUT FOR DEBUGGING: Apply animated gradient material with flowing colors and enhanced glow
            // AnimatedGradientMaterial.animateGradientMaterial(edgeNode, duration: 2.5 + Double(index % 4) * 0.5, color: color)
            
            shapeNode.addChildNode(edgeNode)
        }
        
        let vertexMaterial = ShapeGenerator.createVertexMaterial(color: color)
        
        for (index, vertex) in vertices.enumerated() {
            let sphere = SCNSphere(radius: 0.025)
            sphere.firstMaterial = vertexMaterial
            let vertexNode = SCNNode(geometry: sphere)
            vertexNode.position = vertex
            
            let vertexPulse = CABasicAnimation(keyPath: "geometry.radius")
            vertexPulse.fromValue = 0.025
            vertexPulse.toValue = 0.03
            vertexPulse.duration = 1.5 + Double(index) * 0.1
            vertexPulse.autoreverses = true
            vertexPulse.repeatCount = .infinity
            vertexPulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            vertexNode.addAnimation(vertexPulse, forKey: "vertexPulse")
            
            shapeNode.addChildNode(vertexNode)
        }
        
        // Volumetric haze removed for cleaner rendering
        
        shapeNode.opacity = 0
        container.addChildNode(shapeNode)
        shapeNode.runAction(SCNAction.fadeIn(duration: 0.3))
    }
    
    private func addVolumetricHaze(to container: SCNNode, color: NeonColor) {
        // Create multiple layers of haze contained within the shape center
        let hazeLayers = [
            (radius: Float(0.03), opacity: Float(0.8), emission: Float(2.2)),  // Dense center
            (radius: Float(0.06), opacity: Float(0.5), emission: Float(1.6)), // Mid layer
            (radius: Float(0.10), opacity: Float(0.25), emission: Float(1.0)), // Outer layer
            (radius: Float(0.15), opacity: Float(0.12), emission: Float(0.6)), // Edge fade
            (radius: Float(0.20), opacity: Float(0.05), emission: Float(0.3)) // Boundary
        ]
        
        for (index, layer) in hazeLayers.enumerated() {
            let hazeSphere = SCNSphere(radius: CGFloat(layer.radius))
            let hazeNode = SCNNode(geometry: hazeSphere)
            // Add slight z-offset to prevent z-fighting between layers
            hazeNode.position = SCNVector3(0, 0, Float(index) * 0.001)
            
            // Create haze material with varying opacity and emission
            let hazeMaterial = SCNMaterial()
            hazeMaterial.diffuse.contents = color.uiColor.withAlphaComponent(CGFloat(layer.opacity * 0.3))
            hazeMaterial.emission.contents = color.uiColor
            hazeMaterial.emission.intensity = CGFloat(layer.emission)
            hazeMaterial.lightingModel = .constant
            hazeMaterial.transparency = CGFloat(layer.opacity)
            hazeMaterial.blendMode = .add // Additive blending for volumetric effect
            hazeMaterial.isDoubleSided = true
            hazeMaterial.writesToDepthBuffer = false // Prevent depth conflicts
            hazeMaterial.readsFromDepthBuffer = true // Still respect depth for proper sorting
            hazeSphere.firstMaterial = hazeMaterial
            
            // Add subtle breathing animation with different phases for each layer
            let breatheAnimation = CABasicAnimation(keyPath: "geometry.radius")
            breatheAnimation.fromValue = layer.radius
            breatheAnimation.toValue = layer.radius * 1.08 // Smaller expansion to stay within bounds
            breatheAnimation.duration = 3.0 + Double(index) * 0.5 // Different speeds for layers
            breatheAnimation.autoreverses = true
            breatheAnimation.repeatCount = .infinity
            breatheAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            breatheAnimation.beginTime = CACurrentMediaTime() + Double(index) * 0.3 // Staggered start
            hazeNode.addAnimation(breatheAnimation, forKey: "hazeBreathe")
            
            // Add gentle opacity pulsing
            let opacityAnimation = CABasicAnimation(keyPath: "geometry.firstMaterial.transparency")
            opacityAnimation.fromValue = layer.opacity
            opacityAnimation.toValue = layer.opacity * 1.3
            opacityAnimation.duration = 4.0 + Double(index) * 0.2
            opacityAnimation.autoreverses = true
            opacityAnimation.repeatCount = .infinity
            opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            opacityAnimation.beginTime = CACurrentMediaTime() + Double(index) * 0.1
            hazeNode.addAnimation(opacityAnimation, forKey: "hazeOpacity")
            
            // Add very slow rotation for subtle movement
            if index % 2 == 0 { // Alternate rotation directions
                let rotationAnimation = CABasicAnimation(keyPath: "rotation")
                rotationAnimation.fromValue = SCNVector4(0, 1, 0, 0)
                rotationAnimation.toValue = SCNVector4(0, 1, 0, Float.pi * 2)
                rotationAnimation.duration = 15.0 + Double(index) * 2.0
                rotationAnimation.repeatCount = .infinity
                hazeNode.addAnimation(rotationAnimation, forKey: "hazeRotation")
            }
            
            container.addChildNode(hazeNode)
        }
    }
}