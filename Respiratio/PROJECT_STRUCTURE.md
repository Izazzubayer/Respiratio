# Respiratio iOS App - Complete Project Structure Documentation

## 📱 Project Overview
Respiratio is a meditation and breathing app built with SwiftUI following iOS development best practices. This document provides a comprehensive breakdown of the project structure, explaining what each folder contains, how it's used, and which UI pages it connects to.

---

## 🗂️ Root Directory Structure

```
Respiratio/
├── Views/                    # SwiftUI Views organized by feature
├── Models/                   # Data models and business logic
├── Services/                 # Business logic and external services
├── Utils/                    # Extensions, helpers, and utilities
├── Resources/                # Assets, fonts, audio files, and media
├── DesignSystem/             # Centralized design tokens and components
├── RespiratioApp.swift       # Main app entry point
├── Info.plist               # App configuration
└── Assets.xcassets          # Image assets
```

---

## 🎨 Views/ - SwiftUI User Interface

### Views/Breathing/ - Breathing Exercise Views
**Purpose**: Contains all views related to breathing exercises and techniques.

#### Files:
- **`BreathingSessionView.swift`**
  - **What it does**: Main breathing session interface with timer, breathing patterns, and visual feedback
  - **Connected to**: Breathing exercises from `BreathingView.swift`
  - **Key features**: Breathing timer, pattern visualization, session completion

- **`BreathingView.swift`**
  - **What it does**: Main breathing exercise selection screen
  - **Connected to**: Navigation from main app tabs
  - **Key features**: Exercise categories, difficulty levels, session setup

- **`BoxBreathingView.swift`**
  - **What it does**: 4-4-4-4 box breathing technique interface
  - **Connected to**: `BreathingView.swift` exercise selection
  - **Key features**: Animated breathing cycle, visual guides

- **`TriangleBreathingView.swift`**
  - **What it does**: 4-7-8 triangle breathing technique interface
  - **Connected to**: `BreathingView.swift` exercise selection
  - **Key features**: Inhale-hold-exhale pattern visualization

- **`LottieBreathingView.swift`**
  - **What it does**: Breathing exercise with Lottie animations
  - **Connected to**: `BreathingView.swift` exercise selection
  - **Key features**: Animated breathing guides, visual feedback

### Views/Meditation/ - Meditation Session Views
**Purpose**: Contains all views related to meditation sessions and guided meditation.

#### Files:
- **`MeditationSessionView.swift`**
  - **What it does**: Main meditation session interface with audio controls, progress tracking, and completion
  - **Connected to**: Meditation selection from `MeditationView.swift`
  - **Key features**: Audio playback, fast-forward controls, progress ring, completion sheet
  - **UI Elements**: Play/pause button, fast-forward 30s, volume control, progress display

- **`MeditationView.swift`**
  - **What it does**: Main meditation selection screen with preset options
  - **Connected to**: Navigation from main app tabs
  - **Key features**: Quick meditation presets (2min, 5min, 10min, 15min, 20min), custom duration
  - **UI Elements**: Meditation cards, preset descriptions, difficulty indicators

### Views/Noise/ - Background Noise Views
**Purpose**: Contains all views related to background noise and ambient sounds.

#### Files:
- **`NoiseSessionView.swift`**
  - **What it does**: Background noise playback interface with controls
  - **Connected to**: Noise selection from `BackgroundNoiseView.swift`
  - **Key features**: Noise mixing, volume control, session management

- **`BackgroundNoiseView.swift`**
  - **What it does**: Background noise selection and configuration screen
  - **Connected to**: Navigation from main app tabs
  - **Key features**: Noise categories, mixing options, duration settings

### Views/Common/ - Shared and Navigation Views
**Purpose**: Contains views shared across multiple features and navigation components.

#### Files:
- **`ContentView.swift`**
  - **What it does**: Main app container with tab navigation
  - **Connected to**: `RespiratioApp.swift` (app entry point)
  - **Key features**: Tab bar navigation, feature switching
  - **UI Elements**: Tab bar with Breathing, Meditation, Noise, and Settings

- **`NavBar.swift`**
  - **What it does**: Custom navigation bar component
  - **Connected to**: Used across multiple feature views
  - **Key features**: Consistent navigation styling, tab management

- **`SplashScreenView.swift`**
  - **What it does**: App launch screen and initial loading
  - **Connected to**: `RespiratioApp.swift` (app startup)
  - **Key features**: Brand display, loading animation

- **`AppRootView.swift`**
  - **What it does**: App state management and routing
  - **Connected to**: `RespiratioApp.swift` (app initialization)
  - **Key features**: User session management, onboarding flow

- **`WelcomeView.swift`**
  - **What it does**: First-time user welcome and onboarding
  - **Connected to**: `AppRootView.swift` (user flow)
  - **Key features**: App introduction, feature overview

- **`LottieDemoView.swift`**
  - **What it does**: Lottie animation showcase and testing
  - **Connected to**: Development and testing purposes
  - **Key features**: Animation preview, performance testing

- **`KeepAwakeToggle.swift`**
  - **What it does**: Screen wake lock toggle component
  - **Connected to**: Used in meditation and breathing sessions
  - **Key features**: Prevents screen sleep during sessions

---

## 🏗️ Models/ - Data Structure and Business Logic

### Models/Breathing/ - Breathing Exercise Models
**Purpose**: Defines data structures for breathing exercises and sessions.

#### Files:
- **`BreathingExercise.swift`**
  - **What it does**: Defines breathing exercise patterns and configurations
  - **Connected to**: `BreathingSessionView.swift`, `BreathingView.swift`
  - **Key features**: Exercise types, timing patterns, difficulty levels

### Models/Meditation/ - Meditation Models
**Purpose**: Defines data structures for meditation sessions and presets.

#### Files:
- **`MeditationPreset.swift`**
  - **What it does**: Defines meditation preset configurations
  - **Connected to**: `MeditationView.swift`, `MeditationSessionView.swift`
  - **Key features**: Duration, category, difficulty, audio file mapping
  - **Properties**: title, description, duration, category, difficulty, symbol, audioFileName, hasAudio, tags

### Models/Noise/ - Background Noise Models
**Purpose**: Defines data structures for background noise and ambient sounds.

#### Files:
- **`NoiseCatalog.swift`**
  - **What it does**: Defines available background noise options
  - **Connected to**: `BackgroundNoiseView.swift`, `NoiseSessionView.swift`
  - **Key features**: Noise categories, file mappings, descriptions

- **`BackgroundNoise.swift`**
  - **What it does**: Individual noise sound configuration
  - **Connected to**: `NoiseCatalog.swift`
  - **Key features**: Sound properties, volume levels, mixing options

- **`BNDuration.swift`**
  - **What it does**: Background noise session duration settings
  - **Connected to**: `NoiseSessionView.swift`
  - **Key features**: Session timing, auto-stop options

- **`NoiseActivityAttributes.swift`**
  - **What it does**: Live Activity configuration for background noise
  - **Connected to**: iOS system integration
  - **Key features**: Lock screen controls, notification center integration

### Models/Meditation/ - Meditation Data Models
**Purpose**: Additional meditation-related data structures.

#### Files:
- **`StreakStore.swift`**
  - **What it does**: Tracks user meditation streaks and statistics
  - **Connected to**: `MeditationSessionView.swift` (completion tracking)
  - **Key features**: Daily streaks, completion counting, persistence

---

## ⚙️ Services/ - Business Logic and External Services

### Services/Breathing/ - Breathing Exercise Services
**Purpose**: Handles breathing exercise logic and audio feedback.

#### Files:
- **`HapticBreathEngine.swift`**
  - **What it does**: Manages haptic feedback during breathing exercises
  - **Connected to**: `BreathingSessionView.swift`, `BoxBreathingView.swift`
  - **Key features**: Breath cycle haptics, pattern synchronization

### Services/Meditation/ - Meditation Services
**Purpose**: Handles meditation audio playback and session management.

#### Files:
- **`MeditationAudioEngine.swift`**
  - **What it does**: Manages meditation audio playback, seeking, and completion
  - **Connected to**: `MeditationSessionView.swift`
  - **Key features**: Audio playback, fast-forward/rewind, completion detection, notification posting
  - **Core Methods**: `play()`, `pause()`, `stop()`, `skipForward()`, `seek()`, `meditationCompleted()`

### Services/Noise/ - Background Noise Services
**Purpose**: Handles background noise playback and mixing.

#### Files:
- **`NoiseEngine.swift`**
  - **What it does**: Manages background noise playback and mixing
  - **Connected to**: `NoiseSessionView.swift`, `BackgroundNoiseView.swift`
  - **Key features**: Multiple noise mixing, volume control, session management

- **`NoiseLiveActivityManager.swift`**
  - **What it does**: Manages Live Activity integration for background noise
  - **Connected to**: iOS system integration
  - **Key features**: Lock screen controls, notification center integration

### Services/ - General Services
**Purpose**: Shared services used across multiple features.

#### Files:
- **`Haptics.swift`**
  - **What it does**: Centralized haptic feedback management
  - **Connected to**: Used across all interactive views
  - **Key features**: Consistent haptic patterns, accessibility support

---

## 🛠️ Utils/ - Extensions and Utilities

### Utils/Extensions/ - Swift Extensions
**Purpose**: Extends Swift and SwiftUI types with custom functionality.

#### Files:
- **`Color+Hex.swift`**
  - **What it does**: Adds hex color support to SwiftUI Color
  - **Connected to**: Used throughout the app for consistent theming
  - **Key features**: Hex color parsing, theme color definitions

- **`View+Haptics.swift`**
  - **What it does**: Adds haptic feedback to SwiftUI views
  - **Connected to**: Used across interactive elements
  - **Key features**: Touch haptics, gesture haptics

### Utils/UI/ - UI Components and Helpers
**Purpose**: Reusable UI components and visual helpers.

#### Files:
- **`ProgressRing.swift`**
  - **What it does**: Custom circular progress indicator
  - **Connected to**: `MeditationSessionView.swift`, `BreathingSessionView.swift`
  - **Key features**: Animated progress, customizable styling

---

## 🎵 Resources/ - Assets and Media Files

### Resources/ - Main Resource Directory
**Purpose**: Contains all app assets, media files, and resources.

#### Contents:
- **Audio Files** (`*.mp3`)
  - **`2min.mp3`**: 2-minute meditation audio (1:50 actual duration)
  - **`5min.mp3`**: 5-minute meditation audio
  - **`10-min.mp3`**: 10-minute meditation audio
  - **`15min.mp3`**: 15-minute meditation audio
  - **`20min.mp3`**: 20-minute meditation audio
  - **`rain.mp3`**, **`ocean.mp3`**, **`forest.mp3`**: Background noise files

- **Lottie Animations** (`*.lottie`)
  - Breathing pattern animations
  - Meditation visual guides
  - Loading and transition animations

- **Fonts** (`fonts/`)
  - **`Amagro-Bold.ttf`**: Main app font for headings
  - **`AnekGujarati-Regular.ttf`**: Secondary font for body text
  - **`AnekGujarati-Medium.ttf`**: Medium weight variant

- **Media** (`media/`)
  - Additional media assets
  - Image resources
  - Video content

- **Images**
  - **`Welcome.png`**: Welcome screen background
  - App icons and branding assets

---

## 🎨 DesignSystem/ - Centralized Design System

### DesignSystem/ - Main Design System Directory
**Purpose**: Centralized design tokens and reusable components for consistent app styling.

#### Files:
- **`DesignSystem.swift`**
  - **What it does**: Defines design tokens (colors, typography, spacing, shadows)
  - **Connected to**: Used throughout all views for consistent styling
  - **Key features**: Color palette, font definitions, spacing scale, shadow styles

- **`DesignSystemIndex.swift`**
  - **What it does**: Provides easy import access to design system
  - **Connected to**: All views that need design system access
  - **Key features**: Single import point for design system

---

## 🚀 App Entry Point

### RespiratioApp.swift
**Purpose**: Main application entry point and configuration.

**What it does**:
- Initializes the app
- Sets up the main window
- Configures the root view

**Connected to**: iOS system, `ContentView.swift`

**Key features**:
- App lifecycle management
- Initial view setup
- System integration

---

## 🔗 Feature Connection Map

### User Flow Connections:

1. **App Launch**
   - `RespiratioApp.swift` → `ContentView.swift` → Tab Navigation

2. **Breathing Feature**
   - Tab → `BreathingView.swift` → `BreathingSessionView.swift`
   - `BreathingSessionView.swift` → `HapticBreathEngine.swift`
   - `BreathingSessionView.swift` → `BreathingExercise.swift`

3. **Meditation Feature**
   - Tab → `MeditationView.swift` → `MeditationSessionView.swift`
   - `MeditationSessionView.swift` → `MeditationAudioEngine.swift`
   - `MeditationSessionView.swift` → `MeditationPreset.swift`
   - `MeditationSessionView.swift` → `StreakStore.swift`

4. **Background Noise Feature**
   - Tab → `BackgroundNoiseView.swift` → `NoiseSessionView.swift`
   - `NoiseSessionView.swift` → `NoiseEngine.swift`
   - `NoiseSessionView.swift` → `NoiseCatalog.swift`

5. **Shared Components**
   - All views → `DesignSystem.swift` (styling)
   - All views → `Haptics.swift` (feedback)
   - All views → `NavBar.swift` (navigation)

---

## 📱 UI Page Mapping

### Main App Pages:
- **Tab Bar**: `ContentView.swift`
- **Breathing Selection**: `BreathingView.swift`
- **Breathing Session**: `BreathingSessionView.swift`
- **Meditation Selection**: `MeditationView.swift`
- **Meditation Session**: `MeditationSessionView.swift`
- **Background Noise**: `BackgroundNoiseView.swift`
- **Noise Session**: `NoiseSessionView.swift`

### Specialized Views:
- **Box Breathing**: `BoxBreathingView.swift`
- **Triangle Breathing**: `TriangleBreathingView.swift`
- **Lottie Breathing**: `LottieBreathingView.swift`
- **Welcome Screen**: `WelcomeView.swift`
- **Splash Screen**: `SplashScreenView.swift`

---

## 🛠️ Development Guidelines

### Adding New Features:
1. **Views**: Place in appropriate feature folder under `Views/`
2. **Models**: Add to corresponding feature folder under `Models/`
3. **Services**: Create in appropriate service folder under `Services/`
4. **Design**: Use tokens from `DesignSystem.swift`
5. **Navigation**: Follow existing tab structure in `ContentView.swift`

### File Naming Convention:
- **Views**: `[Feature][Component]View.swift`
- **Models**: `[Feature][Type].swift`
- **Services**: `[Feature][Type]Engine.swift` or `[Feature][Type]Service.swift`
- **Utilities**: `[Type]+[Extension].swift`

### Import Structure:
- **Design System**: `import DesignSystem`
- **Core Services**: Import specific service files
- **Models**: Import specific model files
- **Utilities**: Import specific utility files

---

## 🔧 Troubleshooting Common Issues

### Build Issues:
1. **Missing Dependencies**: Ensure all required files are in correct folders
2. **Import Errors**: Check file paths and import statements
3. **Design System Issues**: Verify `DesignSystem.swift` is properly configured

### Runtime Issues:
1. **Audio Problems**: Check `MeditationAudioEngine.swift` configuration
2. **Navigation Issues**: Verify tab structure in `ContentView.swift`
3. **Styling Problems**: Ensure design system tokens are properly applied

### Performance Issues:
1. **Animation Lag**: Check Lottie file sizes and complexity
2. **Memory Leaks**: Verify proper cleanup in service classes
3. **Audio Quality**: Check audio file formats and compression

---

This documentation provides a complete understanding of the Respiratio project structure, enabling developers to quickly locate files, understand connections, and maintain consistency across the codebase.
