import AVFoundation
import Foundation
import Speech

enum SpeechRecognitionError: LocalizedError {
    case notAuthorized, unavailable, audioEngineFailure

    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "Microphone and speech recognition permission are required."
        case .unavailable: return "Speech recognition isn’t available for this language on your device."
        case .audioEngineFailure: return "Could not start the microphone."
        }
    }
}

@MainActor
final class SpeechRecognitionService: ObservableObject {
    @Published var transcript = ""
    @Published private(set) var isRecording = false
    @Published private(set) var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private var audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.authorizationStatus = status
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }

    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func prepare(for language: Language) {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: language.speechLocaleIdentifier))
        if language == .tagalog, speechRecognizer?.isAvailable != true {
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "tl-PH"))
        }
    }

    func startRecording() throws {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.unavailable
        }
        stopRecording()
        transcript = ""

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { throw SpeechRecognitionError.audioEngineFailure }
        recognitionRequest.shouldReportPartialResults = true
        if #available(iOS 16, *) { recognitionRequest.addsPunctuation = true }

        let inputNode = audioEngine.inputNode
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result { self.transcript = result.bestTranscription.formattedString }
                if error != nil || (result?.isFinal ?? false) { self.finishRecording() }
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
    }

    func stopRecording() { finishRecording() }

    private func finishRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
