import SwiftUI
import DotLottie

struct LottieDemoView: View {
    @State private var isPlaying = false
    @State private var animationProgress: CGFloat = 0.0
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Lottie Animation Demo")
                .font(.title)
                .foregroundColor(.white)
            
            // Example 1: Basic Lottie animation from bundle
            VStack(spacing: 16) {
                Text("Breathing Animation")
                    .font(.headline)
                    .foregroundColor(.white)
                
                // This would load a .lottie or .json file from your assets
                // DotLottieAnimation(fileName: "breathing_animation", config: AnimationConfig(autoplay: true, loop: true)).view()
                    .frame(width: 200, height: 200)
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(12)
                
                Text("Placeholder for Lottie animation")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Example 2: Interactive controls
            VStack(spacing: 16) {
                Text("Interactive Controls")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 16) {
                    Button(action: {
                        isPlaying.toggle()
                    }) {
                        Text(isPlaying ? "Pause" : "Play")
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(isPlaying ? Color.orange : Color.blue)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        animationProgress = 0.0
                    }) {
                        Text("Reset")
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
            }
            
            // Example 3: Progress indicator
            VStack(spacing: 16) {
                Text("Animation Progress")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ProgressView(value: animationProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(width: 200)
                
                Text("\(Int(animationProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.10, green: 0.17, blue: 0.48))
    }
}

#Preview {
    LottieDemoView()
}
