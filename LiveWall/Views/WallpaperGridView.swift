import SwiftUI

struct WallpaperGridView: View {
    @EnvironmentObject var dataService: GitHubDataService
    @EnvironmentObject var downloadManager: DownloadManager
    
    // Responsive grid that adapts to window size
    let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 16, alignment: .top)
    ]
    
    var body: some View {
        ZStack {
            // Base gradient background for depth
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(NSColor.windowBackgroundColor).opacity(0.6),
                    Color(NSColor.windowBackgroundColor).opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Translucent material overlay
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.7)
                .ignoresSafeArea()
            
            ScrollView {
                if dataService.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .controlSize(.large)
                            .scaleEffect(1.2)
                            .tint(.accentColor)
                        Text("Loading wallpapers...")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(.regularMaterial)
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else if dataService.filteredWallpapers.isEmpty {
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(.regularMaterial)
                                .frame(width: 120, height: 120)
                            Image(systemName: "photo.stack")
                                .font(.system(size: 56))
                                .foregroundColor(.secondary)
                                .symbolRenderingMode(.hierarchical)
                        }
                        VStack(spacing: 8) {
                            Text("No wallpapers available")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text("Select a different category from the sidebar")
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 16)
                        .background(.regularMaterial)
                        .cornerRadius(12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(dataService.filteredWallpapers) { wallpaper in
                            WallpaperCard(wallpaper: wallpaper)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle(dataService.selectedCategory.name)
        .navigationSubtitle("\(dataService.filteredWallpapers.count) wallpapers")
    }
}