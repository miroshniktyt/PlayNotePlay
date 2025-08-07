//
//  SoundService.swift
//  music
//
//  Created by pc on 06.08.25.
//


import SwiftUI
import AVFoundation
import Combine

protocol SoundServiceProtocol {
    func playNote(_ note: Note, octave: Int, duration: Double)
    func playChord(_ chord: Chord, duration: Double)
    func playMelody(_ melody: Melody)
    func stopAll()
}

class SoundService: SoundServiceProtocol, ObservableObject {
    private let audioEngine: AudioEngine
    private var currentPlayers: Set<AVAudioPlayerNode> = []
    private let playerAccessQueue = DispatchQueue(label: "com.ear-training.playerAccessQueue", attributes: .concurrent)
    private var melodyTask: Task<Void, Never>?

    @Published var isPlaying = false
    @Published var isMelodyPlaying = false
    
    init() {
        self.audioEngine = AudioEngine()
    }
    
    func playNote(_ note: Note, octave: Int = 4, duration: Double = 1.0) {
        let frequency = note.frequency(octave: octave)
        
        guard let buffer = audioEngine.createTone(
            frequency: frequency,
            duration: duration,
            volume: 0.5
        ) else { return }
        
        let player = AVAudioPlayerNode()
        
        audioEngine.engine.attach(player)
        audioEngine.engine.connect(player, to: audioEngine.mixer, format: buffer.format)
        
        addPlayer(player)
        
        player.play()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts) { [weak self] in
            DispatchQueue.main.async {
                self?.removePlayer(player)
            }
        }
    }
    
    func playChord(_ chord: Chord, duration: Double = 2.0) {
        let players = chord.frequencies.compactMap { frequency -> AVAudioPlayerNode? in
            guard let buffer = audioEngine.createTone(
                frequency: frequency,
                duration: duration,
                volume: 0.3
            ) else { return nil }
            
            let player = AVAudioPlayerNode()
            audioEngine.engine.attach(player)
            audioEngine.engine.connect(player, to: audioEngine.mixer, format: buffer.format)
            
            player.scheduleBuffer(buffer, at: nil, options: .interrupts) { [weak self] in
                DispatchQueue.main.async {
                    self?.removePlayer(player)
                }
            }
            return player
        }
        
        players.forEach { addPlayer($0) }
        players.forEach { $0.play() }
    }
    
    func playMelody(_ melody: Melody) {
        stopAll()
        melodyTask = Task {
            await MainActor.run {
                self.isMelodyPlaying = true
            }
            
            let beatDuration = 60.0 / melody.tempo
            
            for (note, octave, duration) in melody.notes {
                if Task.isCancelled { break }
                
                let noteDuration = beatDuration * duration
                playNote(note, octave: octave, duration: noteDuration)
                
                try? await Task.sleep(nanoseconds: UInt64(noteDuration * 1_000_000_000))
            }
            
            await MainActor.run {
                self.isMelodyPlaying = false
            }
        }
    }

    func stopAll() {
        melodyTask?.cancel()
        melodyTask = nil

        playerAccessQueue.sync(flags: .barrier) {
            let playersToStop = self.currentPlayers
            self.currentPlayers.removeAll()
            
            DispatchQueue.main.async { [weak self] in
                playersToStop.forEach { player in
                    player.stop()
                    self?.audioEngine.engine.detach(player)
                }
                self?.isPlaying = false
                self?.isMelodyPlaying = false
            }
        }
    }

    private func addPlayer(_ player: AVAudioPlayerNode) {
        playerAccessQueue.async(flags: .barrier) { [weak self] in
            self?.currentPlayers.insert(player)
            DispatchQueue.main.async {
                self?.isPlaying = true
            }
        }
    }

    private func removePlayer(_ player: AVAudioPlayerNode) {
        playerAccessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            player.stop()
            self.audioEngine.engine.detach(player)
            self.currentPlayers.remove(player)

            if self.currentPlayers.isEmpty {
                DispatchQueue.main.async {
                    self.isPlaying = false
                }
            }
        }
    }
}
