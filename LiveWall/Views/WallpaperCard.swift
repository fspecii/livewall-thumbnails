import SwiftUI
import AVKit

struct WallpaperCard: View {
    let wallpaper: Wallpaper
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var wallpaperManager: VideoWallpaperManager
    
    @State private var isHovering = false
    @State private var showModal = false
    @State private var hoverPlayer: AVPlayer?
    @State private var showVideoPreview = false
    
    var isDownloaded: Bool {
        downloadManager.isDownloaded(wallpaper)
    }
    
    // Clean title by removing #number pattern
    var cleanTitle: String {
        let title = wallpaper.title
        // Remove patterns like #123 from the title
        let pattern = #"\s*#\d+\s*"#
        return title.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: { showModal = true }) {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack {
                        AsyncImage(url: URL(string: wallpaper.thumbnail)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(16/9, contentMode: .fill)
                            case .failure(_):
                                Rectangle()
                                    .fill(Color.gray.opacity(0.15))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 32))
                                            .foregroundColor(Color.secondary.opacity(0.3))
                                            .symbolRenderingMode(.hierarchical)
                                    )
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .overlay(
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .controlSize(.small)
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(height: geometry.size.width * 9/16) // Responsive 16:9 aspect ratio
                        .clipped()
                    
                        // Clean video preview overlay
                        if showVideoPreview, let player = hoverPlayer {
                            VideoPlayer(player: player)
                                .frame(height: geometry.size.width * 9/16)
                                .disabled(true)
                                .allowsHitTesting(false)
                                .transition(.opacity)
                                .overlay(
                                    // Hide controls with invisible overlay
                                    Color.clear
                                        .allowsHitTesting(false)
                                )
                        }
                    
                        // Download indicator with backdrop
                        VStack {
                            HStack {
                                Spacer()
                                if isDownloaded {
                                    ZStack {
                                        Circle()
                                            .fill(.regularMaterial)
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.green)
                                            .symbolRenderingMode(.multicolor)
                                    }
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    .padding(8)
                                }
                            }
                            Spacer()
                        }
                    
                        if isHovering {
                            ZStack {
                                // Dark gradient overlay for better contrast
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.black.opacity(0.7),
                                                Color.black.opacity(0.4)
                                            ]),
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                
                                // Blur material for depth
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.3)
                                
                                // Play button with backdrop
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(.regularMaterial)
                                            .frame(width: 56, height: 56)
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 44))
                                            .foregroundColor(.white)
                                            .symbolRenderingMode(.hierarchical)
                                    }
                                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                                    
                                    Text("Preview")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(6)
                                }
                            }
                            .transition(.opacity)
                        }
                    }
            
                    HStack(spacing: 6) {
                        Text(wallpaper.primaryCategory.capitalized)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Optional: Add a small quality indicator
                        if wallpaper.downloadUrls?.fourK != nil {
                            Text("4K")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.6))
                                )
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        // Enhanced translucent bottom section with blur
                        ZStack {
                            Rectangle()
                                .fill(.regularMaterial)
                            Rectangle()
                                .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                        }
                    )
                }
            }
            .buttonStyle(PlainButtonStyle())
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .background(
                // Multi-layer translucent card background
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .scaleEffect(isHovering ? 1.03 : 1.0)
            .onHover { hovering in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isHovering = hovering
                }
                
                if hovering {
                    startVideoPreview()
                } else {
                    stopVideoPreview()
                }
            }
            .sheet(isPresented: $showModal) {
                VideoPreviewModal(wallpaper: wallpaper, isPresented: $showModal)
                    .environmentObject(downloadManager)
                    .environmentObject(wallpaperManager)
            }
        }
        .aspectRatio(240.0/200.0, contentMode: .fit)
    }
    
    private func startVideoPreview() {
        // Check if video is downloaded
        guard let localURL = downloadManager.getLocalURL(for: wallpaper) else {
            print("🎥 [WallpaperCard] No local video for preview, triggering download...")
            // Auto-download in background for preview
            Task {
                do {
                    let _ = try await downloadManager.download(wallpaper, quality: "4k") { _ in }
                    // After download, try preview again if still hovering
                    if isHovering {
                        startVideoPreview()
                    }
                } catch {
                    print("❌ [WallpaperCard] Failed to download for preview: \(error)")
                }
            }
            return
        }
        
        // Delay slightly to avoid preview on quick hover
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if isHovering {
                print("🎥 [WallpaperCard] Starting video preview for: \(wallpaper.id)")
                hoverPlayer = AVPlayer(url: localURL)
                hoverPlayer?.isMuted = true
                hoverPlayer?.play()
                
                // Loop the video
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: hoverPlayer?.currentItem,
                    queue: .main
                ) { _ in
                    hoverPlayer?.seek(to: .zero)
                    hoverPlayer?.play()
                }
                
                withAnimation(.easeIn(duration: 0.3)) {
                    showVideoPreview = true
                }
            }
        }
    }
    
    private func stopVideoPreview() {
        print("🎥 [WallpaperCard] Stopping video preview")
        withAnimation(.easeOut(duration: 0.2)) {
            showVideoPreview = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            hoverPlayer?.pause()
            hoverPlayer = nil
        }
    }
}