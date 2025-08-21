//
//  KeepAwakeToggle.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-21.
//

import SwiftUI

/// Small reusable toggle to keep the screen awake during a session.
struct KeepAwakeToggle: View {
    @State private var keepAwake = true

    var body: some View {
        Button {
            keepAwake.toggle()
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = keepAwake
            #endif
        } label: {
            Image(systemName: keepAwake ? "moon.zzz.fill" : "moon")
        }
        .accessibilityLabel(keepAwake ? "Keep screen awake" : "Allow auto‑lock")
    }
}
