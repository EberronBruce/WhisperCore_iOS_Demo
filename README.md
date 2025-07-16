# WhisperCore iOS Demo

This repository contains the original Xcode project used to build [`WhisperCore`](https://github.com/EberronBruce/WhisperCore), a Swift package for real-time or file-based audio transcription using [Whisper.cpp](https://github.com/ggerganov/whisper.cpp).

It includes:
- ✅ Full source code for the Swift module
- ✅ A SwiftUI sample app for testing recording and transcription
- ✅ Unit tests for key components
- ✅ Working integration with `whisper.cpp` compiled into `.xcframework`s

> **Important**: This repo **does not include** the Whisper model binary due to file size constraints. You must manually download and add a model from [Whisper.cpp’s Hugging Face page](https://huggingface.co/ggerganov/whisper.cpp) to use this demo.

---

## 🔗 Related Repositories

- [WhisperCore (Swift Package)](https://github.com/EberronBruce/WhisperCore) – Reusable Swift library built from this demo project

---

## 🧪 Getting Started

1. Clone the repository.
2. Download a Whisper model (e.g., `ggml-base.en.bin`) and place it in
3. Build and run the app on device or simulator.
4. Test live transcription or sample audio file transcription via the UI.

---

## 📝 License

This project is released under the MIT License.

---

## 🙌 Credits

Built using:
- [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) by Georgi Gerganov
- Swift Concurrency + AVFoundation
