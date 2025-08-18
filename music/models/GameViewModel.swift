//
//  GameViewModel.swift
//  PlayXFlash
//
//  Created by pc on 18.08.25.
//


import Foundation
import SwiftUI

class GameViewModel: ObservableObject {
    @Published var currentLevel: GameLevel
    @Published var phase: GamePhase = .listening
    @Published var selectedNote: Note? = nil
    @Published var userMelody: [Note?] = []
    @Published var correctStreak: Int = 0
    @Published var feedback: [Bool] = [] // true for correct, false for incorrect
    @Published var isComplete: Bool = false
    @Published var isLevelWon: Bool = false
    @Published var playingNoteIndex: Int? = nil // For animation during melody playback
    @Published var hasListenedToMelody: Bool = false // Track if user has listened to melody
    
    // AppStorage for progress tracking
    @AppStorage("unlockedLevels") private var unlockedLevelsData: Data = Data()
    @AppStorage("challengeBestStreak") var challengeBestStreak: Int = 0
    
    private let soundService: SoundServiceProtocol
    let configuration: LevelConfiguration
    private let isChallenge: Bool
    
    var unlockedLevels: Set<Int> {
        get {
            (try? JSONDecoder().decode(Set<Int>.self, from: unlockedLevelsData)) ?? [1]
        }
        set {
            unlockedLevelsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    var noteGrid: [Note] {
        return currentLevel.availableNotes
    }
    
    var isStreakSufficient: Bool {
        return correctStreak >= configuration.streakToWin
    }
    
    init(soundService: SoundServiceProtocol, configuration: LevelConfiguration, isChallenge: Bool = false) {
        self.soundService = soundService
        self.configuration = configuration
        self.isChallenge = isChallenge
        self.currentLevel = GameLevel.generateLevel(from: configuration)
        self.userMelody = Array(repeating: nil, count: configuration.melodyLength)
    }
    
    func playTargetMelody() {
        hasListenedToMelody = true
        playMelodyWithAnimation(currentLevel.melody)
    }
    
    func playUserMelody() {
        let userNotes = userMelody.compactMap { $0 }
        guard !userNotes.isEmpty else { return }
        
        let melodyNotes = userNotes.map { ($0, 4, 0.5) }
        let melody = Melody(notes: melodyNotes, tempo: 120)
        playMelodyWithAnimation(melody)
    }
    
    private func playMelodyWithAnimation(_ melody: Melody) {
        Task {
            let beatDuration = 60.0 / melody.tempo
            
            for (index, (note, octave, duration)) in melody.notes.enumerated() {
                await MainActor.run {
                    self.playingNoteIndex = index
                }
                
                soundService.playNote(note, octave: octave, duration: beatDuration * duration)
                
                try? await Task.sleep(nanoseconds: UInt64(beatDuration * duration * 1_000_000_000))
            }
            
            await MainActor.run {
                self.playingNoteIndex = nil
            }
        }
    }
    
    func selectNote(_ note: Note) {
        selectedNote = note
        soundService.playNote(note, octave: 4, duration: 0.3)
    }
    
    func placeNoteInSlot(_ slotIndex: Int) {
        guard let selectedNote = selectedNote else { return }
        userMelody[slotIndex] = selectedNote
    }
    
    func checkAnswer() {
        let userNotes = userMelody.compactMap { $0 }
        guard userNotes.count == configuration.melodyLength else { return }
        
        feedback = zip(userNotes, currentLevel.targetNotes).map { $0 == $1 }
        let isCorrect = feedback.allSatisfy { $0 }
        
        if isCorrect {
            correctStreak += 1
            isComplete = true
            
            // Check if level is won (streak sufficient)
            if isStreakSufficient && !isChallenge {
                isLevelWon = true
                unlockNextLevel()
                phase = .levelComplete
                return
            }
            
            // Update challenge best streak
            if isChallenge && correctStreak > challengeBestStreak {
                challengeBestStreak = correctStreak
            }
        } else {
            correctStreak = 0
            isComplete = false
        }
        
        phase = .result
    }
    
    func unlockNextLevel() {
        let nextLevelNumber = configuration.levelNumber + 1
        if nextLevelNumber <= LevelConfiguration.allLevels.count {
            var unlocked = unlockedLevels
            unlocked.insert(nextLevelNumber)
            unlockedLevels = unlocked
        }
    }
    
    func nextLevel() {
        if isChallenge {
            // Generate new challenge level with random melody length
            let challengeConfig = LevelConfiguration(
                gridSize: 9,
                melodyLength: Int.random(in: 4...7),
                availableNotes: [],
                levelNumber: -1,
                streakToWin: Int.max
            )
            currentLevel = GameLevel.generateLevel(from: challengeConfig)
            userMelody = Array(repeating: nil, count: challengeConfig.melodyLength)
        } else {
            currentLevel = GameLevel.generateLevel(from: configuration)
            userMelody = Array(repeating: nil, count: configuration.melodyLength)
        }
        
        phase = .listening
        selectedNote = nil
        feedback = []
        isComplete = false
        isLevelWon = false
        hasListenedToMelody = false // Reset melody listening state
    }
    
    func startPlaying() {
        phase = .playing
    }
    
    
}