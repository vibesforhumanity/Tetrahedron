import SwiftUI
import Foundation

class AppConfiguration: ObservableObject {
    @Published var selectedShape: ShapeType = .tetrahedron
    @Published var selectedColor: NeonColor = .cyan
    @Published var isMusicEnabled: Bool = false
    @Published var isHapticsEnabled: Bool = true
    @Published var showConfigSheet: Bool = false

    // Internal haptic parameters (not exposed to UI)
    let hapticIntensity: Float = 0.7
    let hapticFrequency: Float = 20.0
    let hapticSharpness: Float = 0.2
}

enum NeonColor: String, CaseIterable, Identifiable {
    case cyan = "Cyan"
    case magenta = "Magenta"  
    case yellow = "Electric Yellow"
    case green = "Neon Green"
    case orange = "Vivid Orange"
    case purple = "Electric Purple"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .cyan:
            return Color(.sRGB, red: 0.0, green: 1.0, blue: 1.0, opacity: 1.0)
        case .magenta:
            return Color(.sRGB, red: 1.0, green: 0.0, blue: 1.0, opacity: 1.0)
        case .yellow:
            return Color(.sRGB, red: 1.0, green: 1.0, blue: 0.0, opacity: 1.0)
        case .green:
            return Color(.sRGB, red: 0.0, green: 1.0, blue: 0.0, opacity: 1.0)
        case .orange:
            return Color(.sRGB, red: 1.0, green: 0.4, blue: 0.0, opacity: 1.0) // Restored vibrant orange
        case .purple:
            return Color(.sRGB, red: 0.3, green: 0.0, blue: 1.0, opacity: 1.0) // Even more blue
        }
    }
    
    var uiColor: UIColor {
        switch self {
        case .cyan:
            return UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
        case .magenta:
            return UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0)
        case .yellow:
            return UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
        case .green:
            return UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
        case .orange:
            return UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0) // Restored vibrant orange
        case .purple:
            return UIColor(red: 0.3, green: 0.0, blue: 1.0, alpha: 1.0) // Even more blue
        }
    }
}