//
//  Haptics.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-21.
//

import UIKit

enum Haptics {
    enum Kind {
        case light, medium, heavy
        case rigid, soft
        case success, warning, error
        case selection
    }

    static func play(_ kind: Kind) {
        switch kind {
        case .light:   UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:  UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:   UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .rigid:   UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case .soft:    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning: UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:   UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .selection: UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}
