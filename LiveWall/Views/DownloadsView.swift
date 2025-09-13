import SwiftUI

struct DownloadsView: View {
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var wallpaperManager: VideoWallpaperManager
    @EnvironmentObject var dataService: GitHubDataService
    
    let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 20)
    ]
    
    private var downloadedWallpapers: [Wallpaper] {
        guard let allWallpapers = dataService.database?.wallpapers else { return [] }
        
        return allWallpapers.filter { wallpaper in
            downloadManager.isDownloaded(wallpaper)
        }
    }
    
    var body: some View {
        ScrollView {
            if downloadedWallpapers.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No downloaded wallpapers")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Download wallpapers from the gallery to see them here")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Storage Used")
                                .font(.headline)
                            Text(String(format: "%.1f MB", downloadManager.downloadSizeInMB))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if wallpaperManager.isPlaying {
                            Button(action: {
                                wallpaperManager.stopAllWallpapers()
                            }) {
                                Label("Stop Wallpaper", systemImage: "stop.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(downloadedWallpapers) { wallpaper in
                            DownloadedWallpaperCard(wallpaper: wallpaper)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .navigationTitle("Downloads")
        .navigationSubtitle("\(downloadedWallpapers.count) wallpapers")
    }
}

struct DownloadedWallpaperCard: View {
    let wallpaper: Wallpaper
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var wallpaperManager: VideoWallpaperManager
    
    @State private var isHovering = false
    
    private var isActive: Bool {
        guard let currentURL = wallpaperManager.currentWallpaperURL,
              let localURL = downloadManager.getLocalURL(for: wallpaper) else {
            return false
        }
        return currentURL == localURL
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                AsyncImage(url: URL(string: wallpaper.thumbnail)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                    case .failure(_), .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 150)
                .clipped()
                
                if isActive {
                    Rectangle()
                        .fill(Color.green.opacity(0.3))
                        .overlay(
                            VStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                                Text("Active")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        )
                }
                
                if isHovering && !isActive {
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .overlay(
                            HStack(spacing: 20) {
                                Button(action: {
                                    if let localURL = downloadManager.getLocalURL(for: wallpaper) {
                                        wallpaperManager.setWallpaper(url: localURL)
                                    }
                                }) {
                                    VStack {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 30))
                                        Text("Set")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.white)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    downloadManager.deleteDownload(wallpaper)
                                }) {
                                    VStack {
                                        Image(systemName: "trash.circle.fill")
                                            .font(.system(size: 30))
                                        Text("Delete")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.red)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        )
                        .transition(.opacity)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(wallpaper.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                HStack {
                    Text(wallpaper.primaryCategory.capitalized)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let localURL = downloadManager.getLocalURL(for: wallpaper) {
                        let quality = localURL.lastPathComponent.contains("4k") ? "4K" : "HD"
                        Text(quality)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? Color.green : Color.clear, lineWidth: 2)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}