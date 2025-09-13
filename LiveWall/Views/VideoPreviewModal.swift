import SwiftUI
import AVKit

struct VideoPreviewModal: View {
    let wallpaper: Wallpaper
    @Binding var isPresented: Bool
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var wallpaperManager: VideoWallpaperManager
    
    @State private var player: AVPlayer?
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    @State private var showError = false
    @State private var errorMessage = ""
    
    var isDownloaded: Bool {
        downloadManager.isDownloaded(wallpaper)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(wallpaper.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Label(wallpaper.primaryCategory.capitalized, systemImage: "folder")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let quality = wallpaper.quality {
                            Text("•")
                                .foregroundColor(.secondary)
                            Label(quality, systemImage: "sparkles")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.ultraThinMaterial)
            
            // Video Player or Thumbnail
            ZStack {
                if let player = player {
                    VideoPlayer(player: player)
                        .frame(height: 400)
                        .background(Color.black)
                        .cornerRadius(8)
                        .disabled(true) // Disable controls
                        .overlay(
                            // Invisible overlay to prevent control interaction
                            Color.clear
                                .allowsHitTesting(false)
                        )
                } else {
                    AsyncImage(url: URL(string: wallpaper.thumbnail)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure(_):
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.secondary)
                                        Text("Failed to load thumbnail")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                )
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(ProgressView())
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 400)
                    .background(Color.black)
                    
                    if !isDownloaded {
                        VStack {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                                .shadow(radius: 10)
                            Text("Download to preview")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.top, 8)
                        }
                    }
                }
                
                if isDownloading {
                    Rectangle()
                        .fill(Color.black.opacity(0.7))
                        .overlay(
                            VStack(spacing: 16) {
                                ProgressView(value: downloadProgress)
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .frame(width: 200)
                                
                                Text("Downloading... \(Int(downloadProgress * 100))%")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        )
                }
            }
            
            // Controls
            VStack(spacing: 16) {
                // Multi-Monitor Controls
                if wallpaperManager.availableScreens.count > 1 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Settings")
                            .font(.headline)
                        
                        Picker("Apply to:", selection: $wallpaperManager.screenMode) {
                            ForEach(VideoWallpaperManager.ScreenMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        if wallpaperManager.screenMode == .selectedScreens {
                            HStack {
                                ForEach(wallpaperManager.availableScreens) { screenInfo in
                                    Toggle(isOn: Binding(
                                        get: { wallpaperManager.selectedScreens.contains(screenInfo) },
                                        set: { isSelected in
                                            if isSelected {
                                                wallpaperManager.selectedScreens.insert(screenInfo)
                                            } else {
                                                wallpaperManager.selectedScreens.remove(screenInfo)
                                            }
                                        }
                                    )) {
                                        VStack(alignment: .leading) {
                                            Text("Screen \(screenInfo.index + 1)")
                                                .font(.caption)
                                            Text(screenInfo.name)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .toggleStyle(.checkbox)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Divider()
                    }
                }
                
                if wallpaper.downloadUrls != nil {
                    // Action Buttons
                    HStack(spacing: 12) {
                        if !isDownloaded {
                            Button(action: downloadVideo) {
                                Label("Download", systemImage: "arrow.down.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .controlSize(.large)
                            .buttonStyle(.borderedProminent)
                            .disabled(isDownloading)
                        }
                        
                        Button(action: setAsWallpaper) {
                            Label(isDownloaded ? "Set as Wallpaper" : "Download & Set", 
                                  systemImage: "photo.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .controlSize(.large)
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(isDownloading)
                        
                        if isDownloaded {
                            Button(action: deleteDownload) {
                                Label("Delete", systemImage: "trash")
                            }
                            .controlSize(.large)
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                } else {
                    Text("Download URLs not available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Tags
                if let tags = wallpaper.tags, !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
        }
        .frame(width: 700)
        .background(.thickMaterial)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .onAppear {
            loadPreview()
            print("🎬 [VideoPreviewModal] Opened for: \(wallpaper.title)")
            
            // Auto-download if not already downloaded
            if !isDownloaded && wallpaper.downloadUrls != nil {
                print("🔄 [VideoPreviewModal] Auto-downloading video...")
                downloadVideo()
            }
        }
        .onDisappear {
            cleanupPlayer()
            print("🎬 [VideoPreviewModal] Closed")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadPreview() {
        if let localURL = downloadManager.getLocalURL(for: wallpaper) {
            print("🎥 [VideoPreviewModal] Loading local video from: \(localURL)")
            player = AVPlayer(url: localURL)
            player?.isMuted = true
            player?.play()
            
            // Loop the video
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player?.currentItem,
                queue: .main
            ) { _ in
                player?.seek(to: .zero)
                player?.play()
            }
        } else {
            print("📷 [VideoPreviewModal] No local video, showing thumbnail")
        }
    }
    
    private func cleanupPlayer() {
        player?.pause()
        player = nil
    }
    
    private func downloadVideo() {
        Task {
            isDownloading = true
            downloadProgress = 0
            
            do {
                let localURL = try await downloadManager.download(wallpaper, quality: "4k") { progress in
                    DispatchQueue.main.async {
                        self.downloadProgress = progress
                    }
                }
                
                await MainActor.run {
                    isDownloading = false
                    loadPreview()
                }
                
                print("✅ [VideoPreviewModal] Download complete: \(localURL)")
            } catch {
                await MainActor.run {
                    isDownloading = false
                    errorMessage = "Failed to download: \(error.localizedDescription)"
                    showError = true
                }
                print("❌ [VideoPreviewModal] Download failed: \(error)")
            }
        }
    }
    
    private func setAsWallpaper() {
        Task {
            if !isDownloaded {
                isDownloading = true
                downloadProgress = 0
                
                do {
                    let localURL = try await downloadManager.download(wallpaper, quality: "4k") { progress in
                        DispatchQueue.main.async {
                            self.downloadProgress = progress
                        }
                    }
                    
                    await MainActor.run {
                        isDownloading = false
                        wallpaperManager.setWallpaper(url: localURL)
                        isPresented = false
                    }
                    
                    print("✅ [VideoPreviewModal] Downloaded and set as wallpaper")
                } catch {
                    await MainActor.run {
                        isDownloading = false
                        errorMessage = "Failed to download: \(error.localizedDescription)"
                        showError = true
                    }
                    print("❌ [VideoPreviewModal] Download failed: \(error)")
                }
            } else if let localURL = downloadManager.getLocalURL(for: wallpaper) {
                wallpaperManager.setWallpaper(url: localURL)
                isPresented = false
                print("✅ [VideoPreviewModal] Set as wallpaper: \(localURL)")
            }
        }
    }
    
    private func deleteDownload() {
        downloadManager.deleteDownload(wallpaper)
        cleanupPlayer()
        print("🗑️ [VideoPreviewModal] Deleted download for: \(wallpaper.id)")
    }
}