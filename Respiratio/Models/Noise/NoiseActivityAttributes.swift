//
//  NoiseActivityAttributes.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-22.
//

// FILE: NoiseActivityAttributes.swift
import ActivityKit

public struct NoiseActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var title: String
        public var remainingSeconds: Int?
        public var isPlaying: Bool

        public init(title: String, remainingSeconds: Int?, isPlaying: Bool) {
            self.title = title
            self.remainingSeconds = remainingSeconds
            self.isPlaying = isPlaying
        }
    }

    public init() {}
}
