//
//  new.swift
//  music
//
//  Created by pc on 06.08.25.
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

// MARK: - Views
struct StreakGameView: View {
    @StateObject private var gameViewModel: GameViewModel
    private let configuration: LevelConfiguration
    private let isChallenge: Bool
    @State private var showingHelp = false
    
    init(configuration: LevelConfiguration, isChallenge: Bool = false) {
        self.configuration = configuration
        self.isChallenge = isChallenge
        self._gameViewModel = StateObject(wrappedValue: GameViewModel(
            soundService: SoundService(),
            configuration: configuration,
            isChallenge: isChallenge
        ))
    }
    
    var body: some View {
        ZStack {
            // Gaming background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color(red: 0.05, green: 0.1, blue: 0.25)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Gaming Header - Compact for small screens
                VStack {
                    if isChallenge {
                        HStack(spacing: 20) {
                            GamingStatCard(title: "STREAK", value: "\(gameViewModel.correctStreak)", color: .blue)
                            GamingStatCard(title: "BEST", value: "\(gameViewModel.challengeBestStreak)", color: .green)
                        }
                    } else {
                        VStack(spacing: 10) {
                            GamingProgressBar(
                                current: gameViewModel.correctStreak,
                                total: configuration.streakToWin,
                                title: "PROGRESS"
                            )
                            
                            if gameViewModel.isLevelWon {
                                Text("🏆 COMPLETE!")
                                    .font(.system(.callout, design: .rounded, weight: .black))
                                    .foregroundColor(.yellow)
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                            }
                        }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.top, 5)
                
                Spacer()
                
                // Game Content
                switch gameViewModel.phase {
                case .listening:
                    ListeningView(viewModel: gameViewModel)
                case .playing:
                    PlayingView(viewModel: gameViewModel)
                case .result:
                    ResultView(viewModel: gameViewModel)
                case .levelComplete:
                    LevelCompleteView(viewModel: gameViewModel)
                }
                
                Spacer()
            }
        }
        .navigationTitle(isChallenge ? "Challenge Mode" : "Level \(configuration.levelNumber)")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingHelp = true
                }) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingHelp) {
            if isChallenge {
                ChallengeHelpView()
            } else {
                LevelsHelpView()
            }
        }
    }
}

struct ListeningView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 25) {
            Text("🎧 Listen to the melody")
                .font(.system(.title2, design: .rounded, weight: .black))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)
            
            // Show melody slots preview with responsive layout - Compact for small screens
            VStack(spacing: 12) {
                Text("🎵 Melody preview:")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                
                let melodyCount = viewModel.currentLevel.melody.notes.count
                if melodyCount <= 5 {
                    // Single row for 5 or fewer notes
                    HStack(spacing: 6) {
                        ForEach(0..<melodyCount, id: \.self) { index in
                            PreviewSlot(
                                index: index + 1,
                                isPulsing: viewModel.playingNoteIndex == index
                            )
                        }
                    }
                } else {
                    // Two rows for 6+ notes - more compact
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            ForEach(0..<min(4, melodyCount), id: \.self) { index in
                                PreviewSlot(
                                    index: index + 1,
                                    isPulsing: viewModel.playingNoteIndex == index
                                )
                            }
                        }
                        if melodyCount > 4 {
                            HStack(spacing: 6) {
                                ForEach(4..<melodyCount, id: \.self) { index in
                                    PreviewSlot(
                                        index: index + 1,
                                        isPulsing: viewModel.playingNoteIndex == index
                                    )
                                }
                            }
                        }
                    }
                }
            }
            
            VStack(spacing: 20) {
                Button(action: {
                    viewModel.playTargetMelody()
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.cyan]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 4)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                    }
                }
                
                Text("🎵 Tap to play melody")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
            }
            
            GamingActionButton(
                title: viewModel.hasListenedToMelody ? "Start Challenge" : "Listen First!",
                icon: viewModel.hasListenedToMelody ? "play.fill" : "headphones",
                gradient: LinearGradient(
                    gradient: Gradient(colors: viewModel.hasListenedToMelody ? 
                        [Color.green, Color.mint] : 
                        [Color.gray.opacity(0.4), Color.gray.opacity(0.2)]
                    ),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                isDisabled: !viewModel.hasListenedToMelody,
                action: { 
                    if viewModel.hasListenedToMelody {
                        viewModel.startPlaying() 
                    }
                }
            )
            .padding(.horizontal)
        }
    }
}

struct PlayingView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🎹 Recreate the melody")
                .font(.system(.title3, design: .rounded, weight: .black))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)
            
            // Dynamic Note Grid
            let gridColumns = max(2, Int(ceil(sqrt(Double(viewModel.noteGrid.count)))))
            let gridRows = Int(ceil(Double(viewModel.noteGrid.count) / Double(gridColumns)))
            
            VStack(spacing: 8) {
                ForEach(0..<gridRows, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(0..<gridColumns, id: \.self) { col in
                            let index = row * gridColumns + col
                            if index < viewModel.noteGrid.count {
                                let note = viewModel.noteGrid[index]
                                NoteButton(
                                    note: note,
                                    isSelected: viewModel.selectedNote == note,
                                    action: { viewModel.selectNote(note) }
                                )
                            } else {
                                Spacer()
                                    .frame(width: 65, height: 65)
                            }
                        }
                    }
                }
            }
            
                        // Melody Slots with responsive layout - Compact
            VStack(spacing: 12) {
                Text("Your melody:")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                
                // Responsive melody slots layout - more compact spacing
                let melodyCount = viewModel.userMelody.count
                if melodyCount <= 5 {
                    // Single row for 5 or fewer notes
                    HStack(spacing: 6) {
                        ForEach(0..<melodyCount, id: \.self) { index in
                        MelodySlot(
                            note: viewModel.userMelody[index],
                            index: index + 1,
                            isPulsing: viewModel.playingNoteIndex == index,
                            action: { viewModel.placeNoteInSlot(index) }
                        )
                    }
                }
                } else {
                    // Two rows for 6+ notes - compact
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            ForEach(0..<min(4, melodyCount), id: \.self) { index in
                                MelodySlot(
                                    note: viewModel.userMelody[index],
                                    index: index + 1,
                                    isPulsing: viewModel.playingNoteIndex == index,
                                    action: { viewModel.placeNoteInSlot(index) }
                                )
                            }
                        }
                        if melodyCount > 4 {
                            HStack(spacing: 6) {
                                ForEach(4..<melodyCount, id: \.self) { index in
                                    MelodySlot(
                                        note: viewModel.userMelody[index],
                                        index: index + 1,
                                        isPulsing: viewModel.playingNoteIndex == index,
                                        action: { viewModel.placeNoteInSlot(index) }
                                    )
                                }
                            }
                        }
                    }
                }
            }
            
            // Gaming Control Buttons
            HStack(spacing: 15) {
                GamingControlButton(
                    title: "Play",
                    icon: "play.fill",
                    gradient: LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.cyan]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    action: { viewModel.playUserMelody() }
                )
                
                GamingControlButton(
                    title: "Submit",
                    icon: "checkmark.circle.fill",
                    gradient: LinearGradient(
                        gradient: Gradient(colors: viewModel.userMelody.contains(nil) ? 
                            [Color.green.opacity(0.4), Color.green.opacity(0.2)] :
                            [Color.green, Color.mint]
                        ),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    isDisabled: viewModel.userMelody.contains(nil),
                    action: { viewModel.checkAnswer() }
                )
            }
        }
        .padding()
    }
}

struct ResultView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var showingCorrectMelody = false
    @State private var showingUserMelody = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Result Header
            VStack(spacing: 10) {
                Image(systemName: viewModel.isComplete ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(viewModel.isComplete ? .green : .red)
                
                Text(viewModel.isComplete ? "Correct!" : "Try Again")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.isComplete ? .green : .red)
                
                if viewModel.isComplete {
                    Text("Streak: \(viewModel.correctStreak)")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
                            // Gaming Feedback Display with animation controls
            VStack(spacing: 15) {
                    Text("🔍 Compare melodies:")
                        .font(.system(.headline, design: .rounded, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                
                // User melody
                VStack(spacing: 10) {
                    HStack {
                        Text("Your Play Line:")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("Play") {
                            playUserMelodyWithAnimation()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 10) {
                        ForEach(0..<viewModel.userMelody.count, id: \.self) { index in
                            if let userNote = viewModel.userMelody[index] {
                                Text(userNote.rawValue)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(viewModel.feedback.count > index ?
                                                     (viewModel.feedback[index] ? .green : .red) : Color(.label))
                                    .frame(width: 40, height: 40)
                                    .background(Color(.secondarySystemFill))
                                    .cornerRadius(8)
                                    .scaleEffect(showingUserMelody && viewModel.playingNoteIndex == index ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.3), value: showingUserMelody && viewModel.playingNoteIndex == index)
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                
                // Target melody
                VStack(spacing: 10) {
                    HStack {
                        Text("Correct melody:")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("Play") {
                            playCorrectMelodyWithAnimation()
                        }
                        .font(.caption)
                        .foregroundColor(.green)
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 10) {
                        ForEach(0..<viewModel.currentLevel.targetNotes.count, id: \.self) { index in
                            Text(viewModel.currentLevel.targetNotes[index].rawValue)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                                .frame(width: 40, height: 40)
                                .background(Color.green.opacity(0.15))
                                .cornerRadius(8)
                                .scaleEffect(showingCorrectMelody && viewModel.playingNoteIndex == index ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: showingCorrectMelody && viewModel.playingNoteIndex == index)
                        }
                    }
                }
            }
            
            // Gaming Action Button
            GamingActionButton(
                title: viewModel.isComplete ? "Next Level" : "Try Again",
                icon: viewModel.isComplete ? "arrow.right" : "arrow.clockwise",
                gradient: LinearGradient(
                    gradient: Gradient(colors: viewModel.isComplete ? 
                        [Color.blue, Color.cyan] : 
                        [Color.orange, Color.red]
                    ),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                action: { viewModel.nextLevel() }
            )
            .padding(.horizontal)
        }
    }
    
    private func playUserMelodyWithAnimation() {
        showingUserMelody = true
        showingCorrectMelody = false
        viewModel.playUserMelody()
        
        // Reset after melody finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showingUserMelody = false
        }
    }
    
    private func playCorrectMelodyWithAnimation() {
        showingCorrectMelody = true
        showingUserMelody = false
        viewModel.playTargetMelody()
        
        // Reset after melody finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showingCorrectMelody = false
        }
    }
}

struct LevelCompleteView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Celebration
            VStack(spacing: 20) {
                Text("🎉")
                    .font(.system(size: 80))
                
                Text("Level Complete!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text("Great job! You've mastered Level \(viewModel.configuration.levelNumber)")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 10) {
                    Text("Streak Achieved: \(viewModel.correctStreak)")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("Next level unlocked!")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
                )
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 15) {
                // Continue to next level (if available)
                let nextLevelNumber = viewModel.configuration.levelNumber + 1
                if nextLevelNumber <= LevelConfiguration.allLevels.count {
                    NavigationLink(destination: StreakGameView(
                        configuration: LevelConfiguration.allLevels[nextLevelNumber - 1]
                    )) {
                        HStack {
                            Text("Next Level")
                            Image(systemName: "arrow.right")
                        }
                .font(.title2)
                .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                .cornerRadius(12)
                    }
                }
                
                // Back to menu
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Back to Menu")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                    RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
    }
}

struct NoteButton: View {
    let note: Note
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    private var noteGradient: LinearGradient {
        if isSelected {
            return LinearGradient(
                gradient: Gradient(colors: [Color.cyan, Color.blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            let noteIndex = Note.allCases.firstIndex(of: note) ?? 0
            let hue = Double(noteIndex) / Double(Note.allCases.count)
            let color1 = Color(hue: hue, saturation: 0.7, brightness: 0.8)
            let color2 = Color(hue: hue, saturation: 0.5, brightness: 0.6)
            
            return LinearGradient(
                gradient: Gradient(colors: [color1, color2]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        Button(action: {
            action()
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(noteGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.6), Color.clear]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isSelected ? 3 : 2
                            )
                    )
                    .shadow(
                        color: isSelected ? Color.cyan.opacity(0.5) : Color.black.opacity(0.3),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isPressed ? 2 : 4
                    )
                
                Text(note.rawValue)
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
            }
            .frame(width: 65, height: 65)
            .scaleEffect(isPressed ? 0.95 : (isSelected ? 1.05 : 1.0))
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
}

struct MelodySlot: View {
    let note: Note?
    let index: Int
    let isPulsing: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    private var slotGradient: LinearGradient {
        if let note = note {
            let noteIndex = Note.allCases.firstIndex(of: note) ?? 0
            let hue = Double(noteIndex) / Double(Note.allCases.count)
            let color1 = Color(hue: hue, saturation: 0.8, brightness: 0.9)
            let color2 = Color(hue: hue, saturation: 0.6, brightness: 0.7)
            
            return LinearGradient(
                gradient: Gradient(colors: [color1, color2]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        Button(action: {
            action()
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(slotGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: isPulsing ? 
                                        [Color.cyan.opacity(0.8), Color.blue.opacity(0.6)] : 
                                        [Color.white.opacity(0.4), Color.clear]
                                    ),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isPulsing ? 3 : 2
                            )
                    )
                    .shadow(
                        color: isPulsing ? Color.cyan.opacity(0.6) : Color.black.opacity(0.2),
                        radius: isPulsing ? 6 : 3,
                        x: 0,
                        y: isPressed ? 1 : 2
                    )
                
                VStack(spacing: 4) {
                if let note = note {
                    Text(note.rawValue)
                            .font(.system(.title3, design: .rounded, weight: .black))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                } else {
                    Text("?")
                            .font(.system(.title3, design: .rounded, weight: .black))
                            .foregroundColor(.white.opacity(0.7))
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                }
                
                Text("\(index)")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.3))
                        )
                }
            }
            .frame(width: 55, height: 55)
            .scaleEffect(isPressed ? 0.95 : (isPulsing ? 1.1 : 1.0))
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .animation(.easeInOut(duration: 0.3), value: isPulsing)
        }
    }
}

// MARK: - Gaming UI Components
struct PreviewSlot: View {
    let index: Int
    let isPulsing: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text("?")
                .font(.system(.title3, design: .rounded, weight: .black))
                .foregroundColor(.white.opacity(0.7))
                .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
            
            Text("\(index)")
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.3))
                )
        }
        .frame(width: 42, height: 42)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: isPulsing ? 
                                    [Color.cyan.opacity(0.8), Color.blue.opacity(0.6)] : 
                                    [Color.white.opacity(0.4), Color.clear]
                                ),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isPulsing ? 3 : 2
                        )
                )
                .shadow(
                    color: isPulsing ? Color.cyan.opacity(0.6) : Color.black.opacity(0.2),
                    radius: isPulsing ? 6 : 3,
                    x: 0,
                    y: 2
                )
            )
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isPulsing)
        }
}

struct GamingStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(1)
            
            Text(value)
                .font(.system(.title, design: .rounded, weight: .black))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [color.opacity(0.4), Color.clear]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
}

struct GamingProgressBar: View {
    let current: Int
    let total: Int
    let title: String
    
    var progress: Double {
        min(Double(current) / Double(total), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(1)
            
            VStack(spacing: 8) {
                Text("\(current) / \(total)")
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundColor(.cyan)
                    .shadow(color: .cyan.opacity(0.3), radius: 3, x: 0, y: 0)
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.3))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.cyan, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 80 * progress, height: 8)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
                .frame(width: 80)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.cyan.opacity(0.4), Color.clear]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
}

struct GamingActionButton: View {
    let title: String
    let icon: String
    let gradient: LinearGradient
    var isDisabled: Bool = false
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(.title2, weight: .bold))
                
                Text(title)
                    .font(.system(.title2, design: .rounded, weight: .black))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(gradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.6), Color.clear]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .black.opacity(0.4), radius: isPressed ? 4 : 10, x: 0, y: isPressed ? 2 : 5)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .opacity(isDisabled ? 0.6 : 1.0)
        }
        .disabled(isDisabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            if !isDisabled {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }
        }, perform: {})
    }
}

struct GamingControlButton: View {
    let title: String
    let icon: String
    let gradient: LinearGradient
    var isDisabled: Bool = false
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(.body, weight: .bold))
                
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(gradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.4), Color.clear]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: isPressed ? 2 : 5, x: 0, y: isPressed ? 1 : 3)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .opacity(isDisabled ? 0.6 : 1.0)
        }
        .disabled(isDisabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            if !isDisabled {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }
        }, perform: {})
    }
}

// MARK: - Mock Sound Service for Preview
class MockSoundService: SoundServiceProtocol {
    func playNote(_ note: Note, octave: Int, duration: Double) {
        print("Playing note: \(note.rawValue)")
    }
    
    
    func playChord(_ chord: Chord, duration: Double) {
        print("Playing chord: \(chord.displayName)")
    }
     
    func playMelody(_ melody: Melody) {
        print("Playing melody with \(melody.notes.count) notes")
    }
    
    func stopAll() {
        print("Stopping all sounds")
    }
    
}
