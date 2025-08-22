//
//  NowPlayingManager.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-22.
//
import MediaPlayer

final class NowPlayingManager {
    static let shared = NowPlayingManager()
    private init() {}

    private var playHandler: (() -> Void)?
    private var pauseHandler: (() -> Void)?
    private var stopHandler: (() -> Void)?

    func configureRemotes(
        onPlay: @escaping () -> Void,
        onPause: @escaping () -> Void,
        onStop: @escaping () -> Void
    ) {
        playHandler = onPlay
        pauseHandler = onPause
        stopHandler  = onStop

        let c = MPRemoteCommandCenter.shared()
        c.playCommand.addTarget { [weak self] _ in self?.playHandler?(); return .success }
        c.pauseCommand.addTarget { [weak self] _ in self?.pauseHandler?(); return .success }
        c.stopCommand.addTarget { [weak self] _ in self?.stopHandler?(); return .success }
        c.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            // Your engine toggles internally; we call play() for simplicity
            self.playHandler?()
            return .success
        }
        c.changePlaybackPositionCommand.isEnabled = false
    }

    func set(title: String, artist: String = "Respiratio", artwork: MPMediaItemArtwork? = nil) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist
        ]
        if let artwork { info[MPMediaItemPropertyArtwork] = artwork }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func update(elapsed: TimeInterval, duration: TimeInterval?, isPlaying: Bool) {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        if let duration { info[MPMediaItemPropertyPlaybackDuration] = duration }
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func clear() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
