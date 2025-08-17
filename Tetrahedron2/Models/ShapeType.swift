import Foundation

enum ShapeType: CaseIterable {
    case tetrahedron
    case cube
    case octahedron
    case icosahedron
    
    var name: String {
        switch self {
        case .tetrahedron: return "Tetrahedron"
        case .cube: return "Cube"
        case .octahedron: return "Octahedron"
        case .icosahedron: return "Icosahedron"
        }
    }
    
    var icon: String {
        switch self {
        case .tetrahedron: return "▲"
        case .cube: return "◻︎"
        case .octahedron: return "◆"
        case .icosahedron: return "◉"
        }
    }
}