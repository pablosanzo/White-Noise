import AppKit
import AVFoundation

@available(macOS 10.15, *)
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var player: AVPlayer?
    var currentCategory: String?
    private var lastPlayedSound: URL?
    private var currentSoundItem: NSMenuItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()
    }
    
    func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if statusItem.button != nil {
            updateStatusIcon(isPlaying: false)
        }
        
        let menu = NSMenu()
        
        // Add sound categories with submenus
        for category in ["Naturescapes", "Noise Masking", "Tranquilities"] {
            let categoryItem = NSMenuItem(title: category, action: nil, keyEquivalent: "")
            let submenu = NSMenu()
            
            if let sounds = soundDict[category] {
            for soundURL in sounds {
                let rawName = URL(string: soundURL)?.deletingPathExtension().lastPathComponent ?? "Sound"
                let cleanName = rawName
                    .replacingOccurrences(of: "bosexx_", with: "")
                    .replacingOccurrences(of: "nscp", with: "")
                    .replacingOccurrences(of: "msk", with: "")
                    .replacingOccurrences(of: "trn_", with: "")
                    .replacingOccurrences(of: "SBII_Sound_", with: "")
                    .replacingOccurrences(of: "_", with: " ")
                    .replacingOccurrences(of: "-", with: " ")
                    .replacingOccurrences(of: "  ", with: " ") // Remove double spaces
                    .trimmingCharacters(in: .whitespaces)
                    .capitalized
                let item = NSMenuItem(title: cleanName, action: #selector(selectSound(_:)), keyEquivalent: "")
                item.representedObject = soundURL
                item.target = self
                submenu.addItem(item)
            }
            }
            
            categoryItem.submenu = submenu
            menu.addItem(categoryItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Add volume slider
        let volumeItem = NSMenuItem()
        let volumeView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 30))
        let volumeSlider = NSSlider(frame: NSRect(x: 20, y: 5, width: 160, height: 20))
        volumeSlider.minValue = 0.0
        volumeSlider.maxValue = 1.0
        volumeSlider.floatValue = 1.0
        volumeSlider.target = self
        volumeSlider.action = #selector(volumeChanged(_:))
        volumeView.addSubview(volumeSlider)
        volumeItem.view = volumeView
        menu.addItem(volumeItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Add control item
        let pauseItem = NSMenuItem(title: "Pause", action: #selector(togglePlayback(_:)), keyEquivalent: "")
        pauseItem.target = self
        pauseItem.isEnabled = false
        menu.addItem(pauseItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit item
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc func selectSound(_ sender: NSMenuItem) {
        guard let soundURL = sender.representedObject as? String,
              let url = URL(string: soundURL) else { return }
        
        playSound(url: url)
    }
    
    func stopPlayback() {
        player?.pause()
        player = nil
    }
    
    func playSound(url: URL) {
        stopPlayback()
        
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        lastPlayedSound = url
        
        // Set up looping
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
        
        player?.play()
        
        // Enable seamless looping
        player?.actionAtItemEnd = .none
        
        // Update UI
        updateStatusIcon(isPlaying: true)
        updateCurrentSoundItem(url: url)
        updatePauseMenuItem(isPlaying: true)
    }
    
    func updateStatusIcon(isPlaying: Bool) {
        if let button = statusItem.button {
            if #available(macOS 11.0, *) {
                button.image = NSImage(systemSymbolName: isPlaying ? "speaker.wave.3.fill" : "speaker.wave.3", accessibilityDescription: "White Noise")
            } else {
                if let image = NSImage(named: NSImage.Name(isPlaying ? "NSSpeakerFill" : "NSSpeaker")) {
                    button.image = image
                } else {
                    button.image = NSImage(named: NSImage.Name("NSBonjour"))
                }
            }
        }
    }
    
    func updateCurrentSoundItem(url: URL) {
        // Clear previous selection
        currentSoundItem?.state = .off
        
        // Find and mark new selection
        if let menu = statusItem.menu {
            for item in menu.items {
                if let submenu = item.submenu {
                    for subItem in submenu.items {
                        if let soundURL = subItem.representedObject as? String,
                           soundURL == url.absoluteString {
                            subItem.state = .on
                            currentSoundItem = subItem
                            return
                        }
                    }
                }
            }
        }
    }
    
    func updatePauseMenuItem(isPlaying: Bool) {
        if let menu = statusItem.menu {
            for item in menu.items {
                if item.action == #selector(togglePlayback(_:)) {
                    item.isEnabled = isPlaying
                    item.title = isPlaying ? "Pause" : "Pause"
                    return
                }
            }
        }
    }
    
    @objc func playerItemDidReachEnd(notification: Notification) {
        guard let item = notification.object as? AVPlayerItem else { return }
        item.seek(to: .zero, completionHandler: nil)
    }
    
    @objc func volumeChanged(_ sender: NSSlider) {
        player?.volume = sender.floatValue
    }
    
    @objc func togglePlayback(_ sender: NSMenuItem) {
        guard let player = player else { return }
        
        if player.rate > 0 {
            player.pause()
            updateStatusIcon(isPlaying: false)
            updatePauseMenuItem(isPlaying: false)
        } else {
            if player.currentItem != nil {
                player.play()
                updateStatusIcon(isPlaying: true)
                updatePauseMenuItem(isPlaying: true)
            } else if let lastSound = lastPlayedSound {
                playSound(url: lastSound)
            }
        }
    }
    
    // MARK: - Properties
    private var soundDict: [String: [String]] = [
        "Naturescapes": [
            "https://sleepsounds-demo.bose.com/audio/bosexx_nscp_Alpine-Powder.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_nscp_Country-Road.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_nscp_HideAway.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_nscp_Marina.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_nscp_Portal.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_nscp_Rainforest.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_nscp_Shoreline.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_nscp_Songbird_1.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_nscp_Squall.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_nscp_Tumble-Dry.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_nscp_Tundra.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_nscp_Windswept.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_nscp-canvas-rain.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_nscp-island-hop.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_nscp-railway.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_nscp-simmer.mp3",
            "https://sleepsounds-demo.bose.com/audio/SBII_Sound_nscp-Boardwalk.mp3",
            "https://sleepsounds-demo.bose.com/audio/SBII_Sound_nscp-Outbound.mp3",
            "https://sleepsounds-demo.bose.com/audio/SBII_Sound_nscp-Starboard.mp3",
            "https://sleepsounds-demo.bose.com/audio/SBII_Sound_nscp-Windowseat.mp3"
        ],
        "Noise Masking": [
            "https://sleepsounds-demo.bose.com/audio/bosexx_msk_Altitude.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_msk_campfire.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_msk_Cascade_Waterfall.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_msk_Circulate-Dehumidifier.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_msk_Crosswind.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_msk_Downstream.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_msk_Elements.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_msk_Frost.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_msk_Mist.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_msk_Rumble.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_msk_Sand.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_msk_Shower.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_msk_Undercurrent.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_msk_WhiteOut.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_msk-engine-room.mp3",
            "https://sleepsounds-demo.bose.com/audio/SBII_Sound_msk-Rinse.mp3",
            "https://sleepsounds-demo.bose.com/audio/SBII_Sound_msk-Rustle.mp3",
            "https://sleepsounds-demo.bose.com/audio/SBII_Sound_msk-Swell_Ocean.mp3",
            "https://sleepsounds-demo.bose.com/audio/SBII_Sound_msk-Warm_Static.mp3"
        ],
        "Tranquilities": [
            "https://sleepsounds-demo.bose.com/audio/bosexx_trn_Afterglow.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_trn_Ambient.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_trn_Calm.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_trn_Candlelight.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_trn_Chill.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_trn_Cozy.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_trn_Dreamscape.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_trn_Ethereal.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_trn_Harmony.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_trn_Lullaby.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_trn_Meditation.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_trn_Peaceful.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_trn_Relaxation.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_trn_Serenity.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_trn_Sleep.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_trn_Snooze.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_trn_Tranquil.mp3",
            "https://sleepsounds-demo.bose.com/audio/bosexx_trn_Zen.mp3"
        ]
    ]
}

// Setup and run the application
let app = NSApplication.shared
if #available(macOS 11.0, *) {
    let delegate = AppDelegate()
    app.delegate = delegate
}
app.run()
