import Foundation
import SwiftUI

@MainActor
final class DownloadManager: ObservableObject {
    @Published var downloadedWallpapers: [Wallpaper] = []
    @Published var activeDownloads: [String: Double] = [:]
    
    private let fileManager = FileManager.default
    private let appSupportURL: URL
    private let downloadsDirectory: URL
    
    init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        appSupportURL = appSupport.appendingPathComponent("LiveWall", isDirectory: true)
        downloadsDirectory = appSupportURL.appendingPathComponent("Downloads", isDirectory: true)
        
        createDirectories()
        loadDownloadedWallpapers()
    }
    
    private func createDirectories() {
        try? fileManager.createDirectory(at: downloadsDirectory, withIntermediateDirectories: true)
    }
    
    func getLocalURL(for wallpaper: Wallpaper) -> URL? {
        let fourKPath = downloadsDirectory.appendingPathComponent("\(wallpaper.id)_4k.mp4")
        let hdPath = downloadsDirectory.appendingPathComponent("\(wallpaper.id)_hd.mp4")
        
        // Prefer 4K if available
        if fileManager.fileExists(atPath: fourKPath.path) {
            return fourKPath
        } else if fileManager.fileExists(atPath: hdPath.path) {
            return hdPath
        }
        return nil
    }
    
    func isDownloaded(_ wallpaper: Wallpaper) -> Bool {
        return getLocalURL(for: wallpaper) != nil
    }
    
    func download(_ wallpaper: Wallpaper, quality: String = "hd", progressHandler: @escaping (Double) -> Void) async throws -> URL {
        print("⬇️ [DownloadManager] Starting download for: \(wallpaper.title) [\(wallpaper.id)]")
        print("   - Quality: \(quality)")
        
        guard let downloadUrls = wallpaper.downloadUrls else {
            print("❌ [DownloadManager] No download URLs available")
            throw URLError(.badURL)
        }
        
        let urlString: String?
        if quality == "4k" {
            urlString = downloadUrls.fourK ?? downloadUrls.hd
        } else {
            urlString = downloadUrls.hd ?? downloadUrls.fourK
        }
        
        guard let urlString = urlString, let url = URL(string: urlString) else {
            print("❌ [DownloadManager] Invalid download URL")
            throw URLError(.badURL)
        }
        
        print("🔗 [DownloadManager] Download URL: \(urlString)")
        
        let destinationURL = downloadsDirectory.appendingPathComponent("\(wallpaper.id)_\(quality).mp4")
        
        if fileManager.fileExists(atPath: destinationURL.path) {
            print("✅ [DownloadManager] File already exists at: \(destinationURL.path)")
            return destinationURL
        }
        
        activeDownloads[wallpaper.id] = 0
        
        // Add trailing slash if not present (motionbgs.com requires it)
        var finalURL = url
        if !url.path.hasSuffix("/") && url.path.contains("/dl/") {
            finalURL = URL(string: url.absoluteString + "/") ?? url
            print("🔄 [DownloadManager] Added trailing slash: \(finalURL)")
        }
        
        // Use URLSession download task which handles redirects automatically
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        
        do {
            let (tempURL, response) = try await session.download(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [DownloadManager] Invalid response type")
                activeDownloads.removeValue(forKey: wallpaper.id)
                throw URLError(.badServerResponse)
            }
            
            print("📊 [DownloadManager] Response status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                print("❌ [DownloadManager] Bad status code: \(httpResponse.statusCode)")
                activeDownloads.removeValue(forKey: wallpaper.id)
                throw URLError(.badServerResponse)
            }
            
            // Move the downloaded file to our destination
            try? fileManager.removeItem(at: destinationURL)
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            
            let fileSize = try fileManager.attributesOfItem(atPath: destinationURL.path)[.size] as? Int64 ?? 0
            
            print("✅ [DownloadManager] Download complete!")
            print("   - File saved to: \(destinationURL.path)")
            print("   - File size: \(fileSize / 1024 / 1024) MB")
            
            await MainActor.run {
                activeDownloads.removeValue(forKey: wallpaper.id)
                progressHandler(1.0)
                if !downloadedWallpapers.contains(where: { $0.id == wallpaper.id }) {
                    downloadedWallpapers.append(wallpaper)
                }
            }
            
            return destinationURL
            
        } catch {
            print("❌ [DownloadManager] Download failed: \(error)")
            await MainActor.run {
                activeDownloads.removeValue(forKey: wallpaper.id)
            }
            throw error
        }
    }
    
    func deleteDownload(_ wallpaper: Wallpaper) {
        let hdPath = downloadsDirectory.appendingPathComponent("\(wallpaper.id)_hd.mp4")
        let fourKPath = downloadsDirectory.appendingPathComponent("\(wallpaper.id)_4k.mp4")
        
        try? fileManager.removeItem(at: hdPath)
        try? fileManager.removeItem(at: fourKPath)
        
        downloadedWallpapers.removeAll { $0.id == wallpaper.id }
    }
    
    func loadDownloadedWallpapers() {
        downloadedWallpapers.removeAll()
        
        guard let files = try? fileManager.contentsOfDirectory(at: downloadsDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        
        // Get unique wallpaper IDs from downloaded files
        let wallpaperIds = Set(files.compactMap { url -> String? in
            let filename = url.lastPathComponent
            if filename.hasSuffix("_hd.mp4") {
                return String(filename.dropLast(7))
            } else if filename.hasSuffix("_4k.mp4") {
                return String(filename.dropLast(7))
            }
            return nil
        })
        
        print("📥 [DownloadManager] Found \(wallpaperIds.count) downloaded wallpaper(s)")
    }
    
    var downloadSizeInMB: Double {
        let files = try? fileManager.contentsOfDirectory(at: downloadsDirectory, includingPropertiesForKeys: [.fileSizeKey])
        let totalBytes = files?.compactMap { url -> Int64? in
            let values = try? url.resourceValues(forKeys: [.fileSizeKey])
            return values?.fileSize.map { Int64($0) }
        }.reduce(0, +) ?? 0
        
        return Double(totalBytes) / 1024 / 1024
    }
}