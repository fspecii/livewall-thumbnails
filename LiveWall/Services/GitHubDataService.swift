import Foundation
import SwiftUI

@MainActor
final class GitHubDataService: ObservableObject {
    @Published var database: WallpaperDatabase?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedCategory: Category = .all
    
    private let databaseURL = "https://fspecii.github.io/livewall-thumbnails/wallpapers_database.json"
    
    var allCategories: [Category] {
        var categories = [Category.all, Category.downloads]
        if let dbCategories = database?.categories {
            categories.append(contentsOf: dbCategories.sorted { $0.priority < $1.priority })
        }
        return categories
    }
    
    var filteredWallpapers: [Wallpaper] {
        guard let wallpapers = database?.wallpapers else { return [] }
        
        let filtered: [Wallpaper]
        switch selectedCategory.id {
        case "all":
            filtered = wallpapers
        case "downloads":
            return []
        default:
            filtered = wallpapers.filter { $0.categories?.contains(selectedCategory.id) ?? false }
        }
        
        // Apply daily shuffle to make content appear fresh
        return dailyShuffled(wallpapers: filtered)
    }
    
    private func dailyShuffled(wallpapers: [Wallpaper]) -> [Wallpaper] {
        guard !wallpapers.isEmpty else { return wallpapers }
        
        // Create a seed based on today's date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let todayString = dateFormatter.string(from: Date())
        let seed = todayString.hash
        
        // Use a seeded random generator for consistent daily shuffle
        var generator = SeededRandomNumberGenerator(seed: seed)
        var shuffled = wallpapers
        shuffled.shuffle(using: &generator)
        
        print("🔀 [GitHubDataService] Daily shuffle applied with seed: \(todayString)")
        return shuffled
    }
    
    func loadDatabase() async {
        isLoading = true
        error = nil
        
        print("📡 [GitHubDataService] Starting to load database from: \(databaseURL)")
        
        do {
            guard let url = URL(string: databaseURL) else {
                print("❌ [GitHubDataService] Invalid URL")
                throw URLError(.badURL)
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 [GitHubDataService] Response status: \(httpResponse.statusCode)")
                print("📦 [GitHubDataService] Data size: \(data.count) bytes")
            }
            
            let decoder = JSONDecoder()
            database = try decoder.decode(WallpaperDatabase.self, from: data)
            
            print("✅ [GitHubDataService] Successfully loaded database")
            print("   - Version: \(database?.version ?? "unknown")")
            print("   - Total wallpapers: \(database?.wallpapers.count ?? 0)")
            print("   - Categories: \(database?.categories.count ?? 0)")
            
            if let firstWallpaper = database?.wallpapers.first {
                print("   - First wallpaper: \(firstWallpaper.title) [\(firstWallpaper.id)]")
            }
            
        } catch {
            self.error = error
            print("❌ [GitHubDataService] Failed to load database: \(error)")
        }
        
        isLoading = false
    }
    
    func selectCategory(_ category: Category) {
        selectedCategory = category
    }
}

// Custom seeded random number generator for consistent shuffling
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: Int) {
        self.state = UInt64(abs(seed))
        // Mix the seed for better distribution
        state = state &* 6364136223846793005 &+ 1
    }
    
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1
        return state
    }
}