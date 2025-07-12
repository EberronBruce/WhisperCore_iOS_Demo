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
    
    var body: some View {
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
                    print(whisperState.isRecording)
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
        
        .padding()
        .onAppear() {
            whisperState.delegate = bridge
            Task {
                do {
                    try whisperState.loadModel(at: Bundle.main.path(forResource: "ggml-base.en", ofType: "bin")!)
                    whisperState.setAudioPlaybackEnable(true)
                    self.canTranscribe = whisperState.canTranscribe
                    self.isRecording = whisperState.isRecording
                } catch {
                    print("Failed to load model: \(error)")
                }

            }
        }
    }
    

}

class WhisperStateBridge: ObservableObject, WhisperStateDelegate {
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
