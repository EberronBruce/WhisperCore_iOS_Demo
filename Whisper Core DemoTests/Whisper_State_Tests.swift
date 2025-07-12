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
    func loadModel_withValidPath() throws {
        let whisper = WhisperState()
        
        guard let path = modelPath() else {
            fatalError("Test model file not found in bundle")
        }
        
        try whisper.loadModel(at: path)
        
        // Validate state changes
        #expect(whisper.isModelLoaded == true, "Model is loaded flag is false, hence model did not load")
        #expect(whisper.canTranscribe == true, "Can Transcribe flag is flase, it did not get set correctly")
    }
    
    @MainActor @Test
    func loadModel_withEmptyPath() throws {
        let whisper = WhisperState()
        
        do {
            try whisper.loadModel(at: "")
            fatalError("Expected to throw but did not")
            
        } catch let error as WhisperState.LoadError {
            #expect(error == .pathToModelEmpty)
        }
    }
    
    @MainActor @Test
    func loadModel_withInvalidPath() throws {
        let whisper = WhisperState()
        
        do {
            try whisper.loadModel(at: "not-a-valid-path/model.bin")
            fatalError("Expected to throw but did not")
        } catch let error as WhisperState.LoadError {
            #expect(error == .couldNotLocateModel)
        }
    }
    
    @MainActor @Test
    func testTranscribeAudio_success() async throws {
        let state = WhisperStateForTest()
        let mockContext = MockWhisperContext()
        let mockDelegate = MockDelegate()
        
        state.injectMockContext(mockContext)
//        state.delegate = mockDelegate
//        state.isModelLoaded = true
//        state.canTranscribe = true
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

class MockDelegate: WhisperStateDelegate {
    var transcribedText: String? = nil
    var failedError: Error? = nil

    func whisperStateDidTranscribe(_ text: String) {
        transcribedText = text
    }

    func whisperStateFailedToTranscribe(_ error: Error) {
        failedError = error
    }
}


