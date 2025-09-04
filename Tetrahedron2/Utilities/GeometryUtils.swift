import SceneKit
import UIKit
import Foundation

struct GeometryUtils {
    
    static func normalize(_ vector: SCNVector3) -> SCNVector3 {
        let length = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        guard length > 0 else { return vector }
        return SCNVector3(vector.x / length, vector.y / length, vector.z / length)
    }
    
    static func cross(_ a: SCNVector3, _ b: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            a.y * b.z - a.z * b.y,
            a.z * b.x - a.x * b.z,
            a.x * b.y - a.y * b.x
        )
    }
    
    static func createEdge(from: SCNVector3, to: SCNVector3) -> SCNNode {
        let distance = sqrt(pow(to.x - from.x, 2) + pow(to.y - from.y, 2) + pow(to.z - from.z, 2))
        
        // Create a single smooth cylinder with higher segment count for deformation
        let cylinder = SCNCylinder(radius: 0.01, height: CGFloat(distance))
        cylinder.heightSegmentCount = 32  // More segments for smooth deformation
        cylinder.radialSegmentCount = 12  // More segments around circumference
        
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
    
    static func createGradientImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [UIColor.black.cgColor, UIColor(red: 0, green: 0, blue: 0.1, alpha: 1).cgColor]
            let locations: [CGFloat] = [0, 1]
            
            guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) else {
                return
            }
            
            cgContext.drawRadialGradient(gradient,
                                       startCenter: CGPoint(x: 50, y: 50),
                                       startRadius: 0,
                                       endCenter: CGPoint(x: 50, y: 50),
                                       endRadius: 70,
                                       options: [])
        }
    }
}