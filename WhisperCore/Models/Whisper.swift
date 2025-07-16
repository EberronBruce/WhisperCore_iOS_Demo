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
    
    /// Indicates whether Whisper is ready to perform transcription.
    ///
    /// Returns `true` if the model is loaded and audio input is enabled,
    /// otherwise `false`. This is useful for enabling or disabling UI elements.
    ///
    /// - Returns: A Boolean indicating transcription readiness.
    public func canTranscribe() -> Bool {
        whisper.canTranscribe
    }
    
    /// Indicates whether audio recording is currently active.
    ///
    /// Returns `true` if Whisper is recording from the microphone, `false` otherwise.
    /// This can be used to update UI elements (e.g., recording indicators or buttons).
    ///
    /// - Returns: A Boolean indicating the recording state.
    public func isRecording() -> Bool {
        whisper.isRecording
    }
    
    /// Checks whether a Whisper model has been successfully loaded.
    ///
    /// Returns `true` if a model is loaded and ready for transcription,
    /// otherwise `false`. This is useful to validate app state before starting recording or transcription.
    ///
    /// - Returns: A Boolean indicating if a model is currently loaded.
    public func isModelLoaded() -> Bool {
        whisper.isModelLoaded
    }
    
    /// Returns a string containing the internal log messages from Whisper.
    ///
    /// This includes debug output, status messages, and benchmark results
    /// (if available). You can expose this in developer builds or log it
    /// to external tools for troubleshooting.
    ///
    /// - Returns: A string of accumulated internal messages and logs.
    public func getMessageLogs() -> String {
        whisper.messageLog
    }
        
    #if DEBUG
    /// Runs a benchmark test on the currently loaded model (DEBUG only).
    ///
    /// Measures the time it takes to process a dummy audio file using the
    /// loaded model and prints the results to the console. Use this to gauge
    /// performance across different devices or model sizes.
    ///
    /// - Note: This function is only available in DEBUG builds.
    public func benchmark() async {
        await whisper.benchCurrentModel()
        print(whisper.messageLog)
    }
    #endif
    
}
