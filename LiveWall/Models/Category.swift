import Foundation

struct Category: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let priority: Int
    
    static let all = Category(id: "all", name: "All", icon: "🌟", priority: 0)
    static let downloads = Category(id: "downloads", name: "Downloads", icon: "⬇️", priority: -1)
}