//
//  WhisperContextExt.swift
//  Whisper Core Demo
//
//  Created by Bruce Burgess on 7/12/25.
//

import Foundation

protocol WhisperContextProtocol {
    func fullTranscribe(samples: [Float]) async
    func getTranscription() async -> String
    func benchFull(modelName: String, nThreads: Int32) async -> String
}


extension WhisperContext: WhisperContextProtocol {}

