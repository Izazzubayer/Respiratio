//
//  SplashView.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-23.
//
import SwiftUI

struct SplashView: View {
    var onFinished: () -> Void

    // ⬅️ put your image name here (no extension)
    private let imageName = "splash-screen"

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 1.02

    var body: some View {
        ZStack {
            // Try assets → plain file in bundle → common alternate names.
            if let img = resolvedSplashImage() {
                img
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(opacity)
                    .scaleEffect(scale)
                    .accessibilityHidden(true)
            } else {
                // Fallback so app still looks intentional if the image isn't bundled yet
                Color(.systemBackground).ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading…")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .opacity(opacity)
                .scaleEffect(scale)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) { 
                opacity = 1; 
                scale = 1.0 
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                withAnimation(.easeIn(duration: 0.6)) { opacity = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { 
                    onFinished() 
                }
            }
        }
    }

    // MARK: - Image resolution helpers
    private func resolvedSplashImage() -> Image? {
        // 1) Asset or bundled image (no extension)
        if let ui = UIImage(named: imageName) { 
            return Image(uiImage: ui) 
        }

        // 2) Direct file in bundle (png/jpg)
        let extensions = ["png", "jpg", "jpeg"]
        for ext in extensions {
            if let url = Bundle.main.url(forResource: imageName, withExtension: ext),
               let data = try? Data(contentsOf: url),
               let ui = UIImage(data: data) {
                return Image(uiImage: ui)
            }
        }

        // 3) Common name variants (in case of accidental rename)
        let alternatives = ["splash_screen", "Splash", "splash"]
        for alt in alternatives {
            if let ui = UIImage(named: alt) { 
                return Image(uiImage: ui) 
            }
        }
        return nil
    }
}
