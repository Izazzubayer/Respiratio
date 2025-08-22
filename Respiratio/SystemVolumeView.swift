//
//  SystemVolumeView.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-22.
//

import SwiftUI
import MediaPlayer
import Combine

/// Embeds MPVolumeView so slider + hardware buttons stay in sync.
/// Use `SystemVolumeSlider()` instead of a custom Slider.
struct SystemVolumeSlider: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let v = MPVolumeView(frame: .zero)
        v.showsRouteButton = false
        v.setVolumeThumbImage(nil, for: .normal)
        return v
    }
    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
