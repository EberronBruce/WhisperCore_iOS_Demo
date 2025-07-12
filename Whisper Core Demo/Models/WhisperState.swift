//
//  WhisperState.swift
//  Whisper Core Demo
//
//  Created by Bruce Burgess on 7/12/25.
//

import Foundation
import SwiftUI
import AVFoundation

protocol WhisperStateDelegate: AnyObject {
    func whisperStateDidTranscribe(_ text: String)
}


extension WhisperStateDelegate {
    func whisperStateDidFailRecording(_ error: Error) {}
    func whisperStateFailedToTranscribe(_ error: Error) {}
    func whisperStateDidFail(_ error: Error) {}
}

enum WhisperCoreError: Error {
    case missingRecordedFile
    case micPermissionDenied
    case modelNotLoaded
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
        }
    }
}



@MainActor
class WhisperState: NSObject, AVAudioRecorderDelegate {
    private(set) var isModelLoaded = false
    private(set) var messageLog = ""
    private(set) var canTranscribe = false
    private(set) var isRecording = false
    
    private var whisperContext: WhisperContext?
    private let recorder = Recorder()
    private var recordedFile: URL? = nil
    private var audioPlayer: AVAudioPlayer?
    private var isMicGranted: Bool = false
    
    private var playBackEnabled = false
    weak var delegate: WhisperStateDelegate?
    
    private var sampleUrl: URL? {
        Bundle.main.url(forResource: "jfk", withExtension: "wav")
    }
    
    private enum LoadError: Error {
        case couldNotLocateModel
        case pathToModelEmpty
        case unableToLoadModel(String)
    }
    
    
    override init() {
        super.init()
        requestRecordPermission { granted in
            self.isMicGranted = granted
        }
    }
    
    func loadModel(at path: String, log: Bool = false) throws {
        if path.isEmpty {
            messageLog += "No model path specified\n"
            throw LoadError.pathToModelEmpty
        }
        guard FileManager.default.fileExists(atPath: path) else {
            messageLog += "Model file not found at \(path)\n"
            throw LoadError.couldNotLocateModel
        }
        do {
            whisperContext = nil
            if (log) { messageLog += "Loading model...\n" }
            whisperContext = try WhisperContext.createContext(path: path)
            if (log) { messageLog += "Loaded model \(path)\n" }
            canTranscribe = true
            isModelLoaded = true
        } catch {
            print(error.localizedDescription)
            if (log) { messageLog += "\(error.localizedDescription)\n" }
            throw LoadError.unableToLoadModel(error.localizedDescription)
        }
    }
    
    
    
    private func transcribeAudio(_ url: URL) async {
        guard isModelLoaded else {
            delegate?.whisperStateDidFail(WhisperCoreError.modelNotLoaded)
            return
        }
        
        guard let whisperContext else {
            delegate?.whisperStateDidFail(WhisperCoreError.modelNotLoaded)
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
            delegate?.whisperStateDidTranscribe(text)
            messageLog += "Done: \(text)\n"
        } catch {
            print(error.localizedDescription)
            messageLog += "\(error.localizedDescription)\n"
            delegate?.whisperStateFailedToTranscribe(error)
        }
        canTranscribe = true
    }
    
    func setAudioPlaybackEnable(_ playBack: Bool) {
        playBackEnabled = playBack
    }
    
    private func readAudioSamples(_ url: URL) throws -> [Float] {
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
                delegate?.whisperStateDidFailRecording(error)
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
                    self.delegate?.whisperStateDidFail(WhisperCoreError.micPermissionDenied)
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
            delegate?.whisperStateDidFail(WhisperCoreError.missingRecordedFile)
        }
    }
    
    private func requestRecordPermission(response: @escaping (Bool) -> Void) {
#if os(macOS)
        response(true)
#else
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            response(granted)
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
        delegate?.whisperStateDidFailRecording(error)
    }
    
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task {
            await onDidFinishRecording()
        }
    }
    
    private func onDidFinishRecording() {
        isRecording = false
    }
    

    func transcribeSample() async {
        if let sampleUrl {
            await transcribeAudio(sampleUrl)
        } else {
            messageLog += "Could not locate sample\n"
            delegate?.whisperStateDidFail(WhisperCoreError.missingRecordedFile)
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

