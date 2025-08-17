import SwiftUI

struct ContentView: View {
    @State private var selectedShape: ShapeType = .tetrahedron
    @State private var showShapeSelector = false
    
    var body: some View {
        ZStack {
            ShapeSceneView(selectedShape: $selectedShape)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                if showShapeSelector {
                    ShapeSelectorView(selectedShape: $selectedShape, showSelector: $showShapeSelector)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
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