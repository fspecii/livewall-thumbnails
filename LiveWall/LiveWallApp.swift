import SwiftUI

@main
struct LiveWallApp: App {
    @StateObject private var dataService = GitHubDataService()
    @StateObject private var downloadManager = DownloadManager()
    @StateObject private var wallpaperManager = VideoWallpaperManager()
    @StateObject private var trialManager = TrialManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataService)
                .environmentObject(downloadManager)
                .environmentObject(wallpaperManager)
                .environmentObject(trialManager)
                .frame(minWidth: 1000, minHeight: 700)
                .onAppear {
                    Task {
                        await dataService.loadDatabase()
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .appInfo) {
                Divider()
                if trialManager.showPurchaseButton {
                    Button("Unlock Premium...") {
                        NotificationCenter.default.post(name: .showPurchaseModal, object: nil)
                    }
                    .keyboardShortcut("U", modifiers: [.command, .shift])
                }
                
                // Debug menu only in debug builds
                #if DEBUG
                Divider()
                Button("Debug Menu...") {
                    NotificationCenter.default.post(name: .showDebugMenu, object: nil)
                }
                .keyboardShortcut("D", modifiers: [.command, .shift, .option])
                #endif
            }
        }
    }
}

// Notification names are defined in DebugMenuView.swift