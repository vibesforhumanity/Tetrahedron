//
//  Tetrahedron2Tests.swift
//  Tetrahedron2Tests
//
//  Created by Emily Zakas on 8/16/25.
//

import Testing
import SceneKit
@testable import Tetrahedron2

struct Tetrahedron2Tests {

    @Test func testAppConfigurationInitialization() async throws {
        let config = AppConfiguration()
        #expect(config.selectedShape == .tetrahedron)
        #expect(config.selectedColor == .cyan)
        #expect(config.isMusicEnabled == false)
        #expect(config.showConfigSheet == false)
    }
    
    @Test func testShapeTypeProperties() async throws {
        let tetrahedron = ShapeType.tetrahedron
        #expect(tetrahedron.name == "Tetrahedron")
        #expect(tetrahedron.icon == "▲")
        
        let cube = ShapeType.cube
        #expect(cube.name == "Cube")
        #expect(cube.icon == "◻︎")
        
        let octahedron = ShapeType.octahedron
        #expect(octahedron.name == "Octahedron")
        #expect(octahedron.icon == "◆")
    }
    
    @Test func testNeonColorProperties() async throws {
        let cyan = NeonColor.cyan
        #expect(cyan.rawValue == "Cyan")
        
        let magenta = NeonColor.magenta
        #expect(magenta.rawValue == "Magenta")
        
        let yellow = NeonColor.yellow
        #expect(yellow.rawValue == "Electric Yellow")
    }
    
    @Test func testShapeGeneratorVerticesAndEdges() async throws {
        let (tetrahedronVertices, tetrahedronEdges) = ShapeGenerator.getVerticesAndEdges(for: .tetrahedron)
        #expect(tetrahedronVertices.count == 4)
        #expect(tetrahedronEdges.count == 6)
        
        let (cubeVertices, cubeEdges) = ShapeGenerator.getVerticesAndEdges(for: .cube)
        #expect(cubeVertices.count == 8)
        #expect(cubeEdges.count == 12)
        
        let (octahedronVertices, octahedronEdges) = ShapeGenerator.getVerticesAndEdges(for: .octahedron)
        #expect(octahedronVertices.count == 6)
        #expect(octahedronEdges.count == 12)
    }
    
    @Test func testGeometryUtilsNormalization() async throws {
        let vector = SCNVector3(3, 4, 0)
        let normalized = GeometryUtils.normalize(vector)
        
        // Check that normalized vector has magnitude 1
        let magnitude = sqrt(normalized.x * normalized.x + normalized.y * normalized.y + normalized.z * normalized.z)
        #expect(abs(magnitude - 1.0) < 0.001)
    }
    
    @Test func testGeometryUtilsCrossProduct() async throws {
        let a = SCNVector3(1, 0, 0)
        let b = SCNVector3(0, 1, 0)
        let cross = GeometryUtils.cross(a, b)
        
        #expect(abs(cross.x - 0) < 0.001)
        #expect(abs(cross.y - 0) < 0.001)
        #expect(abs(cross.z - 1) < 0.001)
    }
    
    @Test func testEdgeCreation() async throws {
        let from = SCNVector3(0, 0, 0)
        let to = SCNVector3(1, 0, 0)
        let edgeNode = GeometryUtils.createEdge(from: from, to: to)
        
        #expect(edgeNode.geometry is SCNCylinder)
        
        if let cylinder = edgeNode.geometry as? SCNCylinder {
            #expect(abs(cylinder.height - 1.0) < 0.001)
            #expect(abs(cylinder.radius - 0.01) < 0.001)
        }
    }

}
