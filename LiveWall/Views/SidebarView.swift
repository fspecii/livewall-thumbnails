import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var dataService: GitHubDataService
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var trialManager: TrialManager
    @State private var showPurchaseModal = false
    
    var body: some View {
        List(selection: Binding(
            get: { dataService.selectedCategory },
            set: { dataService.selectCategory($0) }
        )) {
            Section {
                ForEach(dataService.allCategories.filter { $0.priority <= 0 }) { category in
                    Label {
                        HStack {
                            Text(category.name)
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            if category.id == "downloads" {
                                Text("\(downloadManager.downloadedWallpapers.count)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        ZStack {
                                            Capsule()
                                                .fill(Color.accentColor)
                                            Capsule()
                                                .fill(.regularMaterial)
                                                .opacity(0.2)
                                        }
                                    )
                                    .shadow(color: Color.accentColor.opacity(0.3), radius: 3, x: 0, y: 1)
                            }
                        }
                    } icon: {
                        Text(category.icon)
                            .font(.system(size: 15))
                    }
                    .tag(category)
                }
            } header: {
                Text("Library")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            
            // Premium Upgrade Button - Always visible when trial expired
            if trialManager.showPurchaseButton {
                Section {
                    Button(action: { showPurchaseModal = true }) {
                        HStack {
                            ZStack {
                                // Animated gradient background
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 1.0, green: 0.84, blue: 0.0),
                                                Color(red: 1.0, green: 0.65, blue: 0.0),
                                                Color(red: 1.0, green: 0.5, blue: 0.0)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .orange.opacity(0.4), radius: 4, x: 0, y: 2)
                                
                                // Pulsing glow effect
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.yellow.opacity(0.6), .orange.opacity(0.6)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            }
                            .frame(height: 40)
                            .overlay(
                                HStack(spacing: 8) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                                    
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text("UNLOCK PREMIUM")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("Remove overlay • $9.99")
                                            .font(.system(size: 10))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.horizontal, 12)
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, -8)
                }
            }
            
            if dataService.allCategories.filter({ $0.priority > 0 }).count > 0 {
                Section {
                    ForEach(dataService.allCategories.filter { $0.priority > 0 }) { category in
                        Label {
                            Text(category.name)
                                .font(.system(size: 13, weight: .medium))
                        } icon: {
                            Text(category.icon)
                                .font(.system(size: 15))
                        }
                        .tag(category)
                    }
                } header: {
                    Text("Categories")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }
            }
        }
        .listStyle(SidebarListStyle())
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        .navigationTitle("LiveWall")
        .sheet(isPresented: $showPurchaseModal) {
            PurchaseView()
                .environmentObject(trialManager)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    Task {
                        await dataService.loadDatabase()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .symbolRenderingMode(.hierarchical)
                }
                .disabled(dataService.isLoading)
                .help("Refresh wallpapers")
            }
        }
    }
}