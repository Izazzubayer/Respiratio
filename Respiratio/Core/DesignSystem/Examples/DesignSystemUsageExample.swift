//
//  DesignSystemUsageExample.swift
//  Respiratio
//
//  Example of how to use the Design System in existing views
//

import SwiftUI

// MARK: - Example: Converting MeditationSessionView to use Design System

struct DesignSystemUsageExample: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.itemSpacing) {
            // Example of using the new SectionHeader component
            SectionHeader("Meditation Complete", subtitle: "Great job on your session!")
            
            // Example of using the new SessionInfoCard component
            SessionInfoCard(
                title: "2-MINUTE QUICK RESET SESSION",
                duration: "1m 50s",
                brainIconColor: DesignSystem.Colors.primaryLight
            )
            
            // Example of using the new StreakCard components
            HStack(spacing: DesignSystem.Spacing.md) {
                StreakCard(
                    title: "Current Streak",
                    value: "9 DAYS",
                    symbol: "flame.fill",
                    tint: .orange
                )
                
                StreakCard(
                    title: "Best",
                    value: "9 DAYS",
                    symbol: "trophy.fill",
                    tint: .yellow
                )
            }
            
            // Example of using the new PrimaryButton component
            PrimaryButton(title: "Done") {
                // action
            }
            
            // Example of using design system modifiers
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Custom Content")
                    .primaryTitle()
                    .foregroundColor(.white)
                
                Text("This uses design system typography and spacing")
                    .bodyText()
                    .foregroundColor(.white.opacity(0.8))
            }
            .standardPadding()
            .standardCardStyle()
        }
        .horizontalMargins()
        .sectionSpacing()
        .background(DesignSystem.Colors.primaryDark)
    }
}

// MARK: - Migration Example: Before vs After

struct MigrationExample {
    
    // BEFORE (Old way with hardcoded values)
    /*
    Button("Done") {
        dismissSheet()
    }
    .background(
        RoundedRectangle(cornerRadius: 18)
            .fill(Color(red: 0.29, green: 0.56, blue: 0.89))
    )
    .overlay(
        RoundedRectangle(cornerRadius: 18)
            .stroke(Color(red: 0.29, green: 0.56, blue: 0.89).opacity(0.9), lineWidth: 1.5)
    )
    .shadow(color: Color(red: 0.29, green: 0.56, blue: 0.89).opacity(0.3), radius: 6, x: 0, y: 3)
    .frame(height: 52)
    */
    
    // AFTER (New way using design system)
    /*
    PrimaryButton(title: "Done") {
        dismissSheet()
    }
    */
    
    // BEFORE (Old way with hardcoded spacing)
    /*
    VStack(spacing: 24) {
        Text("Title")
            .font(.custom("Amagro-Bold", size: 24))
            .foregroundColor(.white)
    }
    .padding(24)
    .background(
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.white.opacity(0.08))
    )
    */
    
    // AFTER (New way using design system)
    /*
    VStackSpaced(spacing: DesignSystem.Spacing.xxl) {
        Text("Title")
            .primaryTitle()
            .foregroundColor(.white)
    }
    .standardPadding()
    .standardCardStyle()
    */
}

#Preview {
    DesignSystemUsageExample()
}
