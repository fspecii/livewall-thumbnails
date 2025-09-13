import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataService: GitHubDataService
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var trialManager: TrialManager
    @State private var showPurchaseModal = false
    @State private var showDebugMenu = false
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
                .background(.ultraThinMaterial)
        } detail: {
            if dataService.selectedCategory.id == "downloads" {
                DownloadsView()
                    .background(.thinMaterial)
            } else {
                WallpaperGridView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onReceive(NotificationCenter.default.publisher(for: .showPurchaseModal)) { _ in
            showPurchaseModal = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showDebugMenu)) { _ in
            showDebugMenu = true
        }
        .sheet(isPresented: $showPurchaseModal) {
            PurchaseView()
                .environmentObject(trialManager)
        }
        .sheet(isPresented: $showDebugMenu) {
            DebugMenuView()
                .environmentObject(trialManager)
        }
    }
}