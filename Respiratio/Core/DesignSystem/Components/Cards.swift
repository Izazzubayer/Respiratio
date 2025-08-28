//
//  Cards.swift
//  Respiratio
//
//  Centralized card components following Apple's HIG
//

import SwiftUI

// MARK: - Card Styles
struct StandardCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DesignSystem.Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge)
                    .fill(DesignSystem.Colors.overlay)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge)
                    .stroke(DesignSystem.Colors.overlayBorder, lineWidth: 1)
            )
    }
}

struct InfoCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DesignSystem.Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge)
                    .fill(DesignSystem.Colors.overlay)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge)
                    .stroke(DesignSystem.Colors.overlayBorder, lineWidth: 1)
            )
    }
}

struct StatCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DesignSystem.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(DesignSystem.Colors.overlay)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .stroke(DesignSystem.Colors.overlayBorder, lineWidth: 1)
            )
    }
}

// MARK: - Card Components
struct StandardCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .modifier(StandardCardStyle())
    }
}

struct InfoCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .modifier(InfoCardStyle())
    }
}

struct StatCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .modifier(StatCardStyle())
    }
}

// MARK: - Specific Card Types
struct SessionInfoCard: View {
    let title: String
    let duration: String
    let brainIconColor: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18))
                    .foregroundStyle(brainIconColor)
                Text(title)
                    .font(DesignSystem.Typography.cardTitle)
                    .foregroundColor(.white)
                    .lineLimit(2)
                Spacer()
            }
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.blue)
                Text("Duration: \(duration)")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }
        }
        .modifier(InfoCardStyle())
    }
}

struct StreakCard: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: symbol)
                    .font(.system(size: 14))
                Text(title)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
            }
            .foregroundStyle(tint)
            Text(value)
                .font(DesignSystem.Typography.statValue)
                .foregroundColor(.white)
        }
        .modifier(StatCardStyle())
    }
}

// MARK: - Card Modifiers
extension View {
    func standardCardStyle() -> some View {
        self.modifier(StandardCardStyle())
    }
    
    func infoCardStyle() -> some View {
        self.modifier(InfoCardStyle())
    }
    
    func statCardStyle() -> some View {
        self.modifier(StatCardStyle())
    }
}
