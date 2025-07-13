//
//  Whisper_State_Tests.swift
//  Whisper Core Demo
//
//  Created by Bruce Burgess on 7/12/25.
//

import Testing
import Foundation
import AVFoundation
@testable import Whisper_Core_Demo


struct Whisper_Core_State {
    
    private func modelPath() -> String? {
        Bundle.main.path(forResource: "ggml-base.en", ofType: "bin")
    }
    
    @MainActor @Test
    func loadModel_closure_validPath_callsSuccess() async throws {
        let whisper = WhisperStateForTest()
        guard let path = Bundle.main.path(forResource: "ggml-base.en", ofType: "bin") else {
            throw WhisperState.LoadError.pathToModelEmpty
        }
        
        whisper.loadModel(at: path) { result in
            switch result {
            case .success:
                #expect(true, "Expected success but did not")
            case .failure(let error):
                #expect(Bool(false), "Expected success but did not: Error: \(error)")
            }
        }
        
    }
    
    @MainActor @Test
    func loadModel_closure_emptyPath_callsFailure() async throws {
        let whisper = WhisperStateForTest()
        
        whisper.loadModel(at: "") { result in
            switch result {
            case .success:
                #expect(Bool(false), "Expected failure but did not")
            case .failure(let error):
                #expect(error as! WhisperState.LoadError == WhisperState.LoadError.pathToModelEmpty, "Expected LoadError pathToModelEmpty but did not: Error: \(error)")
            }
        }
        
    }
    
    @MainActor @Test
    func loadModel_closure_invalidPath_callsFailure() async throws {
        let whisper = WhisperStateForTest()
        
        whisper.loadModel(at: "not-a-valid-path/model.bin") { result in
            switch result {
            case .success:
                #expect(Bool(false), "Expected failure but did not")
            case .failure(let error):
                #expect(error as! WhisperState.LoadError == WhisperState.LoadError.couldNotLocateModel, "Expected LoadError couldNotLocateModel but did not: Error: \(error)")
            }
        }
        
    }


    @MainActor @Test
    func loadModel_withValidPath() async throws {
        let whisper = WhisperStateForTest()
        
        guard let path = modelPath() else {
            fatalError("Test model file not found in bundle")
        }
        
        try await whisper.loadModel(at: path)
        
        // Validate state changes
        #expect(whisper.isModelLoaded == true, "Model is loaded flag is false, hence model did not load")
        #expect(whisper.canTranscribe == true, "Can Transcribe flag is flase, it did not get set correctly")
    }
    
    @MainActor @Test
    func loadModel_withEmptyPath() async throws {
        let whisper = WhisperStateForTest()
        
        do {
            try await whisper.loadModel(at: "")
            #expect(Bool(false), "Expected to throw but did not")
        } catch let error as WhisperState.LoadError {
            #expect(error == .pathToModelEmpty, "Expected .pathToModelEmpty, got \(error)")
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }
    
    @MainActor @Test
    func loadModel_withInvalidPath() async throws {
        let whisper = WhisperState()
        
        do {
            try await whisper.loadModel(at: "not-a-valid-path/model.bin")
            #expect(Bool(false), "Expected to throw but did not")
        } catch let error as WhisperState.LoadError {
            #expect(error == .couldNotLocateModel, "Expected .couldNotLocateModel, got \(error)")
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }
    
    @MainActor @Test
    func testTranscribeAudio_success() async throws {
        let state = WhisperStateForTest()
        let mockContext = MockWhisperContext()
        let mockDelegate = MockDelegate()
        
        state.injectMockContext(mockContext)
        state.delegate = mockDelegate
        state.setModelLoaded(true)
        state.setCanTranscribe(true)
        
        // Inject fake audio samples, avoiding playback and I/)
        state.readAudioSamplesOverride = { _ in
            return [0.0, 0.1, 0.2, 0.3, 0.4, 0.5]
        }
        
        await state.testTranscribeAudio(URL(fileURLWithPath: "/dummy/path.wav"))
        
        #expect(mockDelegate.transcribedText == "Mock transcription")
        #expect(mockDelegate.failedError == nil)
        #expect(state.canTranscribe == true)
    }
    
    @MainActor @Test
    func testTranscribeAudio_modelNotLoaded() async {
        let state = WhisperStateForTest()
        let mockDelegate = MockDelegate()

        state.delegate = mockDelegate
        state.setModelLoaded(false) // <- trigger failure
        state.setCanTranscribe(true)

        await state.testTranscribeAudio(URL(fileURLWithPath: "/dummy/path.wav"))
        
        let error = mockDelegate.failedError

        #expect(error as? WhisperCoreError == .modelNotLoaded)
        #expect(mockDelegate.transcribedText == nil)
    }

    @MainActor @Test
    func testTranscribeAudio_missingContext() async {
        let state = WhisperStateForTest()
        let mockDelegate = MockDelegate()

        state.delegate = mockDelegate
        state.setModelLoaded(true)
        state.setCanTranscribe(true)
        // ← do NOT inject whisperContext

        await state.testTranscribeAudio(URL(fileURLWithPath: "/dummy/path.wav"))

        #expect(mockDelegate.failedError as? WhisperCoreError == .modelNotLoaded)
        #expect(mockDelegate.transcribedText == nil)
    }
    

    @MainActor @Test
    func testTranscribeAudio_audioReadFails() async {
        let state = WhisperStateForTest()
        let mockContext = MockWhisperContext()
        let mockDelegate = MockDelegate()

        state.injectMockContext(mockContext)
        state.delegate = mockDelegate
        state.setModelLoaded(true)
        state.setCanTranscribe(true)

        state.readAudioSamplesOverride = { _ in
            throw DummyError.badAudio
        }

        await state.testTranscribeAudio(URL(fileURLWithPath: "/dummy/path.wav"))

        #expect(mockDelegate.failedError as? DummyError == .badAudio)
        #expect(mockDelegate.transcribedText == nil)
    }

    @MainActor @Test
    func testTranscribeAudio_alreadyTranscribing() async {
        let state = WhisperStateForTest()
        let mockContext = MockWhisperContext()
        let mockDelegate = MockDelegate()

        state.injectMockContext(mockContext)
        state.delegate = mockDelegate
        state.setModelLoaded(true)
        state.setCanTranscribe(false) // ← will short-circuit

        await state.testTranscribeAudio(URL(fileURLWithPath: "/dummy/path.wav"))

        #expect(mockDelegate.transcribedText == nil)
        #expect(mockDelegate.failedError == nil)
    }
    
    @Test
    @MainActor
    func testStartRecording_permissionGranted_success() async {
        let mockDelegate = MockDelegate()
        let state = WhisperStateForTest()
        let mockRecorder = MockRecorder()
        state.delegate = mockDelegate

        state.setMicPermission(true)
        state.injectMockRecorder(mockRecorder)

        await state.startRecording()

        #expect(state.isRecording == true)
        #expect(mockRecorder.didStartRecording == true)
        #expect(mockDelegate.failedError == nil)
    }

    @Test
    @MainActor
    func testStartRecording_permissionDenied() async {
        let mockDelegate = MockDelegate()
        let state = WhisperStateForTest()
        state.delegate = mockDelegate

        state.setMicPermission(false)

        // override permission request handler

        state.permissionRequestHandler = { completion in
            completion(false)
        }

        await state.startRecording()

        #expect(state.isRecording == false)
        #expect(mockDelegate.failedError as? WhisperCoreError == .micPermissionDenied)
    }
    
    @MainActor @Test
    func testStopRecording_withRecordedFile_shouldTranscribe() async {
        let state = WhisperStateForTest()
        let mockContext = MockWhisperContext()
        let mockDelegate = MockDelegate()
        let mockRecorder = MockRecorder()
        
        state.injectMockContext(mockContext)
        state.injectMockRecorder(mockRecorder)
        state.delegate = mockDelegate
        state.setModelLoaded(true)
        state.setCanTranscribe(true)
        
        // Stub a dummy file path
        let dummyFile = URL(fileURLWithPath: "/dummy/path.wav")
        state.setRecordedFile(dummyFile)

        // Override sample reader
        state.readAudioSamplesOverride = { _ in
            return [0.0, 0.1]
        }

        await state.stopRecording()
        
        #expect(state.isRecording == false)
        #expect(mockDelegate.transcribedText == "Mock transcription")
        #expect(mockDelegate.failedError == nil)
    }

    @MainActor @Test
    func testStopRecording_withoutRecordedFile_shouldFail() async {
        let state = WhisperStateForTest()
        let mockDelegate = MockDelegate()
        let mockRecorder = MockRecorder()

        state.injectMockRecorder(mockRecorder)
        state.delegate = mockDelegate
        state.setModelLoaded(true)
        state.setCanTranscribe(true)

        // Do NOT set recordedFile (leave as nil)
        
        await state.stopRecording()

        #expect(state.isRecording == false)
        #expect(mockDelegate.failedError as? WhisperCoreError == .missingRecordedFile)
        #expect(mockDelegate.transcribedText == nil)
    }


 

}


class MockWhisperContext: WhisperContextProtocol {
    func benchFull(modelName: String, nThreads: Int32) async -> String {
        return "Run benchmark mock"
    }
    
    func fullTranscribe(samples: [Float]) async {
        // simulate work
    }
    func getTranscription() async -> String {
        return "Mock transcription"
    }
}

enum DummyError: Error, Equatable {
    case badAudio
}


class MockDelegate: WhisperStateDelegate {
    var transcribedText: String? = nil
    var failedError: Error? = nil

    func whisperStateDidTranscribe(_ text: String) {
        transcribedText = text
    }

    func whisperStateFailedToTranscribe(_ error: Error) {
        failedError = error
    }
    
    func whisperStateDidFailRecording(_ error: Error) {
        failedError = error
    }

}

class MockRecorder: AudioRecorderProtocol {
    var shouldSucceed = true
    var didStartRecording = false

    func startRecording(toOutputFile url: URL, delegate: AVAudioRecorderDelegate?) async throws {
        if shouldSucceed {
            didStartRecording = true
        } else {
            throw WhisperCoreError.recordingFailed
        }
    }

    func stopRecording() {}
}




