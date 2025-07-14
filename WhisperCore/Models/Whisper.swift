//
//  WhisperAPI.swift
//  Whisper Core Demo
//
//  Created by Bruce Burgess on 7/13/25.
//

import Foundation

@MainActor
public final class Whisper {
    private let whisper: WhisperState
    
    public init() {
        self.whisper = WhisperState()
    }
    
    /// A delegate that receives updates about transcription results and recording errors.
    ///
    /// Use this to handle successful transcriptions, recording failures,
    /// and other relevant events.
    ///
    /// Example:
    /// ```swift
    /// whisper.delegate = self
    /// ```
    ///
    /// - Note: Your delegate class must conform to the `WhisperDelegate` protocol.
    public weak var delegate: WhisperDelegate? {
        get { whisper.delegate }
        set { whisper.delegate = newValue }
    }
    
    //MARK: Setup APIs
    
    /// Loads the Whisper model asynchronously from a given file path.
    ///
    /// - Parameter modelPath: The file system path to the Whisper model.
    /// - Throws: An error if loading the model fails.
    public func initializeModel(at modelPath: String, log: Bool = false) async throws {
        try await whisper.loadModel(at: modelPath, log: log)
    }
    
    /// Loads the Whisper model with a completion handler.
     ///
     /// - Parameters:
     ///   - modelPath: The file system path to the Whisper model.
     ///   - log: Whether to enable logging during load.
     ///   - completion: Completion handler called with success or failure.
    public func initializeModel(at modelPath: String, log: Bool = false, completion: @escaping (Result<Void, Error>) -> Void) {
        whisper.loadModel(at: modelPath, log: log, completion: completion)
    }
    
    /// Requests microphone permission from the user.
    ///
    /// Call this before attempting to record audio.
    public func callRequestRecordPermission() {
        whisper.callRequestRecordPermission()
    }
    
    //MARK: Function APIs
    
    /// Starts recording audio asynchronously.
    ///
    /// Requires microphone permission.
    public func startRecording() async {
        await whisper.startRecording()
    }
    
    /// Stops ongoing audio recording asynchronously.
    public func stopRecording() async {
        await whisper.stopRecording()
    }
    
    /// Toggles recording state asynchronously.
    ///
    /// If currently recording, stops recording. Otherwise, starts recording.
    public func toggleRecording() async {
        await whisper.toggleRecord()
    }
    
    /// Transcribes audio from a file URL asynchronously.
    ///
    /// - Parameter url: The URL of the audio file to transcribe.
    public func transcribeSample(from url: URL) async {
        await whisper.transcribeSample(url)
    }

    /// Enables or disables audio playback after transcription.
     ///
     /// - Parameter enabled: Set `true` to enable playback, `false` to disable.
    public func enablePlayback(_ enabled: Bool) {
        whisper.setAudioPlaybackEnable(enabled)
    }
    
    /// Resets the internal Whisper state.
    ///
    /// Call this to clear loaded model, transcription state, and stop playback.
    public func reset() {
        whisper.reset()
    }
    
    public func canTranscribe() -> Bool {
        whisper.canTranscribe
    }
    
    public func isRecording() -> Bool {
        whisper.isRecording
    }
    
    public func isModelLoaded() -> Bool {
        whisper.isModelLoaded
    }
    
    public func getMessageLogs() -> String {
        whisper.messageLog
    }
        
    #if DEBUG
    public func benchmark() async {
        await whisper.benchCurrentModel()
        print(whisper.messageLog)
    }
    #endif
    
}
