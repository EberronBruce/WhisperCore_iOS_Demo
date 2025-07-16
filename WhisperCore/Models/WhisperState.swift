//
//  Whisper.swift
//  Whisper Core Demo
//
//  Created by Bruce Burgess on 7/12/25.
//
/*
 This is the main file that handles all the input to the WhisperContext. As the WhisperContext is more like the bridge or glue between the whisper.xcframe work and here. This is what will be used to call all the files. So this allows the user to sample an audio to get translation. Or to allow the user to record the audio to transcribe a recorded audio.
 */

import Foundation
import SwiftUI
import AVFoundation

internal protocol AudioRecorderProtocol {
    func startRecording(toOutputFile url: URL, delegate: AVAudioRecorderDelegate?) async throws
    func stopRecording() async
}

public protocol WhisperDelegate: AnyObject {
    func didTranscribe(_ text: String)
    func recordingFailed(_ error: Error)
    func failedToTranscribe(_ error: Error)
}


internal enum WhisperCoreError: Error {
    case missingRecordedFile
    case micPermissionDenied
    case modelNotLoaded
    case recordingFailed
}

extension WhisperCoreError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingRecordedFile:
            return "No recorded audio file found."
        case .micPermissionDenied:
            return "Microphone access denied."
        case .modelNotLoaded:
            return "Model has not been loaded."
        case .recordingFailed:
            return "Recoding has failed"
        }
    }
}



@MainActor
internal class WhisperState: NSObject, AVAudioRecorderDelegate {
    fileprivate(set) var isModelLoaded = false
    private(set) var messageLog = ""
    fileprivate(set) var canTranscribe = false
    private(set) var isRecording = false
    
    fileprivate var whisperContext: WhisperContextProtocol?
    fileprivate var recorder: AudioRecorderProtocol = Recorder()
    fileprivate var recordedFile: URL? = nil
    private var audioPlayer: AVAudioPlayer?
    fileprivate var isMicGranted: Bool = false
    
    private var playBackEnabled = false
    weak var delegate: WhisperDelegate?
    
    enum LoadError: Error, Equatable {
        case couldNotLocateModel
        case pathToModelEmpty
        case unableToLoadModel(String)
    }
    
    
    override init() {
        super.init()
    }
    
    func callRequestRecordPermission() {
        requestRecordPermission { granted in
            self.isMicGranted = granted
        }
    }
    
    func loadModel(at path: String, log: Bool = false, completion: @escaping (Result<Void, Error>) -> Void) {
        if path.isEmpty {
            messageLog += "No model path specified\n"
            completion(.failure(LoadError.pathToModelEmpty))
            return
        }
        guard FileManager.default.fileExists(atPath: path) else {
            messageLog += "Model file not found at \(path)\n"
            completion(.failure(LoadError.couldNotLocateModel))
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let context = try WhisperContext.createContext(path: path)
                Task { @MainActor in
                    self.whisperContext = context
                    self.canTranscribe = true
                    self.isModelLoaded = true
                    if log { self.messageLog += "Loaded model \(path)\n" }
                    completion(.success(()))
                }
            } catch {
                Task { @MainActor in
                    if log { self.messageLog += "\(error.localizedDescription)\n" }
                    completion(.failure(LoadError.unableToLoadModel(error.localizedDescription)))
                }
            }
        }
    }

    func loadModel(at path: String, log: Bool = false) async throws {
        try await withCheckedThrowingContinuation { continuation in
            loadModel(at: path, log: log) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    
    
    
    fileprivate func transcribeAudio(_ url: URL) async {
        guard isModelLoaded else {
            delegate?.failedToTranscribe(WhisperCoreError.modelNotLoaded)
            return
        }
        
        guard let whisperContext else {
            delegate?.failedToTranscribe(WhisperCoreError.modelNotLoaded)
            return
        }
        
        if (!canTranscribe) {
            messageLog += "Already transcribing \n"
            print("Already transcribing")
            return
        }
        
        do {
            canTranscribe = false
            messageLog += "Reading wave samples...\n"
            let data = try readAudioSamples(url)
            messageLog += "Transcribing data...\n"
            await whisperContext.fullTranscribe(samples: data)
            let text = await whisperContext.getTranscription()
            delegate?.didTranscribe(text)
            messageLog += "Done: \(text)\n"
        } catch {
            print(error.localizedDescription)
            messageLog += "\(error.localizedDescription)\n"
            delegate?.failedToTranscribe(error)
        }
        canTranscribe = true
    }
    
    func setAudioPlaybackEnable(_ playBack: Bool) {
        playBackEnabled = playBack
    }
    
    /// Optional override for tests
     var readAudioSamplesOverride: ((URL) throws -> [Float])?
    
    private func readAudioSamples(_ url: URL) throws -> [Float] {
        //This override is used for tests
        if let override = readAudioSamplesOverride {
            return try override(url)
        }
        
        stopPlayback()
        if(playBackEnabled) {
            try startPlayback(url)
        }
        return try decodeWaveFile(url)
    }
    
    
    func toggleRecord() async{
        if isRecording {
            await stopRecording()
        } else {
            await startRecording()
        }
    }
    
    func startRecording() async {
        if isMicGranted {
            do {
                self.stopPlayback()
                self.isRecording = true
                let file = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    .appending(path: "output.wav")
                try await self.recorder.startRecording(toOutputFile: file, delegate: self)
                self.recordedFile = file
            } catch {
                print(error.localizedDescription)
                self.messageLog += "\(error.localizedDescription)\n"
                self.isRecording = false
                delegate?.recordingFailed(error)
            }
        } else {
            requestRecordPermission { granted in
                self.isMicGranted = granted
                self.isRecording = false
                if granted {
                    Task {
                        await self.startRecording()
                    }
                } else {
                    self.delegate?.recordingFailed(WhisperCoreError.micPermissionDenied)
                }
            }
        }
    }
    
    func stopRecording() async  {
        await recorder.stopRecording()
        isRecording = false
        if let recordedFile {
            await transcribeAudio(recordedFile)
        } else {
            delegate?.recordingFailed(WhisperCoreError.missingRecordedFile)
        }
    }
    
    fileprivate func requestRecordPermission(response: @escaping (Bool) -> Void) {
#if os(macOS)
        response(true)
#else
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                response(granted)
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                response(granted)
            }
        }
#endif
    }
    
    private func startPlayback(_ url: URL) throws {
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.play()
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    // MARK: AVAudioRecorderDelegate
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error {
            Task {
                await handleRecError(error)
            }
        }
    }
    
    private func handleRecError(_ error: Error) {
        print(error.localizedDescription)
        messageLog += "\(error.localizedDescription)\n"
        isRecording = false
        delegate?.recordingFailed(error)
    }
    
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task {
            await onDidFinishRecording()
        }
    }
    
    private func onDidFinishRecording() {
        isRecording = false
    }
    

    func transcribeSample(_ sampleUrl: URL?) async {
        if let sampleUrl {
            await transcribeAudio(sampleUrl)
        } else {
            messageLog += "Could not locate sample\n"
            delegate?.failedToTranscribe(WhisperCoreError.missingRecordedFile)
        }
    }
    
    func reset() {
        stopPlayback()
        whisperContext = nil
        canTranscribe = false
        isModelLoaded = false
        recordedFile = nil
    }

    
#if DEBUG
    func benchCurrentModel() async {
        if whisperContext == nil {
            messageLog += "Cannot bench without loaded model\n"
            return
        }
        messageLog += "Running benchmark for loaded model\n"
        let result = await whisperContext?.benchFull(modelName: "<current>", nThreads: Int32(min(4, cpuCount())))
        if (result != nil) { messageLog += result! + "\n" }
    }
#endif
}


fileprivate func cpuCount() -> Int {
    ProcessInfo.processInfo.processorCount
}

extension Recorder: AudioRecorderProtocol {}


//Added for unit testing
internal class WhisperStateForTest: WhisperState {
    var permissionRequestHandler: ((@escaping (Bool) -> Void) -> Void)?
    
    override fileprivate func requestRecordPermission(response: @escaping (Bool) -> Void) {
        if let handler = permissionRequestHandler {
            handler(response)
        } else {
            super.requestRecordPermission(response: response)
        }
    }
    
    func setRecordedFile(_ url: URL?) {
        self.recordedFile = url
    }

    
    func injectMockContext(_ context: WhisperContextProtocol) {
        self.whisperContext = context
    }

    func setModelLoaded(_ val: Bool) {
        self.isModelLoaded = val
    }

    func setCanTranscribe(_ val: Bool) {
        self.canTranscribe = val
    }
    
    func testTranscribeAudio(_ URL: URL) async {
        await self.transcribeAudio(URL)
    }
    
    func injectMockRecorder(_ mock: AudioRecorderProtocol) {
        self.recorder = mock
    }

    func setMicPermission(_ granted: Bool) {
        self.isMicGranted = granted
    }
    
    func callRequestPermission(response: @escaping (Bool) -> Void) {
        requestRecordPermission(response: response)
    }
}
