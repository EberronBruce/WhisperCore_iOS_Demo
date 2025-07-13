//
//  ContentView.swift
//  Whisper Core Demo
//
//  Created by Bruce Burgess on 7/10/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var bridge = WhisperStateBridge()
    
    private var whisperState = WhisperState()

    @State var canTranscribe: Bool = false
    @State var isRecording = false
    @State private var isLoadingModel = true
    
    var body: some View {
        VStack {
            if isLoadingModel {
                ProgressView("Loading Whisper model...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                
                VStack(spacing: 40) {
                    Text(bridge.translatedText)
                        .font(.title)
                    Button("Test With Sample") {
                        print("Testing Sample")
                        canTranscribe = false
                        Task {
                            await whisperState.transcribeSample()
                            canTranscribe = true
                        }
                        print(whisperState.messageLog)
                    }
                    .disabled(!canTranscribe)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                    
                    Button(isRecording ? "Stop Recording Microphone" : "Start Recording Microphone") {
                        Task {
                            await whisperState.toggleRecord()
                            isRecording = whisperState.isRecording
//                            print(whisperState.isRecording)
                        }
                    }
                    .disabled(!canTranscribe)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                    
                }
            }
        }

        .padding()
        .onAppear() {
            whisperState.delegate = bridge
//            whisperState.loadModel(at: Bundle.main.path(forResource: "ggml-base.en", ofType: "bin")!) { result in
//                print("**************************************************************")
//                switch result {
//                case .success:
//                    print("✅ Model loaded successfully.")
//                    whisperState.setAudioPlaybackEnable(true)
//                    self.canTranscribe = whisperState.canTranscribe
//                    self.isRecording = whisperState.isRecording
//                case .failure(let error):
//                    print("❌ Failed to load model: \(error)")
//                }
//                self.isLoadingModel = false
//            }
            Task {
                do {
                    //try whisperState.loadModel(at: Bundle.main.path(forResource: "ggml-base.en", ofType: "bin")!)
                    try await whisperState.loadModel(at: Bundle.main.path(forResource: "ggml-base.en", ofType: "bin")!)
                    whisperState.setAudioPlaybackEnable(true)
                    self.canTranscribe = whisperState.canTranscribe
                    self.isRecording = whisperState.isRecording

                } catch {
                    print("Failed to load model: \(error)")
                }
                self.isLoadingModel = false
            }
        }
    }
    

}

class WhisperStateBridge: ObservableObject, WhisperStateDelegate {
    func whisperStateDidFailRecording(_ error: any Error) {
        print("Failed To Record")
    }
    
    func whisperStateFailedToTranscribe(_ error: any Error) {
        print("Failed to transcribe")
    }
    
    @Published var translatedText: String = ""

    func whisperStateDidTranscribe(_ text: String) {
        DispatchQueue.main.async {
            self.translatedText = text
        }
    }

    // Optional error methods already have default implementations
}


//#Preview {
//    ContentView()
//}
