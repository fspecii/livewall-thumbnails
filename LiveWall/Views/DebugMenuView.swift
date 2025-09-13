import SwiftUI

struct DebugMenuView: View {
    @EnvironmentObject var trialManager: TrialManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Debug Menu")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.ultraThinMaterial)
            
            // Debug Options
            Form {
                Section("Trial Status") {
                    HStack {
                        Text("Current Status:")
                        Spacer()
                        Text(trialManager.trialStatusText)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Days Remaining:")
                        Spacer()
                        Text("\(trialManager.daysRemaining)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Premium Active:")
                        Spacer()
                        Image(systemName: trialManager.isPremium ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(trialManager.isPremium ? .green : .red)
                    }
                }
                
                Section("Debug Controls") {
                    Toggle("Debug Mode", isOn: Binding(
                        get: { trialManager.debugMode },
                        set: { _ in trialManager.toggleDebugMode() }
                    ))
                    
                    Button("Force Expire Trial") {
                        trialManager.forceExpireTrial()
                    }
                    .foregroundColor(.orange)
                    
                    Button("Reset Trial (Day 1)") {
                        trialManager.resetTrial()
                    }
                    .foregroundColor(.blue)
                    
                    Button("Unlock Premium (Debug)") {
                        trialManager.unlockPremiumDebug()
                    }
                    .foregroundColor(.green)
                    
                    Button("Clear All Data") {
                        clearAllData()
                    }
                    .foregroundColor(.red)
                }
                
                Section("Test Actions") {
                    Button("Show Purchase Modal") {
                        NotificationCenter.default.post(name: .showPurchaseModal, object: nil)
                        dismiss()
                    }
                    
                    Button("Refresh Trial Status") {
                        trialManager.checkTrialStatus()
                    }
                }
                
                Section("Information") {
                    HStack {
                        Text("First Launch Date:")
                        Spacer()
                        if let date = UserDefaults.standard.object(forKey: "LiveWall.FirstLaunchDate") as? Date {
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Not Set")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Build Version:")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 400, height: 500)
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    private func clearAllData() {
        let defaults = UserDefaults.standard
        let keys = [
            "LiveWall.FirstLaunchDate",
            "LiveWall.IsPremium",
            "LiveWall.DebugMode",
            "LiveWall.DebugTrialExpired",
            "LiveWall.HasPurchasedBefore"
        ]
        
        for key in keys {
            defaults.removeObject(forKey: key)
        }
        
        trialManager.resetTrial()
        print("🗑️ [DebugMenu] All data cleared")
    }
}

extension Notification.Name {
    static let showPurchaseModal = Notification.Name("showPurchaseModal")
    static let showDebugMenu = Notification.Name("showDebugMenu")
}