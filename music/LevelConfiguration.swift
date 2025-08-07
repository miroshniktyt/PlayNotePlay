//
//  LevelConfiguration.swift
//  music
//
//  Created by pc on 07.08.25.
//

import Foundation
import SwiftUI

struct GameLevel {
    let melody: Melody
    let targetNotes: [Note]
    let configuration: LevelConfiguration
    let availableNotes: [Note] // The random notes available for this round
    
    static func generateLevel(from config: LevelConfiguration) -> GameLevel {
        // Generate random notes for the grid each round
        let availableNotes = config.randomizedNotes
        
        // Generate random melody from these available notes
        let selectedNotes = (0..<config.melodyLength).map { _ in
            availableNotes.randomElement()!
        }
        let melodyNotes = selectedNotes.map { ($0, 4, 0.5) } // octave 4, 0.5 second duration
        let melody = Melody(notes: melodyNotes, tempo: 120)
        
        return GameLevel(melody: melody, targetNotes: selectedNotes, configuration: config, availableNotes: availableNotes)
    }
}

// MARK: - Game State
enum GamePhase {
    case listening
    case playing
    case result
    case levelComplete
}

struct LevelConfiguration {
    let gridSize: Int
    let melodyLength: Int
    let availableNotes: [Note]
    let levelNumber: Int
    let streakToWin: Int
    
    static let allLevels: [LevelConfiguration] = [
        // Start simple: 2 notes, 2 melody
        LevelConfiguration(gridSize: 2, melodyLength: 2, availableNotes: [], levelNumber: 1, streakToWin: 5),
        
        // 3 notes, 2 melody  
        LevelConfiguration(gridSize: 3, melodyLength: 2, availableNotes: [], levelNumber: 2, streakToWin: 5),
        
        // 3 notes, 3 melody
        LevelConfiguration(gridSize: 3, melodyLength: 3, availableNotes: [], levelNumber: 3, streakToWin: 5),
        
        // 4 notes, 2 melody
        LevelConfiguration(gridSize: 4, melodyLength: 2, availableNotes: [], levelNumber: 4, streakToWin: 5),
        
        // 4 notes, 3 melody
        LevelConfiguration(gridSize: 4, melodyLength: 3, availableNotes: [], levelNumber: 5, streakToWin: 5),
        
        // 4 notes, 4 melody
        LevelConfiguration(gridSize: 4, melodyLength: 4, availableNotes: [], levelNumber: 6, streakToWin: 5),
        
        // 5 notes, 3 melody
        LevelConfiguration(gridSize: 5, melodyLength: 3, availableNotes: [], levelNumber: 7, streakToWin: 5),
        
        // 5 notes, 4 melody  
        LevelConfiguration(gridSize: 5, melodyLength: 4, availableNotes: [], levelNumber: 8, streakToWin: 5),
        
        // 5 notes, 5 melody
        LevelConfiguration(gridSize: 5, melodyLength: 5, availableNotes: [], levelNumber: 9, streakToWin: 5),
        
        // 6 notes, 3 melody
        LevelConfiguration(gridSize: 6, melodyLength: 3, availableNotes: [], levelNumber: 10, streakToWin: 5),
        
        // 6 notes, 4 melody
        LevelConfiguration(gridSize: 6, melodyLength: 4, availableNotes: [], levelNumber: 11, streakToWin: 5),
        
        // 6 notes, 5 melody
        LevelConfiguration(gridSize: 6, melodyLength: 5, availableNotes: [], levelNumber: 12, streakToWin: 5),
        
        // 6 notes, 6 melody
        LevelConfiguration(gridSize: 6, melodyLength: 6, availableNotes: [], levelNumber: 13, streakToWin: 5),
        
        // 7 notes, 4 melody
        LevelConfiguration(gridSize: 7, melodyLength: 4, availableNotes: [], levelNumber: 14, streakToWin: 5),
        
        // 7 notes, 5 melody
        LevelConfiguration(gridSize: 7, melodyLength: 5, availableNotes: [], levelNumber: 15, streakToWin: 5),
        
        // 7 notes, 6 melody
        LevelConfiguration(gridSize: 7, melodyLength: 6, availableNotes: [], levelNumber: 16, streakToWin: 5),
        
        // 8 notes, 5 melody
        LevelConfiguration(gridSize: 8, melodyLength: 5, availableNotes: [], levelNumber: 17, streakToWin: 5),
        
        // 8 notes, 6 melody
        LevelConfiguration(gridSize: 8, melodyLength: 6, availableNotes: [], levelNumber: 18, streakToWin: 5),
        
        // 9 notes, 5 melody
        LevelConfiguration(gridSize: 9, melodyLength: 5, availableNotes: [], levelNumber: 19, streakToWin: 5),
        
        // 9 notes, 6 melody
        LevelConfiguration(gridSize: 9, melodyLength: 6, availableNotes: [], levelNumber: 20, streakToWin: 5),
        
        // 9 notes, 7 melody (hardest)
        LevelConfiguration(gridSize: 9, melodyLength: 7, availableNotes: [], levelNumber: 21, streakToWin: 5),
    ]
    
    // Generate random notes for each level based on grid size
    var randomizedNotes: [Note] {
        let allNotes: [Note] = [.C, .CSharp, .D, .DSharp, .E, .F, .FSharp, .G, .GSharp, .A, .ASharp, .B]
        return Array(allNotes.shuffled().prefix(gridSize))
    }
    
    // Challenge mode: hardest configuration
    static let challengeMode = LevelConfiguration(
        gridSize: 9, 
        melodyLength: Int.random(in: 4...7), 
        availableNotes: [], 
        levelNumber: -1, 
        streakToWin: Int.max
    )
}
