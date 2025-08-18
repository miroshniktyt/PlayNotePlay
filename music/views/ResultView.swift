//
//  ResultView.swift
//  PlayXFlash
//
//  Created by pc on 18.08.25.
//


import Foundation
import SwiftUI

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
                // User melody
                VStack(spacing: 10) {
                    HStack {
                        Text("Your Play Line:")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                        
                        Spacer()
                        
                        Button(action: { playUserMelodyWithAnimation() }) {
                            Image("play-melody-button")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                        }
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 8) {
                        ForEach(0..<viewModel.userMelody.count, id: \.self) { index in
                            if let userNote = viewModel.userMelody[index] {
                                ZStack {
                                    // Use button image based on note
                                    let noteIndex = Note.allCases.firstIndex(of: userNote) ?? 0
                                    Image("button-\(noteIndex)")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            // Feedback border
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    viewModel.feedback.count > index ?
                                                    (viewModel.feedback[index] ? Color.green : Color.red) : Color.clear,
                                                    lineWidth: viewModel.feedback.count > index ? 3 : 0
                                                )
                                                .shadow(
                                                    color: viewModel.feedback.count > index ?
                                                    (viewModel.feedback[index] ? Color.green.opacity(0.8) : Color.red.opacity(0.8)) : Color.clear,
                                                    radius: viewModel.feedback.count > index ? 8 : 0,
                                                    x: 0,
                                                    y: 0
                                                )
                                        )
                                    
                                    // Note text
                                    Text(userNote.rawValue)
                                        .font(.system(.caption, design: .rounded, weight: .black))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.8), radius: 2, x: 1, y: 1)
                                }
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
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                        
                        Spacer()
                        
                        Button(action: { playCorrectMelodyWithAnimation() }) {
                            Image("play-melody-button")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                        }
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 8) {
                        ForEach(0..<viewModel.currentLevel.targetNotes.count, id: \.self) { index in
                            ZStack {
                                // Use button image based on note
                                let targetNote = viewModel.currentLevel.targetNotes[index]
                                let noteIndex = Note.allCases.firstIndex(of: targetNote) ?? 0
                                Image("button-\(noteIndex)")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        // Green border for correct melody
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.green, lineWidth: 2)
                                            .shadow(color: Color.green.opacity(0.6), radius: 6, x: 0, y: 0)
                                    )
                                
                                // Note text
                                Text(targetNote.rawValue)
                                    .font(.system(.caption, design: .rounded, weight: .black))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.8), radius: 2, x: 1, y: 1)
                            }
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
                imageName: viewModel.isComplete ? "start-button" : "tryagain-button",
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

#Preview {
    ResultView(viewModel: GameViewModel(
        soundService: SoundService(),
        configuration: LevelConfiguration.allLevels[0],
        isChallenge: false
    ))
}
