import AppKit
import AVFoundation
import SwiftUI
import QuartzCore

// Wrapper to make NSScreen hashable
struct ScreenInfo: Hashable, Identifiable {
    let screen: NSScreen
    let id: String
    let name: String
    let index: Int
    
    init(screen: NSScreen, index: Int) {
        self.screen = screen
        self.index = index
        if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] {
            self.id = "\(screenNumber)"
        } else {
            self.id = "\(index)"
        }
        self.name = screen.localizedName ?? "Display \(index + 1)"
    }
    
    static func == (lhs: ScreenInfo, rhs: ScreenInfo) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@MainActor
final class VideoWallpaperManager: ObservableObject {
    @Published var isPlaying = false
    @Published var currentWallpaperURL: URL?
    @Published var availableScreens: [ScreenInfo] = []
    @Published var selectedScreens: Set<ScreenInfo> = []
    @Published var screenMode: ScreenMode = .allScreens
    
    enum ScreenMode: String, CaseIterable {
        case allScreens = "All Screens"
        case mainScreen = "Main Screen Only"
        case selectedScreens = "Selected Screens"
    }
    
    // Use string IDs as keys to avoid screen object comparison issues
    private var windows: [String: NSWindow] = [:]
    private var players: [String: AVQueuePlayer] = [:]
    private var playerLayers: [String: AVPlayerLayer] = [:]
    private var loopObservers: [String: Any] = [:]
    
    // UserDefaults keys for persistence
    private let wallpaperURLKey = "LiveWall.LastWallpaperURL"
    private let screenModeKey = "LiveWall.ScreenMode"
    private let selectedScreensKey = "LiveWall.SelectedScreens"
    private let autoRestoreKey = "LiveWall.AutoRestore"
    
    init() {
        updateAvailableScreens()
        setupScreenChangeNotifications()
        restoreLastWallpaper()
    }
    
    private func screenID(for screen: NSScreen) -> String {
        if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
            return "screen_\(screenNumber)"
        }
        return "screen_\(screen.hash)"
    }
    
    private func setupScreenChangeNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    private func updateAvailableScreens() {
        availableScreens = NSScreen.screens.enumerated().map { index, screen in
            ScreenInfo(screen: screen, index: index)
        }
        // By default, select all screens
        if selectedScreens.isEmpty {
            selectedScreens = Set(availableScreens)
        }
        print("🖥️ [VideoWallpaperManager] Available screens updated: \(availableScreens.count) screen(s)")
        for info in availableScreens {
            print("   - Screen \(info.index + 1): \(info.name) - \(info.screen.frame.size)")
        }
    }
    
    func setWallpaper(url: URL, muted: Bool = true) {
        print("🖼️ [VideoWallpaperManager] Setting wallpaper from: \(url.lastPathComponent)")
        print("   - Screen mode: \(screenMode.rawValue)")
        
        stopAllWallpapers()
        currentWallpaperURL = url
        
        // Save settings for restoration
        saveWallpaperSettings()
        
        // Determine which screens to set wallpaper on
        let screensToUse: [NSScreen]
        switch screenMode {
        case .allScreens:
            screensToUse = NSScreen.screens
            print("   - Setting on all \(screensToUse.count) screen(s)")
        case .mainScreen:
            screensToUse = NSScreen.main != nil ? [NSScreen.main!] : []
            print("   - Setting on main screen only")
        case .selectedScreens:
            screensToUse = selectedScreens.map { $0.screen }
            print("   - Setting on \(screensToUse.count) selected screen(s)")
        }
        
        print("📺 [VideoWallpaperManager] Total screens to setup: \(screensToUse.count)")
        
        for (index, screen) in screensToUse.enumerated() {
            print("   - [\(index + 1)/\(screensToUse.count)] Setting up screen: \(screen.localizedName ?? "Unknown")")
            print("     Frame: \(screen.frame)")
            print("     Main screen: \(screen == NSScreen.main ? "Yes" : "No")")
            
            let window = getOrCreateWindow(for: screen)
            let player = AVQueuePlayer()
            let playerItem = AVPlayerItem(url: url)
            
            player.insert(playerItem, after: nil)
            player.isMuted = muted
            player.actionAtItemEnd = .none
            
            let loopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { [weak player] _ in
                player?.seek(to: .zero)
                player?.play()
            }
            
            let id = screenID(for: screen)
            loopObservers[id] = loopObserver
            
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resizeAspectFill
            
            if let contentView = window.contentView {
                contentView.wantsLayer = true
                
                // Remove any existing sublayers
                contentView.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
                
                // Set the player layer frame to match content view bounds
                playerLayer.frame = contentView.bounds
                playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
                
                // Add the player layer
                contentView.layer?.addSublayer(playerLayer)
                
                print("   - Added player layer with frame: \(playerLayer.frame)")
            }
            
            players[id] = player
            playerLayers[id] = playerLayer
            
            player.play()
            print("   - Started playback on screen")
        }
        
        isPlaying = true
        
        // Verify setup
        print("✅ [VideoWallpaperManager] Setup complete:")
        print("   - Windows created: \(windows.count)")
        print("   - Players active: \(players.count)")
        print("   - Layers added: \(playerLayers.count)")
        
        // Add trial overlays to all screens if trial is expired
        checkAndShowTrialOverlay()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    func stopAllWallpapers() {
        print("🛑 [VideoWallpaperManager] Stopping all wallpapers")
        
        // Stop and clean up players
        for (screen, player) in players {
            player.pause()
            player.removeAllItems()
            
            if let observer = loopObservers[screen] {
                NotificationCenter.default.removeObserver(observer)
            }
        }
        
        // Remove layers
        for (_, layer) in playerLayers {
            layer.removeFromSuperlayer()
        }
        
        // Hide windows but don't close them (reuse for better performance)
        for (_, window) in windows {
            window.orderOut(nil)
        }
        
        players.removeAll()
        playerLayers.removeAll()
        loopObservers.removeAll()
        
        isPlaying = false
        currentWallpaperURL = nil
    }
    
    func pausePlayback() {
        for (_, player) in players {
            player.pause()
        }
        isPlaying = false
    }
    
    func resumePlayback() {
        for (_, player) in players {
            player.play()
        }
        isPlaying = true
    }
    
    private func getOrCreateWindow(for screen: NSScreen) -> NSWindow {
        let id = screenID(for: screen)
        if let existingWindow = windows[id] {
            print("🪟 [VideoWallpaperManager] Reusing existing window for screen ID: \(id)")
            // Make sure the window is visible
            existingWindow.orderBack(nil)
            existingWindow.makeKeyAndOrderFront(nil)
            return existingWindow
        }
        
        let window = createDesktopWindow(for: screen)
        windows[id] = window
        return window
    }
    
    private func createDesktopWindow(for screen: NSScreen) -> NSWindow {
        let frame = screen.frame
        let screenName = screen.localizedName ?? "Unknown"
        let screenIndex = NSScreen.screens.firstIndex(of: screen) ?? 0
        print("🪟 [VideoWallpaperManager] Creating window for screen \(screenIndex + 1): \(screenName)")
        
        let window = NSWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        window.isReleasedWhenClosed = false
        
        // Try different window levels for desktop
        let desktopLevel = CGWindowLevelForKey(.desktopWindow)
        window.level = NSWindow.Level(rawValue: Int(desktopLevel - 1))
        
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.backgroundColor = .black
        window.isOpaque = true
        window.hasShadow = false
        window.animationBehavior = .none
        
        // Create content view that fills the screen
        let contentView = NSView(frame: NSRect(origin: .zero, size: frame.size))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.black.cgColor
        window.contentView = contentView
        
        // Set the window frame explicitly
        window.setFrame(frame, display: true)
        
        // Make window visible on the specific screen
        window.orderBack(nil)
        
        print("   - Window frame: \(window.frame)")
        print("   - Successfully created window for: \(screenName)")
        
        return window
    }
    
    private var overlayWindows: [String: NSWindow] = [:]
    private var overlayLayers: [String: CATextLayer] = [:]
    
    private func addTrialOverlayIfNeeded(for screen: NSScreen) {
        // Check if trial is expired
        let trialManager = TrialManager()
        guard trialManager.isTrialExpired && !trialManager.isPremium else { return }
        
        let id = screenID(for: screen)
        
        // Don't add duplicate overlays
        if overlayWindows[id] != nil {
            return
        }
        
        // Create overlay window at a higher level to ensure visibility
        let overlayWindow = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        overlayWindow.isReleasedWhenClosed = false
        overlayWindow.backgroundColor = .clear
        overlayWindow.isOpaque = false
        overlayWindow.ignoresMouseEvents = true
        // Set higher window level to ensure it's above the wallpaper
        overlayWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow) + 1))
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        // Create overlay view with colorful annoying design
        let overlayView = TrialOverlayNSView(frame: NSRect(origin: .zero, size: screen.frame.size))
        overlayWindow.contentView = overlayView
        
        overlayWindow.orderFront(nil)
        overlayWindows[id] = overlayWindow
        
        print("⚠️ [VideoWallpaperManager] Trial overlay added to screen: \(screen.localizedName ?? "Unknown")")
    }
    
    private func checkAndShowTrialOverlay() {
        // Add overlay to ALL screens when trial is expired
        let trialManager = TrialManager()
        guard trialManager.isTrialExpired && !trialManager.isPremium else { return }
        
        // Show overlay on ALL available screens
        for screen in NSScreen.screens {
            addTrialOverlayIfNeeded(for: screen)
        }
        
        print("🚨 [VideoWallpaperManager] Trial overlays added to \(NSScreen.screens.count) screen(s)")
    }
    
    @MainActor
    func removeTrialOverlays() {
        for (_, window) in overlayWindows {
            window.orderOut(nil)
            window.close()
        }
        overlayWindows.removeAll()
        print("✅ [VideoWallpaperManager] Trial overlays removed")
    }
    
    @objc private func screensDidChange() {
        print("🖥️ [VideoWallpaperManager] Screen configuration changed")
        updateAvailableScreens()
        
        if let url = currentWallpaperURL, isPlaying {
            print("   - Reapplying wallpaper to new screen configuration")
            setWallpaper(url: url)
        }
    }
    
    // MARK: - Persistence Methods
    
    private func saveWallpaperSettings() {
        let defaults = UserDefaults.standard
        
        // Save wallpaper URL
        if let url = currentWallpaperURL {
            defaults.set(url.absoluteString, forKey: wallpaperURLKey)
            print("💾 [VideoWallpaperManager] Saved wallpaper URL: \(url.lastPathComponent)")
        }
        
        // Save screen mode
        defaults.set(screenMode.rawValue, forKey: screenModeKey)
        
        // Save selected screens (as array of screen IDs)
        let selectedScreenIDs = selectedScreens.map { $0.id }
        defaults.set(selectedScreenIDs, forKey: selectedScreensKey)
        
        // Enable auto-restore
        defaults.set(true, forKey: autoRestoreKey)
        
        print("💾 [VideoWallpaperManager] Settings saved for restoration")
    }
    
    private func restoreLastWallpaper() {
        let defaults = UserDefaults.standard
        
        // Check if auto-restore is enabled
        guard defaults.bool(forKey: autoRestoreKey) else {
            print("🔄 [VideoWallpaperManager] Auto-restore disabled")
            return
        }
        
        // Restore screen mode
        if let modeString = defaults.string(forKey: screenModeKey),
           let mode = ScreenMode(rawValue: modeString) {
            screenMode = mode
            print("🔄 [VideoWallpaperManager] Restored screen mode: \(mode.rawValue)")
        }
        
        // Restore selected screens
        if let savedScreenIDs = defaults.array(forKey: selectedScreensKey) as? [String] {
            let restoredScreens = availableScreens.filter { savedScreenIDs.contains($0.id) }
            if !restoredScreens.isEmpty {
                selectedScreens = Set(restoredScreens)
                print("🔄 [VideoWallpaperManager] Restored \(restoredScreens.count) selected screen(s)")
            }
        }
        
        // Restore wallpaper URL and set it
        if let urlString = defaults.string(forKey: wallpaperURLKey),
           let url = URL(string: urlString),
           FileManager.default.fileExists(atPath: url.path) {
            print("🔄 [VideoWallpaperManager] Restoring wallpaper: \(url.lastPathComponent)")
            
            // Delay slightly to ensure UI is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.setWallpaper(url: url)
            }
        } else {
            print("🔄 [VideoWallpaperManager] No wallpaper to restore or file not found")
        }
    }
    
    func clearSavedSettings() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: wallpaperURLKey)
        defaults.removeObject(forKey: screenModeKey)
        defaults.removeObject(forKey: selectedScreensKey)
        defaults.removeObject(forKey: autoRestoreKey)
        print("🗑️ [VideoWallpaperManager] Cleared saved settings")
    }
    
    deinit {
        for (screen, player) in players {
            player.pause()
            player.removeAllItems()
            
            if let observer = loopObservers[screen] {
                NotificationCenter.default.removeObserver(observer)
            }
        }
        
        for (_, layer) in playerLayers {
            layer.removeFromSuperlayer()
        }
        
        for (_, window) in windows {
            window.close()
        }
        
        NotificationCenter.default.removeObserver(self)
    }
}