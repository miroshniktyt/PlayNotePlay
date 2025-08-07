import SwiftUI
import AVFoundation
import Combine

// MARK: - Core Sound Models

enum Note: String, CaseIterable {
    case C = "C", CSharp = "C#", D = "D", DSharp = "D#", E = "E", F = "F"
    case FSharp = "F#", G = "G", GSharp = "G#", A = "A", ASharp = "A#", B = "B"
    
    var frequency: Double {
        let noteIndex = Note.allCases.firstIndex(of: self) ?? 0
        // A4 = 440Hz, using equal temperament
        let semitonesFromA4 = noteIndex - 9 // A is at index 9
        return 440.0 * pow(2.0, Double(semitonesFromA4) / 12.0)
    }
    
    func frequency(octave: Int) -> Double {
        let baseFreq = self.frequency
        let octaveMultiplier = pow(2.0, Double(octave - 4)) // A4 as reference
        return baseFreq * octaveMultiplier
    }
}

enum ChordType: String, CaseIterable {
    case major = "Major"
    case minor = "Minor"
    case diminished = "Diminished"
    case augmented = "Augmented"
    case major7 = "Major 7th"
    case minor7 = "Minor 7th"
    case dominant7 = "Dominant 7th"
    
    var intervals: [Int] {
        switch self {
        case .major: return [0, 4, 7]
        case .minor: return [0, 3, 7]
        case .diminished: return [0, 3, 6]
        case .augmented: return [0, 4, 8]
        case .major7: return [0, 4, 7, 11]
        case .minor7: return [0, 3, 7, 10]
        case .dominant7: return [0, 4, 7, 10]
        }
    }
}

struct Chord {
    let root: Note
    let type: ChordType
    let octave: Int
    
    var notes: [Note] {
        let rootIndex = Note.allCases.firstIndex(of: root) ?? 0
        return type.intervals.map { interval in
            let noteIndex = (rootIndex + interval) % 12
            return Note.allCases[noteIndex]
        }
    }
    
    var frequencies: [Double] {
        return notes.map { note in
            note.frequency(octave: octave)
        }
    }
    
    var displayName: String {
        return "\(root.rawValue) \(type.rawValue)"
    }
}

struct Melody {
    let notes: [(Note, Int, Double)] // (note, octave, duration)
    let tempo: Double // BPM
    
    var totalDuration: Double {
        return notes.reduce(0) { $0 + $1.2 }
    }
}


@main
struct MusicApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if !hasSeenOnboarding {
                OnboardingView()
                    .preferredColorScheme(.dark)
            } else {
                MenuView()
                    .preferredColorScheme(.dark)
            }
        }
    }
}
