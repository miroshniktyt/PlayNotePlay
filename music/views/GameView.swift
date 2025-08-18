//
//  new.swift
//  music
//
//  Created by pc on 06.08.25.
//

import Foundation
import SwiftUI

struct GameView: View {
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
        VStack(spacing: 0) {
            // Custom Title
            VStack(spacing: 10) {
                Text(isChallenge ? "Challenge Mode" : "Level \(configuration.levelNumber)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.yellow, .orange]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .black.opacity(0.8), radius: 4, x: 2, y: 2)
            }
            .padding(.vertical)
            
            if isChallenge {
                ZStack {
                    Image("status-frame")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                        .frame(width: 270, height: 90)
                    HStack(spacing: 88) {
                        GamingStatCard(title: "STREAK", value: "\(gameViewModel.correctStreak)", color: .blue)
                        GamingStatCard(title: "BEST", value: "\(gameViewModel.challengeBestStreak)", color: .green)
                    }
                    .padding(.horizontal)
                }
            } else {
                VStack(spacing: 4) {
                    GamingProgressBar(
                        current: gameViewModel.correctStreak,
                        total: configuration.streakToWin,
                        title: "PROGRESS"
                    )
                    
                    if gameViewModel.isLevelWon {
                        Text("🏆 COMPLETE!")
                            .font(.system(.callout, design: .rounded, weight: .black))
                            .foregroundColor(.yellow)
                            .shadow(color: .black.opacity(0.8), radius: 3, x: 2, y: 2)
                    }
                }
                .padding(.horizontal)
            }
            
            
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
        .fullScreenBackground("bg")
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

#Preview("Level Game") {
    GameView(configuration: LevelConfiguration.allLevels[0])
}

#Preview("Challenge Game") {
    GameView(configuration: LevelConfiguration.challengeMode, isChallenge: true)
}
