import Foundation
import AVFoundation

class AudioManager: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying: Bool = false
    
    init() {
        setupAudioSession()
        setupAudioPlayer()
    }
    
    private func setupAudioSession() {
        do {
            // Use playback category for better device compatibility
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("Audio session setup successful - Category: playback, Options: mixWithOthers")
        } catch {
            print("Failed to setup audio session: \(error)")
            // Fallback to ambient if playback fails
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                print("Fallback audio session setup with ambient category")
            } catch {
                print("Fallback audio session also failed: \(error)")
            }
        }
    }
    
    private func setupAudioPlayer() {
        // Look for the audio file in the app bundle
        guard let url = Bundle.main.url(forResource: "meditation-music-409195", withExtension: "mp3") else {
            print("Could not find 'meditation-music-409195.mp3' in app bundle")
            print("Available bundle resources:")
            if let bundlePath = Bundle.main.resourcePath {
                let resourceContents = try? FileManager.default.contentsOfDirectory(atPath: bundlePath)
                resourceContents?.filter { $0.contains(".mp3") }.forEach { print("  - \($0)") }
            }
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = 0.4
            audioPlayer?.prepareToPlay()
            print("Audio player setup successful with file: \(url.lastPathComponent)")
        } catch {
            print("Could not create audio player: \(error)")
        }
    }
    
    func toggleMusic() {
        guard let player = audioPlayer else { return }
        
        if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
    
    func setMusicEnabled(_ enabled: Bool) {
        guard let player = audioPlayer else { return }
        
        if enabled && !player.isPlaying {
            player.play()
            isPlaying = true
        } else if !enabled && player.isPlaying {
            player.pause()
            isPlaying = false
        }
    }
}