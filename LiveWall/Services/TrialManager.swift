import Foundation
import SwiftUI
import StoreKit

@MainActor
final class TrialManager: ObservableObject {
    @Published var isTrialExpired = false
    @Published var isPremium = false
    @Published var daysRemaining = 7
    @Published var showPurchaseButton = false
    @Published var debugMode = false
    
    private let trialDurationDays = 7
    private let premiumPrice = "$9.99"
    private let productID = "com.livewall.premium"
    
    // UserDefaults keys
    private let firstLaunchDateKey = "LiveWall.FirstLaunchDate"
    private let isPremiumKey = "LiveWall.IsPremium"
    private let debugModeKey = "LiveWall.DebugMode"
    private let debugTrialExpiredKey = "LiveWall.DebugTrialExpired"
    
    init() {
        loadTrialStatus()
        checkTrialStatus()
    }
    
    private func loadTrialStatus() {
        let defaults = UserDefaults.standard
        
        // Check if premium was purchased
        isPremium = defaults.bool(forKey: isPremiumKey)
        
        // Load debug mode
        debugMode = defaults.bool(forKey: debugModeKey)
        
        // Set first launch date if not exists
        if defaults.object(forKey: firstLaunchDateKey) == nil {
            defaults.set(Date(), forKey: firstLaunchDateKey)
            print("🎁 [TrialManager] First launch detected. Starting 7-day trial.")
        }
    }
    
    func checkTrialStatus() {
        let defaults = UserDefaults.standard
        
        // If premium, no need to check trial
        if isPremium {
            isTrialExpired = false
            showPurchaseButton = false
            print("✨ [TrialManager] Premium version active")
            return
        }
        
        // Check debug override
        if debugMode && defaults.bool(forKey: debugTrialExpiredKey) {
            isTrialExpired = true
            showPurchaseButton = true
            daysRemaining = 0
            print("🐛 [TrialManager] Debug: Trial forcefully expired")
            return
        }
        
        // Calculate days since first launch
        guard let firstLaunchDate = defaults.object(forKey: firstLaunchDateKey) as? Date else {
            return
        }
        
        let daysSinceFirstLaunch = Calendar.current.dateComponents([.day], from: firstLaunchDate, to: Date()).day ?? 0
        daysRemaining = max(0, trialDurationDays - daysSinceFirstLaunch)
        
        if daysSinceFirstLaunch >= trialDurationDays {
            isTrialExpired = true
            showPurchaseButton = true
            print("⏰ [TrialManager] Trial period expired (Day \(daysSinceFirstLaunch + 1))")
        } else {
            isTrialExpired = false
            showPurchaseButton = false
            print("📅 [TrialManager] Trial active: \(daysRemaining) days remaining")
        }
    }
    
    func purchasePremium() async {
        print("💳 [TrialManager] Starting purchase flow for \(premiumPrice)")
        
        // Simulate purchase process
        // In production, this would use StoreKit
        do {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Mark as premium
            UserDefaults.standard.set(true, forKey: isPremiumKey)
            isPremium = true
            isTrialExpired = false
            showPurchaseButton = false
            
            print("✅ [TrialManager] Premium purchase successful!")
        } catch {
            print("❌ [TrialManager] Purchase failed: \(error)")
        }
    }
    
    func restorePurchases() async {
        print("🔄 [TrialManager] Restoring purchases...")
        
        // Simulate restore process
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Check if user has purchased before
            // In production, this would check with StoreKit
            let hasPurchased = UserDefaults.standard.bool(forKey: "LiveWall.HasPurchasedBefore")
            
            if hasPurchased {
                UserDefaults.standard.set(true, forKey: isPremiumKey)
                isPremium = true
                isTrialExpired = false
                showPurchaseButton = false
                print("✅ [TrialManager] Purchases restored successfully!")
            } else {
                print("ℹ️ [TrialManager] No purchases to restore")
            }
        } catch {
            print("❌ [TrialManager] Restore failed: \(error)")
        }
    }
    
    // MARK: - Debug Functions
    
    func toggleDebugMode() {
        debugMode.toggle()
        UserDefaults.standard.set(debugMode, forKey: debugModeKey)
        print("🐛 [TrialManager] Debug mode: \(debugMode ? "ON" : "OFF")")
    }
    
    func forceExpireTrial() {
        UserDefaults.standard.set(true, forKey: debugTrialExpiredKey)
        checkTrialStatus()
        print("🐛 [TrialManager] Trial forcefully expired")
    }
    
    func resetTrial() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: firstLaunchDateKey)
        defaults.removeObject(forKey: isPremiumKey)
        defaults.removeObject(forKey: debugTrialExpiredKey)
        defaults.set(Date(), forKey: firstLaunchDateKey)
        
        isPremium = false
        isTrialExpired = false
        showPurchaseButton = false
        daysRemaining = trialDurationDays
        
        print("🔄 [TrialManager] Trial reset to day 1")
    }
    
    func unlockPremiumDebug() {
        UserDefaults.standard.set(true, forKey: isPremiumKey)
        isPremium = true
        isTrialExpired = false
        showPurchaseButton = false
        print("🐛 [TrialManager] Premium unlocked via debug")
    }
    
    var trialStatusText: String {
        if isPremium {
            return "Premium Version"
        } else if isTrialExpired {
            return "Trial Expired"
        } else {
            return "Trial: \(daysRemaining) days left"
        }
    }
}