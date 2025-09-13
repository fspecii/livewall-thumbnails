# LiveWall Engine Architecture

## Overview
LiveWall Engine is a native macOS app that lets users browse a gallery of animated wallpapers, preview them, and set them as a live wallpaper. It pulls metadata and thumbnails from a GitHub Pages–hosted catalog and downloads videos from external sources (e.g., motionbgs.com). A lightweight “desktop window” video engine renders the selected wallpaper behind desktop icons.

## System Architecture

```
┌─────────────────────┐
│   GitHub Pages      │
│ (Static CDN Host)   │
├─────────────────────┤
│ • Database JSON     │
│ • Thumbnails        │
│ • Categories        │
└──────────┬──────────┘
           │
           ├─── HTTPS/JSON ──→ wallpapers_database.json
           │
           └─── HTTPS/Images → thumbnails/*.jpg
                     │
                     ↓
        ┌────────────────────────┐
        │    LiveWall macOS App   │
        ├────────────────────────┤
        │ • SwiftUI Interface     │
        │ • AVFoundation Player   │
        │ • Local Storage         │
        └────────────────────────┘
                     │
                     ↓
        ┌────────────────────────┐
        │   motionbgs.com API     │
        ├────────────────────────┤
        │ • Video Downloads       │
        │ • 4K/HD Quality         │
        └────────────────────────┘
```

## GitHub Repository Structure

### Repository: `fspecii/livewall-thumbnails`
Hosted at: https://fspecii.github.io/livewall-thumbnails/

```
livewall-thumbnails/
├── wallpapers_database.json    # Main database file
├── 6000.jpg                     # Thumbnail images
├── 6001.jpg                     # Named by wallpaper ID
├── 6002.jpg
└── ... (1000+ thumbnails)
```

### Database Structure (`wallpapers_database.json`)

```json
{
  "categories": [
    {
      "id": "anime",
      "name": "Anime",
      "icon": "🎌",
      "priority": 1
    },
    {
      "id": "gaming",
      "name": "Gaming",
      "icon": "🎮",
      "priority": 2
    }
    // ... more categories
  ],
  "wallpapers": [
    {
      "id": "6000",
      "title": "Manga Style Animation",
      "category": "anime",
      "tags": ["anime", "manga", "animation"],
      "thumbnail": "https://fspecii.github.io/livewall-thumbnails/6000.jpg",
      "url": "https://motionbgs.com/media/6000",
      "download_urls": {
        "4k": "https://motionbgs.com/dl/4k/6000",
        "hd": "https://motionbgs.com/dl/hd/6000"
      }
    }
    // ... 1000+ wallpapers
  ]
}
```

## Data Flow

### 1. Initial Load
```swift
// LocalDataService.swift
struct WallpaperDatabase: Decodable { /* categories, wallpapers */ }

@MainActor
final class LocalDataService: ObservableObject {
    @Published private(set) var cachedDatabase: WallpaperDatabase?

    func loadRemoteDatabase() async throws {
        let url = URL(string: "https://fspecii.github.io/livewall-thumbnails/wallpapers_database.json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let database = try JSONDecoder().decode(WallpaperDatabase.self, from: data)
        self.cachedDatabase = database
    }
}
```

### 2. Thumbnail Display
```swift
// ThumbnailView.swift
AsyncImage(url: URL(string: wallpaper.thumbnail)) { imagePhase in
    switch imagePhase {
    case .success(let image):
        image.resizable().aspectRatio(contentMode: .fill)
    case .failure(_):
        Color.gray.opacity(0.2)
    case .empty:
        ProgressView()
    @unknown default:
        Color.gray
    }
}
```

### 3. Video Preview (on hover)
```swift
// VideoPreviewView.swift
struct VideoPreviewView: View {
    var body: some View {
        if let localURL = downloadManager.getLocalURL(for: wallpaper) {
            // Show preview of downloaded video
            VideoPlayer(player: AVPlayer(url: localURL))
        } else {
            // Show static thumbnail (streaming disabled to prevent crashes)
            ThumbnailView(wallpaper: wallpaper)
        }
    }
}
```

### 4. Video Download
```swift
// DownloadManager.swift
final class DownloadManager {
    func download(_ wallpaper: Wallpaper, quality: String = "4k") async throws -> URL {
        guard let urlString = wallpaper.downloadURLs[quality], let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (tempURL, _) = try await URLSession.shared.download(from: url)
        let destination = downloadPath(for: wallpaper, quality: quality)

        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        // Replace if exists
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: tempURL, to: destination)
        return destination
    }

    private func downloadPath(for wallpaper: Wallpaper, quality: String) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "LiveWall/Downloads", directoryHint: .isDirectory)
        return base.appending(path: "\(wallpaper.id)_\(quality).mp4")
    }
}
```

## Live Wallpaper Engine

There is no public API to set a video file as the system desktop picture. Instead, LiveWall Engine creates a borderless, non-activating window per screen at desktop level and renders the video with AVFoundation. The window sits behind desktop icons, giving the effect of a live wallpaper.

### Desktop Window Strategy

Key characteristics:
- Window per screen, spanning the visible frame.
- Window level set to desktop level using `CGWindowLevelForKey`.
- Ignores mouse events and joins all Spaces, including fullscreen as auxiliary.
- Renders video via `AVPlayerLayer` (looped, muted by default).

```swift
// VideoWallpaperManager.swift
import AppKit
import AVFoundation

@MainActor
final class VideoWallpaperManager {
    private var windows: [NSScreen: NSWindow] = [:]
    private var players: [NSScreen: AVQueuePlayer] = [:]

    func setWallpaper(url: URL, mute: Bool = true) {
        for screen in NSScreen.screens {
            let window = windows[screen] ?? makeDesktopWindow(for: screen)
            windows[screen] = window

            let playerItem = AVPlayerItem(url: url)
            let player = players[screen] ?? AVQueuePlayer(items: [])
            players[screen] = player

            // loop
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { _ in
                player.seek(to: .zero)
                player.play()
            }

            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resizeAspectFill
            window.contentView?.wantsLayer = true
            window.contentView?.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
            window.contentView?.layer?.addSublayer(layer)
            layer.frame = window.contentView?.bounds ?? .zero

            player.removeAllItems()
            player.insert(playerItem, after: nil)
            player.isMuted = mute
            player.play()
        }
    }

    private func makeDesktopWindow(for screen: NSScreen) -> NSWindow {
        let frame = screen.frame
        let window = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false, screen: screen)
        window.isReleasedWhenClosed = false
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.backgroundColor = .black
        window.orderBack(nil)
        window.makeKeyAndOrderFront(nil)
        return window
    }
}
```

Notes:
- Behavior can vary by macOS version; testing across Sonoma/Sequoia recommended.
- Some systems require `.desktopIconWindow` level; adjust if icons appear above/below incorrectly.
- For best UX, run the engine even when the main app is closed (see “Background Helper”).

### File Storage Locations

```
~/Library/Application Support/LiveWall/
├── Downloads/           # Downloaded video files
│   ├── 6000_4k.mp4
│   ├── 6001_4k.mp4
│   └── ...
├── Cache/              # Temporary files
└── Preferences/        # User settings
```

## Category Distribution

Example distribution from the current dataset (subject to change):
- Anime, Gaming, Cars, Nature, Space, City, Fantasy, Superhero, Abstract
Special sets: Featured, Popular

## Performance Optimizations

### 1. Lazy Loading
- Page through results (e.g., 50 per page)
- Thumbnails on-demand via `AsyncImage`
- Debounced hover (e.g., 300–500 ms) before preview

### 2. Memory Management
```swift
// Proper cleanup in VideoPreviewView
private func cleanupPlayer() {
    player?.pause()
    player?.replaceCurrentItem(with: nil)
    
    if let observer = loopObserver {
        NotificationCenter.default.removeObserver(observer)
        loopObserver = nil
    }
    
    player = nil
}
```

### 3. Network Efficiency
- Single database fetch on app launch (with retry/backoff)
- Thumbnails cached by `AsyncImage`
- Consider resumable downloads with background sessions

### 4. Power Awareness
- Pause/stop playback on battery or low-power mode
- Throttle frame rate or reduce resolution when on battery

## Error Handling

### Network Failures
- Falls back to cached database if available
- Shows placeholder images for failed thumbnails
- Retry mechanisms for downloads

### Video Playback Issues
- Avoid raw streaming in previews to reduce crashes
- Prefer locally downloaded previews; otherwise, fall back to thumbnails
- Graceful degradation when codecs are unsupported

## Security Considerations

1. **HTTPS Only**: All resources served over HTTPS
2. **No Authentication**: Public resources, no sensitive data
3. **Local Storage**: Videos stored in app-specific directory
4. **Sandboxing**: App runs in macOS sandbox; enable outgoing connections
5. **Permissions**: No Accessibility or Screen Recording required for desktop window approach

## Background Helper (Optional)

To keep wallpapers running when the main window closes, ship a login item helper that starts at login and controls the engine.

Approach:
- Add a helper target and register with `SMAppService.loginItem`.
- Communicate via XPC or distributed notifications for play/pause/set.

```swift
import ServiceManagement

// Register at first launch
try? SMAppService.loginItem(identifier: "com.yourcompany.LiveWallHelper").register()
```

## Future Enhancements

1. **Progressive Web App**: Could add offline support
2. **P2P Sharing**: Users could share wallpapers directly
3. **Custom Categories**: User-defined organization
4. **Cloud Sync**: Sync preferences across devices
5. **Video Compression**: Optimize file sizes

## Troubleshooting

### Common Issues

1. **Videos not playing**
   - Check if video is downloaded first
   - Verify file exists in Downloads folder
   - Check console for AVPlayer errors

2. **Thumbnails not loading**
   - Verify internet connection
   - Check if GitHub Pages is accessible
   - Clear image cache if needed

3. **Wallpaper not setting**
   - Ensure app has necessary permissions
   - Check if video format is compatible
   - Try setting via System Preferences manually

## Development Setup

### Requirements
- macOS 14+
- Xcode 15+
- Swift 5.9+
- Internet connection for database/thumbnails

### Building
```bash
# SwiftPM (if configured)
swift build

# Xcode project
open livewallengine.xcodeproj
```

### Testing
```bash
swift test
```

## API Endpoints

### GitHub Pages (CDN)
- Database: `https://fspecii.github.io/livewall-thumbnails/wallpapers_database.json`
- Thumbnails: `https://fspecii.github.io/livewall-thumbnails/{id}.jpg`

### motionbgs.com (example)
- 4K Download: `https://motionbgs.com/dl/4k/{id}`
- HD Download: `https://motionbgs.com/dl/hd/{id}`
- Preview Page: `https://motionbgs.com/media/{id}`

---
Limitations: macOS provides no public API to set videos as the Desktop Picture. LiveWall Engine uses a desktop-level window to render behind icons. Behavior may vary by OS/version.

Last Updated: September 2025
Version: 1.1.0
