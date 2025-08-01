//
//  ViewModel.swift
//  PandaPad
//
//  Created by Atharv Kashyap on 8/14/24.
//

import AVFoundation
import Foundation
import Observation
import OpenAI

// Model for storing conversation history
struct ConversationEntry: Codable {
    let userInput: String
    let assistantResponse: String
}

class ConversationHistory {
    private(set) var entries: [ConversationEntry] = []
    
    func addEntry(userInput: String, assistantResponse: String) {
        let entry = ConversationEntry(userInput: userInput, assistantResponse: assistantResponse)
        entries.append(entry)
        saveToDisk()
    }
    
    func loadFromDisk() {
        let url = historyFileURL()
        if let data = try? Data(contentsOf: url),
           let savedEntries = try? JSONDecoder().decode([ConversationEntry].self, from: data) {
            entries = savedEntries
        }
    }
    
    private func saveToDisk() {
        let url = historyFileURL()
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: url)
        }
    }
    
    func clearHistory() {
        entries.removeAll()
        saveToDisk()
    }
    
    
    private func historyFileURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("conversationHistory.json")
    }
}

@Observable
class ViewModel: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    let openAIManager = OpenAIManager.shared
    
    var audioPlayer: AVAudioPlayer!
    var audioRecorder: AVAudioRecorder!
    #if !os(macOS)
    var recordingSession = AVAudioSession.sharedInstance()
    #endif
    var recordingTimer: Timer?
    var audioPower = 0.0
    var prevAudioPower: Double?
    var processingSpeechTask: Task<Void, Never>?
    var shouldEndConversation = false
    
    
    var captureURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("recording.m4a")
    }
    
    var state = VoiceChatState.idle {
        didSet { print(state) }
    }
    var isIdle: Bool {
        if case .idle = state {
            return true
        }
        return false
    }

    private let conversationHistory = ConversationHistory()
    
    override init() {
        super.init()
        conversationHistory.loadFromDisk()
        #if !os(macOS)
        do {
            #if os(iOS)
            try recordingSession.setCategory(.playAndRecord, options: .defaultToSpeaker)
            #else
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            #endif
            try recordingSession.setActive(true)
            
            AVAudioApplication.requestRecordPermission { [unowned self] allowed in
                if !allowed {
                    self.state = .error("Recording not allowed by the user" as! Error)
                }
            }
        } catch {
            state = .error(error)
        }
        #endif
    }
    
    func startCaptureAudio() {
        resetValues()
        state = .recordingSpeech
        do {
            audioRecorder = try AVAudioRecorder(url: captureURL,
                                                settings: [
                                                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                                                    AVSampleRateKey: 12000,
                                                    AVNumberOfChannelsKey: 1,
                                                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                                                ])
            audioRecorder.isMeteringEnabled = true
            audioRecorder.delegate = self
            audioRecorder.record()
            
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { [unowned self]_ in
                guard self.audioRecorder != nil else { return }
                self.audioRecorder.updateMeters()
                let power = min(1, max(0, 1 - abs(Double(self.audioRecorder.averagePower(forChannel: 0)) / 50) ))
                if self.prevAudioPower == nil {
                    self.prevAudioPower = power
                    return
                }
                if let prevAudioPower = self.prevAudioPower, prevAudioPower < 0.35 && power < 0.25 { // changed from 0.25 and 0.175
                    self.finishCaptureAudio()
                    return
                }
                self.prevAudioPower = power
            })
            
        } catch {
            resetValues()
            state = .error(error)
        }
    }
    
    func finishCaptureAudio() {
        resetValues()
        do {
            let data = try Data(contentsOf: captureURL)
            processingSpeechTask = processSpeechTask(audioData: data)
        } catch {
            state = .error(error)
            resetValues()
        }
    }
    
    func processSpeechTask(audioData: Data) -> Task<Void, Never> {
        Task { @MainActor [unowned self] in
            do {
                self.state = .processingSpeech
                
                // Transcribe the audio using the new OpenAI API
                let transcriptionQuery = openAIManager.getTranscriptionQuery(for: audioData)
                let transcriptionResult = try await openAIManager.openAI.audioTranscriptions(query: transcriptionQuery)
                let prompt = transcriptionResult.text
                
                // Check for exit phrases
                if ExitPhraseHandling.isExitPhrase(in: prompt) {
                    shouldEndConversation = true
                    let data = try await openAIManager.handleChatAndSpeech(for: prompt, context: "respond very briefly in the same language", conversationHistory: conversationHistory)
                    try self.playAudio(data: data)
                    self.state = .idle
                    return // End the task early to avoid further processing
                }
                
                // Retrieve conversation history as context
                let context = conversationHistory.entries.map { "\($0.userInput): \($0.assistantResponse)" }.joined(separator: "\n")
                let outputspeech = try await openAIManager.handleChatAndSpeech(for: prompt, context: context, conversationHistory: conversationHistory)
                try self.playAudio(data: outputspeech)
                
            } catch {
                if Task.isCancelled { return }
                state = .error(error)
                resetValues()
            }
        }
    }
    
    func playAudio(data: Data) throws {
        self.state = .playingSpeech
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer.isMeteringEnabled = true
        audioPlayer.delegate = self
        audioPlayer.play()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if shouldEndConversation {
//            conversationHistory.clearHistory() // remove in final vers. + test
            state = .idle // End the conversation and reset to idle
            shouldEndConversation = false // Reset the flag
        } else {
            resetValues()
            startCaptureAudio() // Automatically start capturing audio after response finishes
        }
    }
    
    func cancelRecording() {
        resetValues()
        state = .idle
        // Do not reset conversation history
    }
    
    func cancelProcessingTask() {
        processingSpeechTask?.cancel()
        processingSpeechTask = nil
        resetValues()
        state = .idle
        // Do not reset conversation history
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            resetValues()
            state = .idle
        }
    }
    
    func resetValues() {
        audioPower = 0
        prevAudioPower = nil
        audioRecorder?.stop()
        audioRecorder = nil
        audioPlayer?.stop()
        audioPlayer = nil
        recordingTimer?.invalidate()
        recordingTimer = nil
        shouldEndConversation = false
    }
}
