//
//  View+Haptics.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-21.
//

import SwiftUI

/// Adds haptics to any tap without altering the control's built-in visuals/styles.
struct HapticsOnTap: ViewModifier {
    let kind: Haptics.Kind
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded { Haptics.play(kind) }
        )
    }
}

extension View {
    /// Use on any Button / NavigationLink / tappable view.
    func hapticsOnTap(_ kind: Haptics.Kind = .light) -> some View {
        modifier(HapticsOnTap(kind: kind))
    }
}
