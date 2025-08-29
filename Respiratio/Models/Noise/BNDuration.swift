//
//  BNDuration.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 22/8/25.
//

import Foundation

/// Represents how long a noise session should last
enum BNDuration: Hashable {
    case fiveMin
    case fifteenMin
    case thirtyMin
    case oneHour
    case infinite
    case minutes(Int)

    var timeInterval: TimeInterval? {
        switch self {
        case .fiveMin: return 5 * 60
        case .fifteenMin: return 15 * 60
        case .thirtyMin: return 30 * 60
        case .oneHour: return 60 * 60
        case .infinite: return nil
        case .minutes(let m): return TimeInterval(m * 60)
        }
    }
}
