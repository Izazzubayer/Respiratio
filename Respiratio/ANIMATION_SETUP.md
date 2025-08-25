# 🎬 Lottie Animation Setup for Respiratio

## 📁 File Organization

### 1. Create Animations Folder in Assets

```
Respiratio/
├── Assets.xcassets/
│   └── animations/
│       ├── box_breathing.lottie      # Box breathing pattern
│       ├── triangle_breathing.lottie # Triangle breathing pattern
│       ├── meditation_waves.lottie   # Meditation background
│       └── noise_visualizer.lottie   # Background noise waves
```

### 2. Add to Xcode Project

1. **Right-click** on `Assets.xcassets` in Xcode
2. **New Folder** → Name it `animations`
3. **Drag & Drop** your `.lottie` files into this folder
4. **Ensure** "Add to target" includes your main app target

## 🎯 Animation Requirements

### Box Breathing Animation
- **Duration**: 16 seconds (4s per side)
- **Loop**: Continuous
- **Size**: 280x280 points
- **Format**: `.lottie` or `.json`

### Triangle Breathing Animation
- **Duration**: 9 seconds (3s per side)
- **Loop**: Continuous
- **Size**: 280x280 points
- **Format**: `.lottie` or `.json`

### Meditation Waves
- **Duration**: 10-15 seconds
- **Loop**: Continuous
- **Size**: Full screen or 280x280
- **Format**: `.lottie` or `.json`

## 🔧 Code Integration

### Current Implementation
Your `BoxBreathingView` now automatically detects Lottie files:

```swift
private func setupLottieAnimation() {
    // Try to load Lottie animation from bundle
    if let _ = Bundle.main.path(forResource: "box_breathing", ofType: "lottie") {
        breathingAnimation = DotLottieAnimation(
            fileName: "box_breathing",
            config: AnimationConfig(autoplay: false, loop: true)
        )
    } else if let _ = Bundle.main.path(forResource: "box_breathing", ofType: "json") {
        breathingAnimation = DotLottieAnimation(
            fileName: "box_breathing",
            config: AnimationConfig(autoplay: false, loop: true)
        )
    }
    // Falls back to custom animation if no Lottie file exists
}
```

### Fallback System
- **With Lottie**: Uses professional animation
- **Without Lottie**: Falls back to your custom circle animation
- **Seamless**: No code changes needed

## 📱 Testing

### 1. Without Lottie Files
- App works with custom animations
- No errors or crashes
- Smooth performance

### 2. With Lottie Files
- Professional animations play
- Better visual quality
- Maintains all functionality

## 🚀 Next Steps

1. **Create Animations**: Use After Effects + LottieFiles plugin
2. **Export**: Save as `.lottie` files
3. **Add to Project**: Drag into Xcode assets
4. **Test**: Verify animations work correctly
5. **Optimize**: Ensure file sizes are under 500KB

## 💡 Animation Ideas

### Breathing Patterns
- **Inhale**: Circle expands, color brightens
- **Hold**: Pulsing effect, steady glow
- **Exhale**: Circle contracts, color dims
- **Hold Empty**: Minimal glow, subtle pulse

### Background Effects
- **Waves**: Gentle flowing lines
- **Particles**: Floating dots or sparkles
- **Gradients**: Smooth color transitions
- **Shapes**: Geometric patterns

### Interactive Elements
- **Touch Response**: Animation reacts to taps
- **Speed Control**: Adjust animation speed
- **Progress Sync**: Match breathing rhythm
- **Haptic Feedback**: Coordinate with vibrations
