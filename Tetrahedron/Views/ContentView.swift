import SwiftUI

struct ContentView: View {
    @StateObject private var config = AppConfiguration()
    @StateObject private var audioManager = AudioManager()
    
    var body: some View {
        ZStack {
            ShapeSceneView(selectedShape: $config.selectedShape, selectedColor: config.selectedColor)
                .ignoresSafeArea()
                .onTapGesture {
                    if config.showConfigSheet {
                        // If sheet is open, close it
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            config.showConfigSheet = false
                        }
                    } else {
                        // If sheet is closed, open it
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            config.showConfigSheet = true
                        }
                    }
                }
        }
        .statusBar(hidden: true)
        .sheet(isPresented: $config.showConfigSheet) {
            ConfigurationBottomSheet(config: config, audioManager: audioManager)
                .presentationDetents([.fraction(0.6), .large])
                .presentationDragIndicator(.hidden)
                .presentationBackground(.regularMaterial)
                .presentationBackgroundInteraction(.enabled)
        }
    }
}