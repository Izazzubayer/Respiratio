# Respiratio Design System

A centralized design system following Apple's Human Interface Guidelines (HIG) for consistent, maintainable UI components across the app.

## 🎯 Benefits

- **Single Source of Truth**: Change colors, fonts, spacing in one place
- **Consistency**: All components follow the same design patterns
- **Maintainability**: Easy to update app-wide styling
- **Apple HIG Compliance**: Follows iOS design best practices
- **Developer Experience**: Simple, intuitive API

## 📁 Structure

```
Core/DesignSystem/
├── DesignSystem.swift          # Main design tokens & extensions
├── Components/
│   ├── Buttons.swift          # Button styles & components
│   ├── Cards.swift            # Card styles & components
│   └── Layout.swift           # Layout helpers & components
└── README.md                  # This documentation
```

## 🎨 Design Tokens

### Colors
```swift
// Primary brand colors
DesignSystem.Colors.primary        // #4A8FE3 - Main app blue
DesignSystem.Colors.primaryDark    // #1A2B7C - Dark blue
DesignSystem.Colors.primaryLight   // Light blue variant

// Semantic colors
DesignSystem.Colors.success        // Green
DesignSystem.Colors.warning        // Orange
DesignSystem.Colors.error          // Red
DesignSystem.Colors.info           // Blue

// Background colors
DesignSystem.Colors.background     // System background
DesignSystem.Colors.overlay        // Card overlay
```

### Typography
```swift
// Font families
DesignSystem.Typography.primaryFont    // "Amagro-Bold"
DesignSystem.Typography.secondaryFont  // "AnekGujarati-Regular"

// Font sizes (Dynamic Type compliant)
DesignSystem.Typography.title1         // 28pt
DesignSystem.Typography.title2         // 22pt
DesignSystem.Typography.headline       // 17pt
DesignSystem.Typography.body           // 17pt
DesignSystem.Typography.caption1       // 12pt
```

### Spacing
```swift
// 8pt grid system
DesignSystem.Spacing.xs    // 4pt
DesignSystem.Spacing.sm    // 8pt
DesignSystem.Spacing.md    // 12pt
DesignSystem.Spacing.lg    // 16pt
DesignSystem.Spacing.xl    // 20pt
DesignSystem.Spacing.xxl   // 24pt
```

## 🧩 Components

### Buttons

#### Using Button Styles
```swift
Button("Done") { }
    .buttonStyle(PrimaryButtonStyle())

Button("Cancel") { }
    .buttonStyle(SecondaryButtonStyle())
```

#### Using Button Components
```swift
PrimaryButton(title: "Done") {
    // action
}

SecondaryButton(title: "Cancel") {
    // action
}

ShareButton(title: "Share") {
    // action
}
```

#### Using Button Modifiers
```swift
Button("Done") { }
    .primaryButtonStyle()

Button("Cancel") { }
    .secondaryButtonStyle()
```

### Cards

#### Using Card Styles
```swift
VStack { /* content */ }
    .standardCardStyle()

VStack { /* content */ }
    .infoCardStyle()
```

#### Using Card Components
```swift
StandardCard {
    VStack {
        Text("Card Content")
    }
}

InfoCard {
    VStack {
        Text("Info Content")
    }
}

SessionInfoCard(
    title: "2-MINUTE QUICK RESET SESSION",
    duration: "1m 50s",
    brainIconColor: DesignSystem.Colors.primaryLight
)

StreakCard(
    title: "Current Streak",
    value: "9 DAYS",
    symbol: "flame.fill",
    tint: .orange
)
```

### Layout

#### Using Layout Components
```swift
SectionHeader("Meditation", subtitle: "Choose your session")

ProgressSection(
    progress: 0.75,
    currentTime: "00:00",
    totalTime: "-01:50"
)

AudioOutputSection(
    icon: "airpods",
    name: "AirPods"
)
```

#### Using Layout Modifiers
```swift
VStack { /* content */ }
    .sectionSpacing()
    .horizontalMargins()
    .fullWidth()
    .standardHeight()
```

## 🔄 Migration Guide

### Before (Old Way)
```swift
Button("Done") {
    dismissSheet()
}
.background(
    RoundedRectangle(cornerRadius: 18)
        .fill(Color(red: 0.29, green: 0.56, blue: 0.89))
)
.frame(height: 52)
.padding(.horizontal, 16)
```

### After (New Way)
```swift
PrimaryButton(title: "Done") {
    dismissSheet()
}
```

### Before (Old Way)
```swift
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
```

### After (New Way)
```swift
VStackSpaced(spacing: DesignSystem.Spacing.xxl) {
    Text("Title")
        .primaryTitle()
        .foregroundColor(.white)
}
.standardPadding()
.standardCardStyle()
```

## 📱 Usage Examples

### Complete Button Example
```swift
struct ContentView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            SectionHeader("Welcome", subtitle: "Start your journey")
            
            PrimaryButton(title: "Get Started") {
                // action
            }
            
            SecondaryButton(title: "Learn More") {
                // action
            }
        }
        .horizontalMargins()
        .sectionSpacing()
    }
}
```

### Complete Card Example
```swift
struct SessionCard: View {
    var body: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text("Session Title")
                    .cardTitle()
                    .foregroundColor(.white)
                
                Text("Session description goes here")
                    .bodyText()
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}
```

## 🚀 Best Practices

1. **Always use design tokens** instead of hardcoded values
2. **Use components** when possible instead of building from scratch
3. **Follow the spacing system** (8pt grid)
4. **Use semantic colors** for different states
5. **Test with Dynamic Type** to ensure accessibility
6. **Keep components focused** on a single responsibility

## 🔧 Customization

To add new design tokens or components:

1. **Add to DesignSystem.swift** for new tokens
2. **Create new component files** for complex components
3. **Update this README** with new usage examples
4. **Test across different screen sizes** and accessibility settings

## 📚 Resources

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [iOS Design Patterns](https://developer.apple.com/design/human-interface-guidelines/ios/overview/design-patterns/)
