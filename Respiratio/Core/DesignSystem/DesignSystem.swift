//
//  DesignSystem.swift
//  Respiratio
//
//  Design System following Apple's Human Interface Guidelines
//  Centralized design tokens and components for consistent app experience
//

import SwiftUI

// MARK: - Design System Namespace
enum DesignSystem {
    
    // MARK: - Colors
    enum Colors {
        // Primary Brand Colors
        static let primary = Color(red: 0.29, green: 0.56, blue: 0.89) // #4A8FE3
        static let primaryDark = Color(hex: "#1A2B7C")
        static let primaryLight = Color(red: 0.56, green: 0.59, blue: 0.99)
        
        // Semantic Colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Background Colors
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)
        
        // Text Colors
        static let primaryText = Color(.label)
        static let secondaryText = Color(.secondaryLabel)
        static let tertiaryText = Color(.tertiaryLabel)
        
        // Overlay Colors
        static let overlay = Color.white.opacity(0.08)
        static let overlayBorder = Color.white.opacity(0.2)
        static let overlayStrong = Color.white.opacity(0.15)
    }
    
    // MARK: - Typography
    enum Typography {
        // Font Families
        static let primaryFont = "Amagro-Bold"
        static let secondaryFont = "AnekGujarati-Regular"
        static let mediumFont = "AnekGujarati-Medium"
        
        // Font Sizes (following Apple's Dynamic Type scale)
        static let largeTitle = Font.custom(primaryFont, size: 34)
        static let title1 = Font.custom(primaryFont, size: 28)
        static let title2 = Font.custom(primaryFont, size: 22)
        static let title3 = Font.custom(primaryFont, size: 20)
        static let headline = Font.custom(primaryFont, size: 17)
        static let body = Font.custom(secondaryFont, size: 17)
        static let callout = Font.custom(secondaryFont, size: 16)
        static let subheadline = Font.custom(secondaryFont, size: 15)
        static let footnote = Font.custom(secondaryFont, size: 13)
        static let caption1 = Font.custom(secondaryFont, size: 12)
        static let caption2 = Font.custom(secondaryFont, size: 11)
        
        // Custom Sizes for specific use cases
        static let buttonText = Font.custom(primaryFont, size: 16)
        static let cardTitle = Font.custom(primaryFont, size: 18)
        static let statValue = Font.custom(primaryFont, size: 18)
    }
    
    // MARK: - Spacing
    enum Spacing {
        // Base spacing unit (8pt grid system)
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        
        // Component-specific spacing
        static let cardPadding: CGFloat = 16
        static let buttonPadding: CGFloat = 12
        static let sectionSpacing: CGFloat = 24
        static let itemSpacing: CGFloat = 16
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 18
        static let xxlarge: CGFloat = 24
    }
    
    // MARK: - Shadows
    enum Shadows {
        static let small = Shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let medium = Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        static let large = Shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
        
        // Custom shadows for primary color
        static let primarySmall = Shadow(color: Colors.primary.opacity(0.3), radius: 6, x: 0, y: 3)
        static let primaryMedium = Shadow(color: Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Animation
    enum Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        
        // Spring animations
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let bouncy = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.6)
    }
    
    // MARK: - Layout
    enum Layout {
        // Minimum tap targets (Apple HIG requirement)
        static let minimumTapTarget: CGFloat = 44
        
        // Standard heights
        static let buttonHeight: CGFloat = 44
        static let cardHeight: CGFloat = 52
        static let listRowHeight: CGFloat = 52
        
        // Standard widths
        static let maxWidth = CGFloat.infinity
        static let standardWidth: CGFloat = 320
    }
}

// MARK: - Shadow Helper
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// Shadow helper struct for storing shadow values

// MARK: - View Extensions for Design System
extension View {
    // Typography modifiers
    func primaryTitle() -> some View {
        self.font(DesignSystem.Typography.title1)
    }
    
    func secondaryTitle() -> some View {
        self.font(DesignSystem.Typography.title2)
    }
    
    func headlineText() -> some View {
        self.font(DesignSystem.Typography.headline)
    }
    
    func bodyText() -> some View {
        self.font(DesignSystem.Typography.body)
    }
    
    func captionText() -> some View {
        self.font(DesignSystem.Typography.caption1)
    }
    
    // Spacing modifiers
    func standardPadding() -> some View {
        self.padding(DesignSystem.Spacing.lg)
    }
    
    func cardPadding() -> some View {
        self.padding(DesignSystem.Spacing.cardPadding)
    }
    
    func buttonPadding() -> some View {
        self.padding(DesignSystem.Spacing.buttonPadding)
    }
    
    // Background modifiers
    func primaryBackground() -> some View {
        self.background(DesignSystem.Colors.primary)
    }
    
    func overlayBackground() -> some View {
        self.background(DesignSystem.Colors.overlay)
    }
    
    // Corner radius modifiers
    func standardCornerRadius() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
    }
    
    func cardCornerRadius() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge))
    }
    
    // Shadow modifiers
    func shadowSmall() -> some View {
        self.shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    func shadowMedium() -> some View {
        self.shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    func shadowLarge() -> some View {
        self.shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
    }
    
    func primaryShadowSmall() -> some View {
        self.shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 6, x: 0, y: 3)
    }
    
    func primaryShadowMedium() -> some View {
        self.shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}
