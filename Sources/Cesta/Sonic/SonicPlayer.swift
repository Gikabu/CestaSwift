//
//  SonicPlayer.swift
//
//
//  Created by Jonathan Gikabu on 08/11/2023.
//

import AVFoundation

/// Responsible for loading and playing a single sound attached to a SwiftUI view.
public class SonicPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    public enum PlayingState {
        /// Sound/audio is currently playing.
        case playing
        /// Sound/audio has been paused.
        case paused
        /// Sound/audio has been stopped or is yet to be played.
        case none
    }
    
    /// Indicates the current player state.
    @Published public var state: PlayingState = .none

    /// The internal audio player being managed by this object.
    private var audioPlayer: AVAudioPlayer?
    
    /// Check if the sound is currently playing.
    public var playing: Bool {
        return state == .playing
    }
    
    /// Check if the sound is currently paused.
    public var paused: Bool {
        return state == .paused
    }

    /// How loud to play this sound relative to other sounds in your app,
    /// specified in the range 0 (no volume) to 1 (maximum volume).
    public var volume: Double {
        didSet {
            audioPlayer?.volume = Float(volume)
        }
    }

    /// How many times to repeat this sound. Specifying 0 here
    /// (the default) will play the sound only once.
    public var repeatCount: Sonic.RepeatCount {
        didSet {
            audioPlayer?.numberOfLoops = repeatCount.value
        }
    }

    /// Whether playback should restart from the beginning each time, or
    /// continue from the last playback point.
    public var playMode: Sonic.PlayMode


    /// Creates a new instance by looking for a particular sound filename in a bundle of your choosing.of `.reset`.
    /// - Parameters:
    ///   - sound: The name of the sound file you want to load.
    ///   - bundle: The bundle containing the sound file. Defaults to the main bundle.
    ///   - volume: How loud to play this sound relative to other sounds in your app,
    ///     specified in the range 0 (no volume) to 1 (maximum volume).
    ///   - repeatCount: How many times to repeat this sound. Specifying 0 here
    ///     (the default) will play the sound only once.
    ///   - playMode: Whether playback should restart from the beginning each time, or
    ///     continue from the last playback point.
    public init(sound: String, bundle: Bundle = .main, volume: Double = 1.0, repeatCount: Sonic.RepeatCount = 0, playMode: Sonic.PlayMode = .reset) {
        audioPlayer = Sonic.shared.prepare(sound: sound, from: bundle)

        self.volume = volume
        self.repeatCount = repeatCount
        self.playMode = playMode

        super.init()

        audioPlayer?.delegate = self
    }

    /// Plays the current sound. If `playMode` is set to `.reset` this will play from the beginning,
    /// otherwise it will play from where the sound last left off.
    public func play() {
        toggleState(.playing, resume: playMode == .continue)
    }
    
    /// Stops the audio from playing.
    public func stop() {
        toggleState(.none)
    }
    
    /// Pause current playback.
    public func pause() {
        toggleState(.paused)
    }
    
    /// Resume current playback.
    public func resume() {
        toggleState(.playing, resume: true)
    }
    
    private func toggleState(_ newState: PlayingState, resume: Bool = false) {
        state = newState
        switch newState {
        case .playing:
            if !resume {
                audioPlayer?.currentTime = 0
            }
            audioPlayer?.play()
        case .paused:
            audioPlayer?.pause()
        case .none:
            audioPlayer?.stop()
        }
    }

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        state = .none
    }
}
