////
////  Whisper_Core_DemoTests.swift
////  Whisper Core DemoTests
////
////  Created by Bruce Burgess on 7/10/25.
////
//
//import Testing
//import Foundation
//import AVFoundation
//@testable import Whisper_Core_Demo
//
//final class Dummy {}
//
//struct Whisper_Core_Utils {
//
//    @Test
//    func testDecodeWaveFile() async throws {
//        let testBundle = Bundle(for: Dummy.self)
//        guard let url = testBundle.url(forResource: "jfk", withExtension: "wav") else {
//            #expect(Bool(false), "Missing jfk.wav file in test bundle")
//            return
//        }
//
//     let floats = try decodeWaveFile(url)
//
//     #expect(!floats.isEmpty, "Decoded float array should not be empty")
//
//     let outOfRange = floats.contains { $0 < -1.0 || $0 > 1.0 }
//     #expect(!outOfRange, "Float values must be between -1.0 and 1.0")
//    }
//    
//    
//    @Test
//    func testStartAndStopRecording() async throws {
//        let recorder = Recorder()
//        
//        // Temporary file path for recording
//        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("testRecording.wav")
//        
//        do {
//            try await recorder.startRecording(toOutputFile: tempURL, delegate: nil)
//        } catch {
//            #expect(Bool(false), "startRecording threw an error: \(error)")
//            return
//        }
//        
//        await recorder.stopRecording()
//        
//        // Optional: Check if file was written
//        let exists = FileManager.default.fileExists(atPath: tempURL.path)
//        #expect(exists, "Recording file should exist at path")
//        
//        // Optional: Check if file is non-empty
//        if exists {
//            do {
//                let attrs = try FileManager.default.attributesOfItem(atPath: tempURL.path)
//                let fileSize = attrs[.size] as? UInt64 ?? 0
//                #expect(fileSize > 0, "Recorded file should not be empty")
//            } catch {
//                #expect(Bool(false), "Could not get file size: \(error)")
//            }
//            
//            // Clean up
//            do {
//                try FileManager.default.removeItem(at: tempURL)
//            } catch {
//                #expect(Bool(false), "Failed to delete temp file: \(error)")
//            }
//        }
//    }
//
//}
