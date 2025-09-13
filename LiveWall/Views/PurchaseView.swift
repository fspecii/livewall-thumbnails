import SwiftUI

struct PurchaseView: View {
    @EnvironmentObject var trialManager: TrialManager
    @Environment(\.dismiss) var dismiss
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var selectedPlan = "lifetime"
    @State private var showSuccessAnimation = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.1, blue: 0.3),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(8)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        // Hero Section
                        VStack(spacing: 20) {
                            // Animated Icon
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.blue.opacity(0.3),
                                                Color.purple.opacity(0.3)
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .blur(radius: 20)
                                
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.yellow, .orange],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: .yellow.opacity(0.5), radius: 10)
                            }
                            .scaleEffect(showSuccessAnimation ? 1.2 : 1.0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showSuccessAnimation)
                            
                            VStack(spacing: 10) {
                                Text("Upgrade to Premium")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Remove all limitations and unlock the full experience")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Urgency Banner
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("Limited Time Offer - 50% OFF!")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [.orange.opacity(0.3), .red.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.orange.opacity(0.5), lineWidth: 1)
                                )
                        )
                        
                        // Pricing Card
                        VStack(spacing: 0) {
                            // Price section with strikethrough
                            VStack(spacing: 15) {
                                // Badge
                                Text("BEST VALUE")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(LinearGradient(
                                                colors: [.green, .mint],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ))
                                    )
                                
                                // Price
                                VStack(spacing: 5) {
                                    Text("$19.99")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.white.opacity(0.5))
                                        .strikethrough(color: .red)
                                    
                                    HStack(alignment: .top, spacing: 4) {
                                        Text("$")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white.opacity(0.9))
                                            .offset(y: 8)
                                        Text("9")
                                            .font(.system(size: 60, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("99")
                                            .font(.system(size: 36, weight: .bold))
                                            .foregroundColor(.white)
                                            .offset(y: 8)
                                    }
                                    
                                    Text("One-time payment")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                // Benefits
                                VStack(alignment: .leading, spacing: 15) {
                                    FeatureCheckmark(text: "Remove annoying overlay forever")
                                    FeatureCheckmark(text: "Unlimited HD & 4K wallpapers")
                                    FeatureCheckmark(text: "Multi-monitor support")
                                    FeatureCheckmark(text: "Lifetime updates included")
                                    FeatureCheckmark(text: "Priority customer support")
                                }
                                .padding(.top, 20)
                            }
                            .padding(25)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.3),
                                                        Color.white.opacity(0.1)
                                                    ],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Social Proof
                        VStack(spacing: 15) {
                            HStack(spacing: 4) {
                                ForEach(0..<5) { _ in
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 18))
                                }
                            }
                            
                            Text("Trusted by 10,000+ users")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            HStack(spacing: 20) {
                                UserTestimonial(name: "John D.", text: "Best purchase ever!")
                                UserTestimonial(name: "Sarah M.", text: "Worth every penny")
                                UserTestimonial(name: "Mike R.", text: "Amazing quality")
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // CTA Buttons
                        VStack(spacing: 12) {
                            Button(action: purchase) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.2, green: 0.6, blue: 1.0),
                                                    Color(red: 0.5, green: 0.3, blue: 1.0)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color.blue.opacity(0.4), radius: 10, y: 5)
                                    
                                    if isPurchasing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .scaleEffect(0.9)
                                            .tint(.white)
                                            .frame(width: 20, height: 20)
                                    } else {
                                        VStack(spacing: 4) {
                                            Text("Unlock Premium Now")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.white)
                                            Text("Instant activation • Secure payment")
                                                .font(.system(size: 11))
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                    }
                                }
                                .frame(height: 60)
                            }
                            .buttonStyle(.plain)
                            .disabled(isPurchasing || isRestoring)
                            .scaleEffect(isPurchasing ? 0.98 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isPurchasing)
                            
                            Button(action: restore) {
                                HStack {
                                    if isRestoring {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .scaleEffect(0.7)
                                            .tint(.white)
                                            .frame(width: 16, height: 16)
                                    } else {
                                        Text("Restore Previous Purchase")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                                .frame(height: 40)
                            }
                            .buttonStyle(.plain)
                            .disabled(isPurchasing || isRestoring)
                        }
                        .padding(.horizontal, 20)
                        
                        // Trust Badges
                        HStack(spacing: 30) {
                            TrustBadge(icon: "lock.shield.fill", text: "Secure")
                            TrustBadge(icon: "checkmark.shield.fill", text: "Verified")
                            TrustBadge(icon: "arrow.triangle.2.circlepath", text: "Instant")
                        }
                        .padding(.top, 10)
                        
                        // Money Back Guarantee
                        VStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.green)
                            
                            Text("30-Day Money Back Guarantee")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Not satisfied? Get a full refund, no questions asked")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.green.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .strokeBorder(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                        
                        // Footer
                        VStack(spacing: 10) {
                            Text("Payments are secure and encrypted")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                            
                            HStack(spacing: 20) {
                                Button("Privacy Policy") {
                                    NSWorkspace.shared.open(URL(string: "https://livewall.app/privacy")!)
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.white.opacity(0.5))
                                .font(.system(size: 11))
                                
                                Text("•")
                                    .foregroundColor(.white.opacity(0.3))
                                
                                Button("Terms of Service") {
                                    NSWorkspace.shared.open(URL(string: "https://livewall.app/terms")!)
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.white.opacity(0.5))
                                .font(.system(size: 11))
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .frame(width: 480, height: 750)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    private func purchase() {
        isPurchasing = true
        Task {
            await trialManager.purchasePremium()
            isPurchasing = false
            showSuccessAnimation = true
            
            // Show success then dismiss
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            dismiss()
        }
    }
    
    private func restore() {
        isRestoring = true
        Task {
            await trialManager.restorePurchases()
            isRestoring = false
            if trialManager.isPremium {
                showSuccessAnimation = true
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                dismiss()
            }
        }
    }
}

struct FeatureCheckmark: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
    }
}

struct UserTestimonial: View {
    let name: String
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
            Text("\"\(text)\"")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.5))
                .italic()
        }
    }
}

struct TrustBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.6))
            Text(text)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}