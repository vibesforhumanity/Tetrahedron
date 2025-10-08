import SwiftUI

struct ConfigurationBottomSheet: View {
    @ObservedObject var config: AppConfiguration
    @ObservedObject var audioManager: AudioManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Futuristic handle bar
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [config.selectedColor.color.opacity(0.8), config.selectedColor.color.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 40, height: 4)
                .padding(.top, 16)
                .padding(.bottom, 28)
            
            ScrollView {
                VStack(spacing: 36) {
                    // Shape Selection Section
                    VStack(spacing: 20) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(config.selectedColor.color.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "cube")
                                    .foregroundStyle(config.selectedColor.color)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            Text("GEOMETRY")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.9))
                                .tracking(1.2)
                            Spacer()
                        }
                        .padding(.horizontal, 28)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(ShapeType.allCases, id: \.self) { shape in
                                    FuturisticShapeButton(
                                        shape: shape,
                                        isSelected: config.selectedShape == shape,
                                        accentColor: config.selectedColor.color
                                    ) {
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                        impactFeedback.impactOccurred()
                                        
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8, blendDuration: 0.1)) {
                                            config.selectedShape = shape
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 28)
                        }
                    }
                    
                    // Color Selection Section
                    VStack(spacing: 20) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(config.selectedColor.color.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "circle.hexagongrid")
                                    .foregroundStyle(config.selectedColor.color)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            Text("SPECTRUM")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.9))
                                .tracking(1.2)
                            Spacer()
                        }
                        .padding(.horizontal, 28)
                        
                        HStack(spacing: 24) {
                            ForEach(NeonColor.allCases) { neonColor in
                                CircularColorButton(
                                    neonColor: neonColor,
                                    isSelected: config.selectedColor == neonColor
                                ) {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    
                                    // DEBUG: Log picker color selection
                                    if let components = neonColor.uiColor.cgColor.components {
                                        print("🟡 PICKER Selected Color \(neonColor): R=\(components[0]), G=\(components[1]), B=\(components[2])")
                                    }
                                    
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8, blendDuration: 0.1)) {
                                        config.selectedColor = neonColor
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 28)
                    }
                    
                    // Audio Section
                    VStack(spacing: 20) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(config.selectedColor.color.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: audioManager.isPlaying ? "waveform" : "waveform.slash")
                                    .foregroundStyle(config.selectedColor.color)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            Text("AUDIO")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.9))
                                .tracking(1.2)
                            Spacer()
                        }
                        .padding(.horizontal, 28)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("AMBIENT_SYNTHESIS")
                                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.95))
                                Text("// atmospheric.loop")
                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            
                            Spacer()
                            
                            FuturisticToggle(
                                isOn: Binding(
                                    get: { config.isMusicEnabled },
                                    set: { newValue in
                                        config.isMusicEnabled = newValue
                                        audioManager.setMusicEnabled(newValue)
                                    }
                                ),
                                accentColor: config.selectedColor.color
                            )
                        }
                        .padding(.horizontal, 28)
                    }
                    
                    // Haptic Controls Section
                    hapticControlsSection

                    // Share Section
                    shareSection
                }
                .padding(.bottom, 50)
            }
        }
        .background(
            ZStack {
                // Dark base
                Color.black.opacity(0.95)
                
                // Subtle grid pattern
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.02),
                        Color.clear,
                        Color.white.opacity(0.01)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Accent glow
                RadialGradient(
                    colors: [
                        config.selectedColor.color.opacity(0.05),
                        Color.clear
                    ],
                    center: .topTrailing,
                    startRadius: 50,
                    endRadius: 200
                )
            }
        )
        .overlay(
            // Border glow
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            config.selectedColor.color.opacity(0.3),
                            Color.white.opacity(0.1),
                            config.selectedColor.color.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var hapticControlsSection: some View {
        VStack(spacing: 20) {
            HStack {
                ZStack {
                    Circle()
                        .fill(config.selectedColor.color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "iphone.radiowaves.left.and.right")
                        .foregroundStyle(config.selectedColor.color)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text("HAPTIC TUNING")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                    .tracking(1.2)
                Spacer()
            }
            .padding(.horizontal, 28)

            VStack(spacing: 16) {
                // Intensity Control
                HapticSlider(
                    title: "INTENSITY",
                    value: $config.hapticIntensity,
                    range: 0.1...1.0,
                    accentColor: config.selectedColor.color
                )

                // Duration Control (in milliseconds)
                HapticSlider(
                    title: "DURATION_MS",
                    value: $config.hapticDuration,
                    range: 100.0...2000.0,
                    accentColor: config.selectedColor.color
                )

                // Frequency Control
                HapticSlider(
                    title: "FREQUENCY",
                    value: $config.hapticFrequency,
                    range: 5.0...100.0,
                    accentColor: config.selectedColor.color
                )

                // Sharpness Control
                HapticSlider(
                    title: "SHARPNESS",
                    value: $config.hapticSharpness,
                    range: 0.0...1.0,
                    accentColor: config.selectedColor.color
                )
            }
            .padding(.horizontal, 28)
        }
    }

    private var shareSection: some View {
        VStack(spacing: 20) {
            HStack {
                ZStack {
                    Circle()
                        .fill(config.selectedColor.color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(config.selectedColor.color)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text("SHARE")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                    .tracking(1.2)
                Spacer()
            }
            .padding(.horizontal, 28)
            
            shareButton
                .padding(.horizontal, 28)
        }
    }
    
    private var shareButton: some View {
        Button(action: shareApp) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SHARE APP")
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.95))
                    Text("Tell friends about Tetrahedron")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(config.selectedColor.color.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(config.selectedColor.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private func shareApp() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // First dismiss the current sheet
        config.showConfigSheet = false
        
        // Add a small delay to let the sheet dismiss, then show share sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let appStoreURL = "https://apps.apple.com/app/tetrahedron2/id123456789"
            let shareText = "Check out Tetrahedron2! 🔺✨"
            
            let activityVC = UIActivityViewController(
                activityItems: [shareText, URL(string: appStoreURL)!],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                // For iPad, set up popover
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = window
                    popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                rootViewController.present(activityVC, animated: true)
            }
        }
    }
}

struct FuturisticShapeButton: View {
    let shape: ShapeType
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Main container - reduced size to prevent overflow
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: isSelected ? 
                                        [accentColor.opacity(0.15), accentColor.opacity(0.05)] :
                                        [Color.white.opacity(0.05), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? 
                                    LinearGradient(
                                        colors: [accentColor.opacity(0.8), accentColor.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                lineWidth: isSelected ? 1.5 : 0.5
                            )
                    )
                    .frame(width: 78, height: 78) // Reduced from 84x84 to prevent overflow
                
                // Shape icon
                VStack(spacing: 6) {
                    Text(shape.icon)
                        .font(.system(size: 26, weight: .medium, design: .rounded))
                        .foregroundStyle(isSelected ? accentColor : Color.white.opacity(0.9))
                    
                    Text(shape.name.uppercased())
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(isSelected ? accentColor.opacity(0.9) : Color.white.opacity(0.6))
                        .tracking(0.5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7) // Allow text to scale down if needed
                }
                
                // Background glow - positioned behind main container
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accentColor.opacity(0.15))
                        .blur(radius: 6)
                        .scaleEffect(1.05)
                        .zIndex(-1) // Behind main content
                }
            }
        }
        .frame(width: 80, height: 86) // Container frame to prevent overflow
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .scaleEffect(isSelected ? 1.02 : 1.0) // Reduced scale effect
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
        .onTapGesture(perform: action)
    }
}

struct CircularColorButton: View {
    let neonColor: NeonColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        ZStack {
            // Outer glow ring when selected
            if isSelected {
                Circle()
                    .stroke(neonColor.color.opacity(0.6), lineWidth: 3)
                    .frame(width: 52, height: 52)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .opacity(isSelected ? 1 : 0)
            }
            
            // Main color circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            neonColor.color,
                            neonColor.color.opacity(0.8)
                        ],
                        center: .topLeading,
                        startRadius: 5,
                        endRadius: 20
                    )
                )
                .onAppear {
                    // DEBUG: Log what the picker is displaying vs what materials use
                    if let uiComponents = neonColor.uiColor.cgColor.components {
                        print("🔶 PICKER UIColor \(neonColor): R=\(uiComponents[0]), G=\(uiComponents[1]), B=\(uiComponents[2])")
                    }
                    // Also check the SwiftUI Color being displayed
                    let uiColorFromSwiftUI = UIColor(neonColor.color)
                    if let swiftUIComponents = uiColorFromSwiftUI.cgColor.components {
                        print("🔶 PICKER SwiftUI Color \(neonColor): R=\(swiftUIComponents[0]), G=\(swiftUIComponents[1]), B=\(swiftUIComponents[2])")
                    }
                }
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(
                            Color.white.opacity(isSelected ? 0.6 : 0.2),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(
                    color: neonColor.color.opacity(isSelected ? 0.4 : 0.2),
                    radius: isSelected ? 8 : 4
                )
        }
        .contentShape(Circle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
        .onTapGesture(perform: action)
    }
}

struct FuturisticToggle: View {
    @Binding var isOn: Bool
    let accentColor: Color
    
    var body: some View {
        ZStack {
            // Background track
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: isOn ? 
                            [accentColor.opacity(0.8), accentColor.opacity(0.6)] :
                            [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 64, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isOn ? accentColor.opacity(0.4) : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
            
            // Sliding knob
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white, Color.white.opacity(0.9)],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 12
                    )
                )
                .frame(width: 26, height: 26)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                .offset(x: isOn ? 16 : -16)
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isOn)
        }
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            isOn.toggle()
        }
    }
}

struct HapticSlider: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let accentColor: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                    .tracking(0.5)

                Spacer()

                Text(String(format: "%.2f", value))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(accentColor)
                    .frame(width: 45, alignment: .trailing)
            }

            HStack {
                Slider(value: Binding(
                    get: { value },
                    set: { newValue in
                        value = newValue
                        // Provide immediate haptic feedback when adjusting
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                ), in: range)
                .accentColor(accentColor)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

