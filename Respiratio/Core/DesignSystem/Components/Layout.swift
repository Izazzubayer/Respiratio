//
//  Layout.swift
//  Respiratio
//
//  Centralized layout components following Apple's HIG
//

import SwiftUI

// MARK: - Layout Components
struct SectionHeader: View {
    let title: String
    let subtitle: String?
    
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(DesignSystem.Typography.title2)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProgressSection: View {
    let progress: Double
    let currentTime: String
    let totalTime: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Progress bar with time display
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Progress bar container
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 8)
                    
                    // Progress track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: UIScreen.main.bounds.width * 0.8 * progress, height: 8)
                }
                
                // Time labels
                HStack {
                    Text(currentTime)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text(totalTime)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

struct AudioOutputSection: View {
    let icon: String
    let name: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
            
            Text(name)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Spacing Helpers
struct VStackSpaced<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat = DesignSystem.Spacing.itemSpacing, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: spacing) {
            content
        }
    }
}

struct HStackSpaced<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat = DesignSystem.Spacing.sm, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            content
        }
    }
}

// MARK: - Layout Modifiers
extension View {
    func sectionSpacing() -> some View {
        self.padding(.vertical, DesignSystem.Spacing.sectionSpacing)
    }
    
    func standardSpacing() -> some View {
        self.padding(.vertical, DesignSystem.Spacing.itemSpacing)
    }
    
    func horizontalMargins() -> some View {
        self.padding(.horizontal, DesignSystem.Spacing.lg)
    }
    
    func fullWidth() -> some View {
        self.frame(maxWidth: .infinity)
    }
    
    func standardHeight() -> some View {
        self.frame(height: DesignSystem.Layout.buttonHeight)
    }
    
    func cardHeight() -> some View {
        self.frame(height: DesignSystem.Layout.cardHeight)
    }
}
