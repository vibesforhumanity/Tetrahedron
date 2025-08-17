import SwiftUI
import SceneKit

struct ShapeSceneView: UIViewRepresentable {
    @Binding var selectedShape: ShapeType
    
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
        
        addShape(selectedShape, to: shapeContainer)
        StarFieldGenerator.addStarField(to: scene.rootNode)
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(SceneCoordinator.handlePan(_:)))
        scnView.addGestureRecognizer(panGesture)
        
        context.coordinator.scnView = scnView
        context.coordinator.shapeContainer = shapeContainer
        
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
        
        addShape(selectedShape, to: shapeContainer)
        
        SCNTransaction.commit()
    }
    
    func makeCoordinator() -> SceneCoordinator {
        SceneCoordinator()
    }
    
    private func addShape(_ type: ShapeType, to container: SCNNode) {
        let shapeNode = SCNNode()
        shapeNode.name = "shape"
        
        let (vertices, edges) = ShapeGenerator.getVerticesAndEdges(for: type)
        
        for (index, edge) in edges.enumerated() {
            let edgeNode = GeometryUtils.createEdge(from: vertices[edge.0], to: vertices[edge.1])
            let material = ShapeGenerator.createEdgeMaterial(for: index)
            edgeNode.geometry?.firstMaterial = material
            
            // Store edge index for animation reference
            edgeNode.setValue(index, forKey: "edgeIndex")
            
            // Apply animated gradient material with flowing colors and enhanced glow
            AnimatedGradientMaterial.animateGradientMaterial(edgeNode, duration: 2.5 + Double(index % 4) * 0.5)
            
            shapeNode.addChildNode(edgeNode)
        }
        
        let vertexMaterial = ShapeGenerator.createVertexMaterial()
        
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
        
        shapeNode.opacity = 0
        container.addChildNode(shapeNode)
        shapeNode.runAction(SCNAction.fadeIn(duration: 0.3))
    }
}