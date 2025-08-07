//
//  ChordMatchGame.swift
//  music
//
//  Created by pc on 06.08.25.
//


import SwiftUI
import AVFoundation
import Combine

class ChordMatchGame: ObservableObject {
    private let soundService: SoundService
    
    @Published var currentChord: Chord?
    @Published var options: [Chord] = []
    @Published var score = 0
    @Published var isShowingAnswer = false
    
    init(soundService: SoundService) {
        self.soundService = soundService
    }
    
    func startNewRound() {
        // Generate random chord
        let root = Note.allCases.randomElement()!
        let type = ChordType.allCases.randomElement()!
        let octave = Int.random(in: 3...5)
        
        currentChord = Chord(root: root, type: type, octave: octave)
        
        // Generate options (including correct answer)
        options = generateOptions(correct: currentChord!)
        isShowingAnswer = false
    }
    
    private func generateOptions(correct: Chord) -> [Chord] {
        var opts = [correct]
        
        // Add 3 wrong options
        while opts.count < 4 {
            let root = Note.allCases.randomElement()!
            let type = ChordType.allCases.randomElement()!
            let candidate = Chord(root: root, type: type, octave: correct.octave)
            
            if !opts.contains(where: { $0.displayName == candidate.displayName }) {
                opts.append(candidate)
            }
        }
        
        return opts.shuffled()
    }
    
    func selectChord(_ chord: Chord) {
        guard let currentChord = currentChord else { return }
        
        if chord.displayName == currentChord.displayName {
            score += 1
        }
        isShowingAnswer = true
    }
    
    func playCurrentChord() {
        guard let chord = currentChord else { return }
        soundService.playChord(chord)
    }
    
    func playOption(_ chord: Chord) {
        soundService.playChord(chord)
    }
}