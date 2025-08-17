import SwiftUI
import SceneKit

// MARK: - Main App
@main
struct ShapesSpinApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Content View
struct ContentView: View {
    @State private var selectedShape: ShapeType = .tetrahedron
    @State private var showShapeSelector = false
    
    var body: some View {
        ZStack {
            // 3D Scene
            ShapeSceneView(selectedShape: $selectedShape)
                .ignoresSafeArea()
            
            // Shape Selector UI
            VStack {
                Spacer()
                
                if showShapeSelector {
                    ShapeSelectorView(selectedShape: $selectedShape, showSelector: $showShapeSelector)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Handle for shape selector
                VStack(spacing: 4) {
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 40, height: 4)
                    
                    Text("Shapes")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.bottom, showShapeSelector ? 0 : 20)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showShapeSelector.toggle()
                    }
                }
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if value.translation.height < -50 {
                                    showShapeSelector = true
                                } else if value.translation.height > 50 {
                                    showShapeSelector = false
                                }
                            }
                        }
                )
            }
        }
        .statusBar(hidden: true)
    }
}

// MARK: - Shape Types
enum ShapeType: CaseIterable {
    case tetrahedron
    case cube
    case octahedron
    case dodecahedron
    case icosahedron
    
    var name: String {
        switch self {
        case .tetrahedron: return "Tetrahedron"
        case .cube: return "Cube"
        case .octahedron: return "Octahedron"
        case .dodecahedron: return "Dodecahedron"
        case .icosahedron: return "Icosahedron"
        }
    }
    
    var icon: String {
        switch self {
        case .tetrahedron: return "▲"
        case .cube: return "◻︎"
        case .octahedron: return "◆"
        case .dodecahedron: return "⬟"
        case .icosahedron: return "◉"
        }
    }
}

// MARK: - Shape Selector View
struct ShapeSelectorView: View {
    @Binding var selectedShape: ShapeType
    @Binding var showSelector: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                ForEach(ShapeType.allCases, id: \.self) { shape in
                    VStack(spacing: 8) {
                        Text(shape.icon)
                            .font(.system(size: 32))
                            .foregroundColor(selectedShape == shape ? .cyan : .white.opacity(0.6))
                        
                        Text(shape.name)
                            .font(.caption2)
                            .foregroundColor(selectedShape == shape ? .cyan : .white.opacity(0.4))
                    }
                    .frame(width: 70)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedShape = shape
                            showSelector = false
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(.bottom, 40)
    }
}

// MARK: - 3D Scene View
struct ShapeSceneView: UIViewRepresentable {
    @Binding var selectedShape: ShapeType
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .black
        scnView.antialiasingMode = .multisampling4X
        scnView.allowsCameraControl = false
        
        // Setup scene
        let scene = SCNScene()
        scnView.scene = scene
        
        // Add gradient background
        scene.background.contents = createGradientImage()
        
        // Setup camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 5)
        scene.rootNode.addChildNode(cameraNode)
        
        // Add lighting
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .ambient
        lightNode.light!.color = UIColor.white.withAlphaComponent(0.3)
        scene.rootNode.addChildNode(lightNode)
        
        // Create shape container
        let shapeContainer = SCNNode()
        shapeContainer.name = "shapeContainer"
        scene.rootNode.addChildNode(shapeContainer)
        
        // Add initial shape
        addShape(selectedShape, to: shapeContainer)
        
        // Add star field
        addStarField(to: scene.rootNode)
        
        // Add gesture recognizer
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        scnView.addGestureRecognizer(panGesture)
        
        context.coordinator.scnView = scnView
        context.coordinator.shapeContainer = shapeContainer
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        guard let shapeContainer = uiView.scene?.rootNode.childNode(withName: "shapeContainer", recursively: false) else { return }
        
        // Transition to new shape
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        
        // Remove old shape
        shapeContainer.enumerateChildNodes { node, _ in
            if node.name == "shape" {
                node.opacity = 0
                node.runAction(SCNAction.sequence([
                    SCNAction.wait(duration: 0.3),
                    SCNAction.removeFromParentNode()
                ]))
            }
        }
        
        // Add new shape
        addShape(selectedShape, to: shapeContainer)
        
        SCNTransaction.commit()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // MARK: - Helper Functions
    
    private func createGradientImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else { return UIImage() }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [UIColor.black.cgColor, UIColor(red: 0, green: 0, blue: 0.1, alpha: 1).cgColor]
        let locations: [CGFloat] = [0, 1]
        
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) else {
            return UIImage()
        }
        
        context.drawRadialGradient(gradient,
                                  startCenter: CGPoint(x: 50, y: 50),
                                  startRadius: 0,
                                  endCenter: CGPoint(x: 50, y: 50),
                                  endRadius: 70,
                                  options: [])
        
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
    
    private func addShape(_ type: ShapeType, to container: SCNNode) {
        let shapeNode = SCNNode()
        shapeNode.name = "shape"
        
        let vertices: [SCNVector3]
        let edges: [(Int, Int)]
        
        // All shapes normalized to same bounding box size
        let targetSize: Float = 0.7  // Target bounding box dimension
        
        switch type {
        case .tetrahedron:
            let a: Float = targetSize / 2.3  // Adjusted for same visual size
            vertices = [
                SCNVector3(a, a, a),
                SCNVector3(-a, -a, a),
                SCNVector3(-a, a, -a),
                SCNVector3(a, -a, -a)
            ]
            edges = [(0,1), (0,2), (0,3), (1,2), (1,3), (2,3)]
            
        case .cube:
            let a: Float = targetSize / 2.0
            vertices = [
                SCNVector3(-a, -a, -a), SCNVector3(a, -a, -a),
                SCNVector3(a, a, -a), SCNVector3(-a, a, -a),
                SCNVector3(-a, -a, a), SCNVector3(a, -a, a),
                SCNVector3(a, a, a), SCNVector3(-a, a, a)
            ]
            edges = [(0,1), (1,2), (2,3), (3,0), (4,5), (5,6), (6,7), (7,4),
                    (0,4), (1,5), (2,6), (3,7)]
            
        case .octahedron:
            let a: Float = targetSize / 1.4
            vertices = [
                SCNVector3(a, 0, 0), SCNVector3(-a, 0, 0),
                SCNVector3(0, a, 0), SCNVector3(0, -a, 0),
                SCNVector3(0, 0, a), SCNVector3(0, 0, -a)
            ]
            edges = [(0,2), (0,3), (0,4), (0,5), (1,2), (1,3), (1,4), (1,5),
                    (2,4), (2,5), (3,4), (3,5)]
            
        case .dodecahedron:
            let phi: Float = (1 + sqrt(5)) / 2
            let a: Float = targetSize / 3.5
            vertices = [
                // Cube vertices
                SCNVector3(-a, -a, -a), SCNVector3(a, -a, -a),
                SCNVector3(a, a, -a), SCNVector3(-a, a, -a),
                SCNVector3(-a, -a, a), SCNVector3(a, -a, a),
                SCNVector3(a, a, a), SCNVector3(-a, a, a),
                // Rectangle vertices in xy-plane
                SCNVector3(0, -phi*a, -1/phi*a), SCNVector3(0, phi*a, -1/phi*a),
                SCNVector3(0, -phi*a, 1/phi*a), SCNVector3(0, phi*a, 1/phi*a),
                // Rectangle vertices in xz-plane
                SCNVector3(-1/phi*a, 0, -phi*a), SCNVector3(1/phi*a, 0, -phi*a),
                SCNVector3(-1/phi*a, 0, phi*a), SCNVector3(1/phi*a, 0, phi*a),
                // Rectangle vertices in yz-plane
                SCNVector3(-phi*a, -1/phi*a, 0), SCNVector3(phi*a, -1/phi*a, 0),
                SCNVector3(-phi*a, 1/phi*a, 0), SCNVector3(phi*a, 1/phi*a, 0)
            ]
            edges = [(0,8), (0,12), (0,16), (1,8), (1,13), (1,17), (2,9), (2,13), (2,19),
                    (3,9), (3,12), (3,18), (4,10), (4,14), (4,16), (5,10), (5,15), (5,17),
                    (6,11), (6,15), (6,19), (7,11), (7,14), (7,18), (8,10), (9,11),
                    (12,13), (14,15), (16,18), (17,19)]
            
        case .icosahedron:
            let phi: Float = (1 + sqrt(5)) / 2
            let a: Float = targetSize / 2.8
            vertices = [
                SCNVector3(0, a, phi*a), SCNVector3(0, a, -phi*a),
                SCNVector3(0, -a, phi*a), SCNVector3(0, -a, -phi*a),
                SCNVector3(a, phi*a, 0), SCNVector3(a, -phi*a, 0),
                SCNVector3(-a, phi*a, 0), SCNVector3(-a, -phi*a, 0),
                SCNVector3(phi*a, 0, a), SCNVector3(phi*a, 0, -a),
                SCNVector3(-phi*a, 0, a), SCNVector3(-phi*a, 0, -a)
            ]
            edges = [(0,2), (0,4), (0,6), (0,8), (0,10), (1,3), (1,4), (1,6), (1,9), (1,11),
                    (2,5), (2,7), (2,8), (2,10), (3,5), (3,7), (3,9), (3,11), (4,6), (4,8),
                    (4,9), (5,7), (5,8), (5,9), (6,10), (6,11), (7,10), (7,11), (8,9), (10,11)]
        }
        
        // Create edges with multi-colored materials
        for (index, edge) in edges.enumerated() {
            let edgeNode = createEdge(from: vertices[edge.0], to: vertices[edge.1])
            
            // Create unique material for each edge
            let edgeMaterial = SCNMaterial()
            
            // Use different base colors that cycle through the edges
            let colorIndex = index % 6
            switch colorIndex {
            case 0:
                edgeMaterial.diffuse.contents = UIColor.cyan
                edgeMaterial.emission.contents = UIColor(red: 0, green: 1, blue: 1, alpha: 1)
            case 1:
                edgeMaterial.diffuse.contents = UIColor(red: 1, green: 0, blue: 1, alpha: 1) // Magenta
                edgeMaterial.emission.contents = UIColor(red: 1, green: 0, blue: 0.8, alpha: 1)
            case 2:
                edgeMaterial.diffuse.contents = UIColor(red: 1, green: 0.5, blue: 0, alpha: 1) // Orange
                edgeMaterial.emission.contents = UIColor(red: 1, green: 0.6, blue: 0.2, alpha: 1)
            case 3:
                edgeMaterial.diffuse.contents = UIColor(red: 0.5, green: 0, blue: 1, alpha: 1) // Purple
                edgeMaterial.emission.contents = UIColor(red: 0.6, green: 0.2, blue: 1, alpha: 1)
            case 4:
                edgeMaterial.diffuse.contents = UIColor(red: 0, green: 1, blue: 0.5, alpha: 1) // Teal
                edgeMaterial.emission.contents = UIColor(red: 0.2, green: 1, blue: 0.6, alpha: 1)
            case 5:
                edgeMaterial.diffuse.contents = UIColor(red: 1, green: 0, blue: 0.5, alpha: 1) // Pink
                edgeMaterial.emission.contents = UIColor(red: 1, green: 0.2, blue: 0.6, alpha: 1)
            default:
                edgeMaterial.diffuse.contents = UIColor.cyan
                edgeMaterial.emission.contents = UIColor.cyan
            }
            
            edgeMaterial.emission.intensity = 1.5
            edgeNode.geometry?.firstMaterial = edgeMaterial
            
            // Add pulse animation with varied timing
            let pulseAnimation = CABasicAnimation(keyPath: "geometry.firstMaterial.emission.intensity")
            pulseAnimation.fromValue = 1.0
            pulseAnimation.toValue = 2.0
            pulseAnimation.duration = 1.5 + Double(index % 3) * 0.5
            pulseAnimation.autoreverses = true
            pulseAnimation.repeatCount = .infinity
            pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            edgeNode.addAnimation(pulseAnimation, forKey: "pulse")
            
            shapeNode.addChildNode(edgeNode)
        }
        
        // Create vertex dots with glow
        let vertexMaterial = SCNMaterial()
        vertexMaterial.diffuse.contents = UIColor.white
        vertexMaterial.emission.contents = UIColor.white.withAlphaComponent(0.8)
        vertexMaterial.emission.intensity = 1.2
        
        for (index, vertex) in vertices.enumerated() {
            let sphere = SCNSphere(radius: 0.025)
            sphere.firstMaterial = vertexMaterial
            let vertexNode = SCNNode(geometry: sphere)
            vertexNode.position = vertex
            
            // Add subtle pulse to vertices
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
        
        // Fade in animation
        shapeNode.opacity = 0
        container.addChildNode(shapeNode)
        shapeNode.runAction(SCNAction.fadeIn(duration: 0.3))
    }
    
    private func createEdge(from: SCNVector3, to: SCNVector3) -> SCNNode {
        let distance = sqrt(pow(to.x - from.x, 2) + pow(to.y - from.y, 2) + pow(to.z - from.z, 2))
        let cylinder = SCNCylinder(radius: 0.01, height: CGFloat(distance))
        
        let node = SCNNode(geometry: cylinder)
        node.position = SCNVector3((from.x + to.x) / 2, (from.y + to.y) / 2, (from.z + to.z) / 2)
        
        let direction = SCNVector3(to.x - from.x, to.y - from.y, to.z - from.z)
        let up = SCNVector3(0, 1, 0)
        
        let dot = direction.y / distance
        if abs(dot) < 0.999 {
            let axis = normalize(cross(up, direction))
            let angle = acos(dot)
            node.rotation = SCNVector4(axis.x, axis.y, axis.z, angle)
        } else {
            if dot < 0 {
                node.rotation = SCNVector4(1, 0, 0, Float.pi)
            }
        }
        
        return node
    }
    
    private func addStarField(to rootNode: SCNNode) {
        // Create three layers of particles for depth
        for i in 0..<3 {
            let particleSystem = SCNParticleSystem()
            particleSystem.birthRate = 50 + CGFloat(i * 30)
            particleSystem.particleLifeSpan = 10
            particleSystem.particleLifeSpanVariation = 2
            
            particleSystem.particleSize = CGFloat(0.02 - Float(i) * 0.005)
            particleSystem.particleSizeVariation = 0.01
            
            particleSystem.particleColor = UIColor.white
            particleSystem.particleColorVariation = SCNVector4(0, 0, 0, 0.3)
            
            particleSystem.emitterShape = SCNSphere(radius: 10)
            particleSystem.birthLocation = .surface
            particleSystem.birthDirection = .surfaceNormal
            
            particleSystem.particleVelocity = CGFloat(0.5 + Float(i) * 0.3)
            particleSystem.particleVelocityVariation = 0.2
            particleSystem.acceleration = SCNVector3(0, 0, 2)
            
            // Add twinkling
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
    
    
    // MARK: - Vector Helper Functions
    private func normalize(_ vector: SCNVector3) -> SCNVector3 {
        let length = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        guard length > 0 else { return vector }
        return SCNVector3(vector.x / length, vector.y / length, vector.z / length)
    }
    
    private func cross(_ a: SCNVector3, _ b: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            a.y * b.z - a.z * b.y,
            a.z * b.x - a.x * b.z,
            a.x * b.y - a.y * b.x
        )
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject {
        weak var scnView: SCNView?
        weak var shapeContainer: SCNNode?
        
        private var lastPanLocation: CGPoint = .zero
        private var currentVelocity: CGVector = .zero
        private var baseRotationSpeed: CGVector = CGVector(dx: 30, dy: 20)  // Base speed
        private var addedVelocity: CGVector = .zero  // Velocity added by swipes
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
            
            // Combine base rotation with added velocity for total rotation
            let totalVelocityX = baseRotationSpeed.dx + addedVelocity.dx
            let totalVelocityY = baseRotationSpeed.dy + addedVelocity.dy
            
            // Apply rotation
            let rotationX = Float(totalVelocityY) * 0.0001
            let rotationY = Float(totalVelocityX) * 0.0001
            
            let currentTransform = shapeContainer.transform
            let rotationMatrix = SCNMatrix4MakeRotation(rotationX, 1, 0, 0)
            let rotationMatrix2 = SCNMatrix4MakeRotation(rotationY, 0, 1, 0)
            
            shapeContainer.transform = SCNMatrix4Mult(SCNMatrix4Mult(currentTransform, rotationMatrix), rotationMatrix2)
            
            // Gradually decay added velocity back to zero (returns to base speed)
            addedVelocity.dx *= 0.985  // Slower decay for longer momentum
            addedVelocity.dy *= 0.985
            
            // If velocity is very small, set to zero
            if abs(addedVelocity.dx) < 0.1 && abs(addedVelocity.dy) < 0.1 {
                addedVelocity = .zero
            }
            
            // Update star field based on total velocity
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
                // Calculate drag delta
                let deltaX = location.x - lastPanLocation.x
                let deltaY = location.y - lastPanLocation.y
                
                // Track current gesture velocity
                currentVelocity = CGVector(dx: velocity.x, dy: velocity.y)
                
                // Add immediate rotation feedback during drag
                addedVelocity.dx += deltaX * 3  // Amplify for better responsiveness
                addedVelocity.dy += deltaY * 3
                
                // Cap maximum added velocity to prevent too-fast spinning
                let maxAddedVelocity: CGFloat = 3000
                addedVelocity.dx = max(-maxAddedVelocity, min(maxAddedVelocity, addedVelocity.dx))
                addedVelocity.dy = max(-maxAddedVelocity, min(maxAddedVelocity, addedVelocity.dy))
                
                lastPanLocation = location
                
            case .ended, .cancelled:
                // Apply momentum boost based on final swipe velocity
                let boostFactor: CGFloat = 1.5
                addedVelocity.dx += currentVelocity.dx * boostFactor
                addedVelocity.dy += currentVelocity.dy * boostFactor
                
                // Cap the total momentum
                let maxMomentum: CGFloat = 4000
                addedVelocity.dx = max(-maxMomentum, min(maxMomentum, addedVelocity.dx))
                addedVelocity.dy = max(-maxMomentum, min(maxMomentum, addedVelocity.dy))
                
            default:
                break
            }
        }
        
        private func updateStarFieldVelocity(speed: CGFloat) {
            guard let rootNode = scnView?.scene?.rootNode else { return }
            
            // Calculate speed multiplier (base speed = ~36, so divide by that for baseline of 1)
            let baseSpeed: CGFloat = 36
            let speedMultiplier = speed / baseSpeed
            
            // Update each star field layer
            for i in 0..<3 {
                if let particleNode = rootNode.childNode(withName: "starField\(i)", recursively: false),
                   let particleSystem = particleNode.particleSystems?.first {
                    
                    // Base values for each layer
                    let baseVelocity = CGFloat(0.5 + Float(i) * 0.3)
                    let baseBirthRate = 50 + CGFloat(i * 30)
                    
                    // Apply multiplier (minimum 1 for base rotation speed)
                    let effectiveMultiplier = max(1, speedMultiplier)
                    
                    particleSystem.particleVelocity = baseVelocity * effectiveMultiplier
                    particleSystem.birthRate = baseBirthRate * (1 + (effectiveMultiplier - 1) * 0.3)
                    
                    // Adjust acceleration for tumbling effect
                    let accel = 2 + Float(effectiveMultiplier - 1) * 1.5
                    particleSystem.acceleration = SCNVector3(0, 0, accel)
                }
            }
        }
    }
}
