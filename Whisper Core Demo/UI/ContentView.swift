//
//  ContentView.swift
//  Whisper Core Demo
//
//  Created by Bruce Burgess on 7/10/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var bridge = WhisperBridge()
    
    private var whisper = Whisper()

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
                            await whisper.transcribeSample(Bundle.main.url(forResource: "jfk", withExtension: "wav"))
                            canTranscribe = true
                        }
                        print(whisper.messageLog)
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
                            await whisper.toggleRecord()
                            isRecording = whisper.isRecording
//                            print(whisper.isRecording)
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
            whisper.delegate = bridge
            whisper.callRequestRecordPermission()
//            whisper.loadModel(at: Bundle.main.path(forResource: "ggml-base.en", ofType: "bin")!) { result in
//                print("**************************************************************")
//                switch result {
//                case .success:
//                    print("✅ Model loaded successfully.")
//                    whisper.setAudioPlaybackEnable(true)
//                    self.canTranscribe = whisper.canTranscribe
//                    self.isRecording = whisper.isRecording
//                case .failure(let error):
//                    print("❌ Failed to load model: \(error)")
//                }
//                self.isLoadingModel = false
//            }
            Task {
                do {
                    //try whisper.loadModel(at: Bundle.main.path(forResource: "ggml-base.en", ofType: "bin")!)
                    try await whisper.loadModel(at: Bundle.main.path(forResource: "ggml-base.en", ofType: "bin")!)
                    whisper.setAudioPlaybackEnable(true)
                    self.canTranscribe = whisper.canTranscribe
                    self.isRecording = whisper.isRecording

                } catch {
                    print("Failed to load model: \(error)")
                }
                self.isLoadingModel = false
            }
        }
    }
    

}

class WhisperBridge: ObservableObject, WhisperDelegate {
    @Published var translatedText: String = ""
    func didTranscribe(_ text: String) {
        DispatchQueue.main.async {
            self.translatedText = text
        }
    }
    
    func recordingFailed(_ error: any Error) {
        print("Failed To Record")
    }
    
    func failedToTranscribe(_ error: any Error) {
        print("Failed to transcribe")
    }
    
}


//#Preview {
//    ContentView()
//}
