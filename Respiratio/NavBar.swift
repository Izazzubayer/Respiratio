//
//  NavBar.swift
//  Respiratio
//
//  Navigation bar component optimized for iPhone 14 Pro Max with fluid animations and haptics
//

import SwiftUI

enum NavTab: String, CaseIterable {
    case meditation = "Meditation"
    case breathing = "Breathing"
    case noise = "Noise"
    
    var iconName: String {
        switch self {
        case .meditation:
            return "nav-meditation"
        case .breathing:
            return "nav-breathing"
        case .noise:
            return "nav-noise"
        }
    }
}

struct NavBar: View {
    @Binding var selectedTab: NavTab
    
    private let tabWidth: CGFloat = 122
    private let tabSpacing: CGFloat = 8
    
    private var selectedTabOffset: CGFloat {
        let selectedIndex = NavTab.allCases.firstIndex(of: selectedTab) ?? 0
        let totalWidth = CGFloat(NavTab.allCases.count) * tabWidth + CGFloat(NavTab.allCases.count - 1) * tabSpacing
        let startX = -totalWidth / 2 + tabWidth / 2
        return startX + CGFloat(selectedIndex) * (tabWidth + tabSpacing)
    }
    
    var body: some View {
        ZStack {
            // Full background color - extend beyond frame bounds
            Color(red: 0.17, green: 0.28, blue: 0.79)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all, edges: .bottom)
            
            // Sliding blue pill background
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.21, green: 0.35, blue: 0.97))
                .frame(width: tabWidth, height: 76)
                .offset(x: selectedTabOffset, y: -9.5)
                .animation(
                    .interpolatingSpring(
                        mass: 0.6,
                        stiffness: 150,
                        damping: 20,
                        initialVelocity: 0.3
                    ),
                    value: selectedTab
                )
            
            // Tab items (no individual backgrounds)
            HStack(spacing: tabSpacing) {
                ForEach(NavTab.allCases, id: \.self) { tab in
                    NavBarItem(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        selectedTab = tab
                        
                        // Haptic feedback
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.prepare()
                        impactGenerator.impactOccurred()
                    }
                }
            }
            .offset(x: 0, y: -9.5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 146)
        .cornerRadius(0)
        .clipped() // Clip any overflow
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

private struct NavBarItem: View {
    let tab: NavTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Icon with smooth opacity transition and scale
                Image(tab.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .foregroundColor(.white)
                    .opacity(isSelected ? 1.0 : 0.6)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isSelected)
                
                // Label with smooth opacity transition and weight change
                Text(tab.rawValue)
                    .font(.custom(isSelected ? "AnekGujarati-SemiBold" : "AnekGujarati-Medium", size: 16))
                    .foregroundColor(.white)
                    .opacity(isSelected ? 1.0 : 0.6)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8) // Prevent text truncation
                    .fixedSize(horizontal: false, vertical: true) // Ensure text fits
                    .animation(.easeInOut(duration: 0.3), value: isSelected)
            }
            .padding(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24))
            .frame(width: 122)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle()) // Ensures the entire area is tappable
    }
}

// MARK: - Preview

#Preview("NavBar") {
    @State var selectedTab: NavTab = .meditation
    
    return VStack {
        Spacer()
        
        NavBar(selectedTab: $selectedTab)
    }
    .background(Color.gray.opacity(0.1))
}

#Preview("All Nav States") {
    VStack(spacing: 20) {
        ForEach(NavTab.allCases, id: \.self) { tab in
            NavBar(selectedTab: .constant(tab))
        }
    }
    .background(Color.gray.opacity(0.1))
}
