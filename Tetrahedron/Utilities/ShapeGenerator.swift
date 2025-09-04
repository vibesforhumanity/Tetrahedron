import SceneKit
import UIKit

struct ShapeGenerator {
    
    static func getVerticesAndEdges(for shapeType: ShapeType) -> (vertices: [SCNVector3], edges: [(Int, Int)]) {
        let targetSize: Float = 0.7
        
        switch shapeType {
        case .tetrahedron:
            let a: Float = targetSize / 2.3
            let vertices = [
                SCNVector3(a, a, a),
                SCNVector3(-a, -a, a),
                SCNVector3(-a, a, -a),
                SCNVector3(a, -a, -a)
            ]
            let edges = [(0,1), (0,2), (0,3), (1,2), (1,3), (2,3)]
            return (vertices, edges)
            
        case .cube:
            let a: Float = targetSize / 2.0
            let vertices = [
                SCNVector3(-a, -a, -a), SCNVector3(a, -a, -a),
                SCNVector3(a, a, -a), SCNVector3(-a, a, -a),
                SCNVector3(-a, -a, a), SCNVector3(a, -a, a),
                SCNVector3(a, a, a), SCNVector3(-a, a, a)
            ]
            let edges = [(0,1), (1,2), (2,3), (3,0), (4,5), (5,6), (6,7), (7,4),
                        (0,4), (1,5), (2,6), (3,7)]
            return (vertices, edges)
            
        case .octahedron:
            let a: Float = targetSize / 1.4
            let vertices = [
                SCNVector3(a, 0, 0), SCNVector3(-a, 0, 0),
                SCNVector3(0, a, 0), SCNVector3(0, -a, 0),
                SCNVector3(0, 0, a), SCNVector3(0, 0, -a)
            ]
            let edges = [(0,2), (0,3), (0,4), (0,5), (1,2), (1,3), (1,4), (1,5),
                        (2,4), (2,5), (3,4), (3,5)]
            return (vertices, edges)
            
        case .icosahedron:
            let phi: Float = (1 + sqrt(5)) / 2
            let a: Float = targetSize / 2.8
            let vertices = [
                SCNVector3(0, a, phi*a), SCNVector3(0, a, -phi*a),
                SCNVector3(0, -a, phi*a), SCNVector3(0, -a, -phi*a),
                SCNVector3(a, phi*a, 0), SCNVector3(a, -phi*a, 0),
                SCNVector3(-a, phi*a, 0), SCNVector3(-a, -phi*a, 0),
                SCNVector3(phi*a, 0, a), SCNVector3(phi*a, 0, -a),
                SCNVector3(-phi*a, 0, a), SCNVector3(-phi*a, 0, -a)
            ]
            let edges = [(0,2), (0,4), (0,6), (0,8), (0,10), (1,3), (1,4), (1,6), (1,9), (1,11),
                        (2,5), (2,7), (2,8), (2,10), (3,5), (3,7), (3,9), (3,11), (4,6), (4,8),
                        (4,9), (5,7), (5,8), (5,9), (6,10), (6,11), (7,10), (7,11), (8,9), (10,11)]
            return (vertices, edges)
        }
    }
    
    static func createEdgeMaterial(for index: Int, color: NeonColor) -> SCNMaterial {
        let material = SCNMaterial()
        let selectedColor = color.uiColor
        
        material.diffuse.contents = selectedColor
        material.emission.contents = selectedColor
        material.emission.intensity = 1.0
        material.lightingModel = .constant
        material.isDoubleSided = true
        
        return material
    }
    
    static func createVertexMaterial(color: NeonColor) -> SCNMaterial {
        let material = SCNMaterial()
        
        // SIMPLIFIED FOR DEBUGGING: Use AppConfiguration color directly
        let selectedColor = color.uiColor
        
        // DEBUG: Log the actual color being used
        if let components = selectedColor.cgColor.components {
            print("🔵 VERTEX Material Color \(color): R=\(components[0]), G=\(components[1]), B=\(components[2])")
        }
        
        material.diffuse.contents = selectedColor
        material.emission.contents = selectedColor.withAlphaComponent(0.8)
        material.emission.intensity = 1.2
        return material
    }
}