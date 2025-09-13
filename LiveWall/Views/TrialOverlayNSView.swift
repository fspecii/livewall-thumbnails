import AppKit
import QuartzCore

class TrialOverlayNSView: NSView {
    private var containerLayer: CALayer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupOverlay()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupOverlay()
    }
    
    private func setupOverlay() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        
        // Create container for the overlay
        let container = CALayer()
        containerLayer = container
        
        // Position at bottom-right corner with padding
        let overlayWidth: CGFloat = 320
        let overlayHeight: CGFloat = 90
        let padding: CGFloat = 30
        let xPosition = bounds.width - overlayWidth - padding
        let yPosition = padding  // Bottom position
        
        container.frame = CGRect(x: xPosition, y: yPosition, width: overlayWidth, height: overlayHeight)
        
        // Create subtle background
        let backgroundLayer = CALayer()
        backgroundLayer.frame = CGRect(x: 0, y: 0, width: overlayWidth, height: overlayHeight)
        backgroundLayer.backgroundColor = NSColor.black.withAlphaComponent(0.75).cgColor
        backgroundLayer.cornerRadius = 12
        
        // Add subtle border
        backgroundLayer.borderWidth = 1
        backgroundLayer.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
        
        // Add subtle shadow for better readability
        backgroundLayer.shadowColor = NSColor.black.cgColor
        backgroundLayer.shadowOpacity = 0.3
        backgroundLayer.shadowOffset = CGSize(width: 0, height: 2)
        backgroundLayer.shadowRadius = 8
        
        container.addSublayer(backgroundLayer)
        
        // Create text layer
        let textLayer = CATextLayer()
        let attributedString = NSMutableAttributedString()
        
        // Add title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: NSColor.white.cgColor
        ]
        attributedString.append(NSAttributedString(string: "Free Version\n", attributes: titleAttributes))
        
        // Add subtitle
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor.white.withAlphaComponent(0.8).cgColor
        ]
        attributedString.append(NSAttributedString(string: "Unlock Premium to remove this message", attributes: subtitleAttributes))
        
        textLayer.string = attributedString
        textLayer.alignmentMode = .center
        textLayer.isWrapped = true
        textLayer.frame = CGRect(x: 15, y: 20, width: overlayWidth - 30, height: overlayHeight - 30)
        textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        
        container.addSublayer(textLayer)
        
        // Add small premium icon
        let iconLayer = CATextLayer()
        iconLayer.string = "👑"
        iconLayer.fontSize = 20
        iconLayer.alignmentMode = .center
        iconLayer.frame = CGRect(x: overlayWidth - 45, y: overlayHeight - 35, width: 30, height: 30)
        iconLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        
        container.addSublayer(iconLayer)
        
        // Add subtle fade-in animation
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.fromValue = 0
        fadeAnimation.toValue = 1
        fadeAnimation.duration = 1.0
        fadeAnimation.fillMode = .forwards
        container.add(fadeAnimation, forKey: "fadeIn")
        
        layer?.addSublayer(container)
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // Update position if window changes
        if let _ = window {
            setupOverlay()
        }
    }
}