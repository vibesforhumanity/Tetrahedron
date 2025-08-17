import SwiftUI

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