import Foundation

struct Wallpaper: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let categories: [String]?
    let tags: [String]?
    let thumbnail: String
    let url: String
    let quality: String?
    let downloadUrls: DownloadURLs?
    let index: Int?
    let dateAdded: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, categories, tags, thumbnail, url, quality, downloadUrls, index, dateAdded
    }
    
    struct DownloadURLs: Codable, Hashable {
        let fourK: String?
        let hd: String?
        
        enum CodingKeys: String, CodingKey {
            case fourK = "4k"
            case hd = "hd"
        }
    }
    
    var primaryCategory: String {
        return categories?.first ?? "uncategorized"
    }
}

struct WallpaperDatabase: Codable {
    let version: String?
    let lastUpdated: String?
    let totalWallpapers: Int?
    let categories: [Category]
    let wallpapers: [Wallpaper]
}