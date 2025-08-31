import SwiftUI

// MARK: - Navigation Tab Enum
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

struct ContentView: View {
    @State private var selectedTab: NavTab = .meditation
    @State private var isMeditationSessionActive = false
    @State private var isNoiseSessionActive = false
    
    var body: some View {
        ZStack {
            // Global dark background
            Color(hex: "#1A2B7C")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content area with smooth tab transitions
                ZStack {
                    if selectedTab == .meditation {
                        MeditationView()
                    } else if selectedTab == .breathing {
                        BreathingView()
                    } else if selectedTab == .noise {
                        BackgroundNoiseView()
                    }
                }
                .onChange(of: selectedTab) { _, newTab in
                    // Only allow tab changes if no session is active
                    if (isMeditationSessionActive && newTab != .meditation) ||
                       (isNoiseSessionActive && newTab != .noise) {
                        // Provide haptic feedback to indicate tabs are disabled
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        // Revert back to current session tab if session is active
                        if isMeditationSessionActive {
                            selectedTab = .meditation
                        } else if isNoiseSessionActive {
                            selectedTab = .noise
                        }
                        return
                    }
                    
                    // Post notification when tab changes so audio can be paused immediately
                    // But don't post if we're staying on current session tab (to avoid conflicts)
                    if (newTab != .meditation && !isMeditationSessionActive) ||
                       (newTab != .noise && !isNoiseSessionActive) {
                        NotificationCenter.default.post(
                            name: .tabDidChange,
                            object: newTab
                        )
                    }
                }
                
                // Custom navigation bar
                SimpleNavBar(selectedTab: $selectedTab, onSameTabTapped: { tab in
                    handleSameTabTapped(tab)
                })
                .disabled(isMeditationSessionActive || isNoiseSessionActive)
                .opacity((isMeditationSessionActive || isNoiseSessionActive) ? 0.5 : 1.0)
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: .meditationSessionStarted)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isMeditationSessionActive = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .meditationSessionEnded)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isMeditationSessionActive = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .noiseSessionStarted)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isNoiseSessionActive = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .noiseSessionEnded)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isNoiseSessionActive = false
            }
        }
    }
    
    // MARK: - Same Tab Tapped Handler
    
    private func handleSameTabTapped(_ tab: NavTab) {
        // Trigger haptic feedback
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.impactOccurred()
        
        // Post notification to exit current session
        NotificationCenter.default.post(
            name: .exitToMainView,
            object: tab
        )
    }
}

// MARK: - Simple Navigation Bar Component
struct SimpleNavBar: View {
    @Binding var selectedTab: NavTab
    let onSameTabTapped: (NavTab) -> Void
    
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
            // Full background color
            Color(hex: "#111C52")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all, edges: .bottom)
            
            // Sliding blue pill background
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "#1A2B7C"))
                .frame(width: tabWidth, height: 82)
                .offset(x: selectedTabOffset, y: -9.5)
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
            
            // Tab items
            HStack(spacing: tabSpacing) {
                ForEach(NavTab.allCases, id: \.self) { tab in
                    SimpleNavBarItem(tab: tab, isSelected: selectedTab == tab) {
                        if selectedTab == tab {
                            onSameTabTapped(tab)
                        } else {
                            selectedTab = tab
                        }
                        
                        // Haptic feedback
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()
                    }
                }
            }
            .offset(x: 0, y: -9.5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 128)
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

struct SimpleNavBarItem: View {
    let tab: NavTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Icon
                Image(tab.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .foregroundColor(.white)
                    .opacity(isSelected ? 1.0 : 0.6)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isSelected)
                
                // Label
                Text(tab.rawValue)
                    .font(.custom(isSelected ? "AnekGujarati-SemiBold" : "AnekGujarati-Medium", size: 16))
                    .foregroundColor(.white)
                    .opacity(isSelected ? 1.0 : 0.6)
                    .lineLimit(1)
                    .animation(.easeInOut(duration: 0.3), value: isSelected)
            }
            .padding(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24))
            .frame(width: 122)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Comprehensive Previews for Real-Time Development

#Preview("Main App - iPhone") {
    ContentView()
}

#Preview("Main App - iPhone Landscape") {
    ContentView()
}

#Preview("Main App - iPad") {
    ContentView()
}

#Preview("Main App - Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}

#Preview("Main App - Dynamic Type Large") {
    ContentView()
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}