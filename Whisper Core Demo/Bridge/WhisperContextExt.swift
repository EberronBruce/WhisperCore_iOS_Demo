//
//  WhisperContextExt.swift
//  Whisper Core Demo
//
//  Created by Bruce Burgess on 7/12/25.
//
/*
 This file was created in order to help allow for unit test to be writen and help create mocks for the test. 
 */

import Foundation

protocol WhisperContextProtocol {
    func fullTranscribe(samples: [Float]) async
    func getTranscription() async -> String
    func benchFull(modelName: String, nThreads: Int32) async -> String
}


extension WhisperContext: WhisperContextProtocol {}

