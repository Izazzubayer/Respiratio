# 🎬 Lottie Animation Integration Guide for Respiratio

## 📱 What is Lottie?

Lottie is a library that renders After Effects animations in real-time. It allows you to create complex animations in After Effects and export them as lightweight JSON files that can be played in your iOS app.

## 🚀 Benefits for Respiratio

- **Professional Animations**: Create smooth, complex breathing animations
- **Performance**: Hardware-accelerated animations that are smooth at 60fps
- **File Size**: Small animation files (typically 10-100KB)
- **Designer-Friendly**: Animators can create in After Effects, developers just play them
- **Interactive**: Control playback, speed, and progress programmatically

## 📦 Installation

### 1. Add Swift Package Dependency

In Xcode:
1. Go to **File** → **Add Package Dependencies**
2. Search for: `https://github.com/LottieFiles/dotlottie-ios`
3. Click **Add Package**

### 2. Import in Your Swift Files

```swift
import DotLottie
```

## 🎯 Usage Examples

### Basic Animation from Bundle

```swift
// Load a .lottie or .json file from your app bundle
DotLottieAnimation(
    fileName: "breathing_animation",
    config: AnimationConfig(autoplay: true, loop: true)
).view()
.frame(width: 280, height: 280)
```

### Animation from Web URL

```swift
// Load animation from a web server
DotLottieAnimation(
    webURL: "https://your-domain.com/breathing.lottie",
    config: AnimationConfig(autoplay: false, loop: true)
).view()
.frame(width: 280, height: 280)
```

### Animation from JSON String

```swift
// Load animation from a JSON string (useful for dynamic content)
DotLottieAnimation(
    animationData: jsonString,
    config: AnimationConfig(autoplay: false, loop: false)
).view()
.frame(width: 280, height: 280)
```

## ⚙️ Configuration Options

### AnimationConfig Properties

```swift
AnimationConfig(
    autoplay: Bool,        // Start playing immediately
    loop: Bool,            // Loop the animation
    speed: Double,         // Playback speed (1.0 = normal)
    direction: Int,        // 1 = forward, -1 = reverse
    segment: [Int, Int]    // Play specific frame range
)
```

### Common Configurations

```swift
// Breathing animation that loops continuously
let breathingConfig = AnimationConfig(autoplay: false, loop: true)

// One-time animation that plays once
let introConfig = AnimationConfig(autoplay: true, loop: false)

// Slow motion breathing
let slowBreathingConfig = AnimationConfig(autoplay: false, loop: true, speed: 0.5)
```

## 🎮 Interactive Control

### Playback Control

```swift
// Get a reference to the animation
let breathingAnimation = DotLottieAnimation(
    fileName: "box_breathing",
    config: AnimationConfig(autoplay: false, loop: true)
)

// Control playback
breathingAnimation.play()      // Start playing
breathingAnimation.pause()     // Pause
breathingAnimation.stop()      // Stop and reset
breathingAnimation.seek(to: 0.5) // Jump to 50% progress
```

### Progress Tracking

```swift
// Listen to animation progress
breathingAnimation.onProgress = { progress in
    // progress is a value from 0.0 to 1.0
    print("Animation progress: \(progress * 100)%")
}

// Listen to animation completion
breathingAnimation.onComplete = {
    print("Animation completed!")
}
```

## 🎨 Integration with Your Current UI

### Replace Custom Animation in BoxBreathingView

Instead of the current custom circle animation, you can use a Lottie animation:

```swift
// Replace this:
// Circle()
//     .fill(Color.white)
//     .frame(width: 30, height: 30)
//     .offset(breathingCircleOffset)

// With this:
DotLottieAnimation(
    fileName: "box_breathing_circle",
    config: AnimationConfig(autoplay: false, loop: true)
).view()
.frame(width: 280, height: 280)
```

### Breathing Pattern Animations

Create different Lottie animations for each breathing technique:

- **Box Breathing**: 4-4-4-4 pattern
- **4-7-8 Breathing**: 4-7-8 pattern
- **Triangle Breathing**: 3-3-3 pattern

## 📁 File Organization

### Recommended Structure

```
Respiratio/
├── Assets.xcassets/
│   └── animations/
│       ├── box_breathing.lottie
│       ├── triangle_breathing.lottie
│       ├── meditation_breath.lottie
│       └── background_waves.lottie
```

### File Naming Convention

- `breathing_[technique].lottie` - Breathing animations
- `meditation_[type].lottie` - Meditation animations
- `noise_[sound].lottie` - Background noise visualizations

## 🔧 Advanced Features

### Multiple Animation Layers

```swift
ZStack {
    // Background breathing waves
    DotLottieAnimation(fileName: "breathing_waves", config: waveConfig).view()
    
    // Foreground breathing circle
    DotLottieAnimation(fileName: "breathing_circle", config: circleConfig).view()
}
```

### Synchronized Animations

```swift
// Start multiple animations together
let startTime = Date()
breathingAnimation.play()
waveAnimation.play()
pulseAnimation.play()

// Or stagger them
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    secondaryAnimation.play()
}
```

### Custom Animation Timing

```swift
// Create custom breathing patterns
let inhaleDuration: TimeInterval = 4.0
let holdDuration: TimeInterval = 4.0
let exhaleDuration: TimeInterval = 4.0
let holdEmptyDuration: TimeInterval = 4.0

// Control animation speed based on breathing phase
breathingAnimation.seek(to: 0.0) // Start of inhale
// ... wait for inhaleDuration
breathingAnimation.seek(to: 0.25) // Start of hold
// ... wait for holdDuration
breathingAnimation.seek(to: 0.5) // Start of exhale
// ... wait for exhaleDuration
breathingAnimation.seek(to: 0.75) // Start of hold empty
// ... wait for holdEmptyDuration
```

## 🎯 Next Steps

1. **Create Lottie Animations**: Work with a designer to create breathing animations in After Effects
2. **Export as .lottie**: Use the LottieFiles plugin to export optimized animations
3. **Add to Assets**: Place .lottie files in your Xcode project
4. **Replace Custom Code**: Gradually replace custom animations with Lottie animations
5. **Test Performance**: Ensure animations run smoothly on all devices

## 📚 Resources

- [LottieFiles Website](https://lottiefiles.com/)
- [After Effects Plugin](https://lottiefiles.com/plugins/after-effects)
- [Animation Examples](https://lottiefiles.com/featured)
- [Community Animations](https://lottiefiles.com/community)

## 🚨 Important Notes

- **iOS 15.4+ Required**: dotLottie-ios requires iOS 15.4 or later
- **File Size**: Keep individual animations under 500KB for best performance
- **Testing**: Test animations on actual devices, not just simulator
- **Fallbacks**: Always provide fallback UI for devices that don't support Lottie
