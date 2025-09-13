import SwiftUI

struct TrialOverlayView: View {
    @EnvironmentObject var trialManager: TrialManager
    @State private var showPurchaseModal = false
    
    var body: some View {
        if trialManager.isTrialExpired && !trialManager.isPremium {
            VStack {
                // Top overlay message
                VStack(spacing: 12) {
                    Text("You are using a free version of the software")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("To remove this overlay, unlock the premium version for unlimited usage.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Button(action: { showPurchaseModal = true }) {
                        Text("Unlock Premium - $9.99")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white, Color.white.opacity(0.9)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
                .frame(maxWidth: 500)
                .background(
                    ZStack {
                        // Dark background
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.85))
                        
                        // Gradient border
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 10)
                .padding(.top, 100)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(true)
            .sheet(isPresented: $showPurchaseModal) {
                PurchaseView()
                    .environmentObject(trialManager)
            }
        }
    }
}