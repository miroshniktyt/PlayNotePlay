//
//  PlayingView.swift
//  PlayXFlash
//
//  Created by pc on 18.08.25.
//


import Foundation
import SwiftUI

struct PlayingView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Notes Container with Background
            ZStack {
                // Background container image for 9-element grid
                Image("notes-frame")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 300)
                
                // Dynamic Note Grid - centered within the container
                let gridSize = 3 // Always use 3x3 grid for consistency
                let noteCount = viewModel.noteGrid.count
                
                VStack(spacing: 12) {
                    ForEach(0..<gridSize, id: \.self) { row in
                        HStack(spacing: 12) {
                            ForEach(0..<gridSize, id: \.self) { col in
                                let index = row * gridSize + col
                                if index < noteCount {
                                    let note = viewModel.noteGrid[index]
                                    NoteButton(
                                        note: note,
                                        isSelected: viewModel.selectedNote == note,
                                        action: { viewModel.selectNote(note) }
                                    )
                                    .frame(width: 65, height: 65)
                                } else {
                                    // Empty space for missing notes
                                    Spacer()
                                        .frame(width: 65, height: 65)
                                }
                            }
                        }
                    }
                }
                .padding(30) // Adjust padding to fit within the container
            }
            
            Spacer()
            // Melody Slots - Single line with dynamic sizing
            VStack(spacing: 8) {
                Text("Your melody:")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                
                // Single row that adapts to screen width
                let melodyCount = viewModel.userMelody.count
                let maxSlotSize: CGFloat = 55
                let minSlotSize: CGFloat = 35
                let availableWidth: CGFloat = UIScreen.main.bounds.width - 80 // Account for padding
                let spacing: CGFloat = 6
                let totalSpacing = spacing * CGFloat(melodyCount - 1)
                let slotSize = min(maxSlotSize, max(minSlotSize, (availableWidth - totalSpacing) / CGFloat(melodyCount)))
                
                HStack(spacing: spacing) {
                    ForEach(0..<melodyCount, id: \.self) { index in
                        MelodySlot(
                            note: viewModel.userMelody[index],
                            index: index + 1,
                            isPulsing: viewModel.playingNoteIndex == index,
                            action: { viewModel.placeNoteInSlot(index) }
                        )
                        .frame(width: slotSize, height: slotSize)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            Spacer()
            // Gaming Control Buttons
            HStack(spacing: 15) {
                GamingControlButton(
                    title: "Play",
                    icon: "play.fill",
                    imageName: "play-button",
                    action: { viewModel.playUserMelody() }
                )
                
                GamingControlButton(
                    title: "Submit",
                    icon: "checkmark.circle.fill",
                    imageName: "submit-button",
                    isDisabled: viewModel.userMelody.contains(nil),
                    action: { viewModel.checkAnswer() }
                )
            }
        }
        .padding()
    }
}

#Preview {
    PlayingView(viewModel: GameViewModel(
        soundService: SoundService(),
        configuration: LevelConfiguration.allLevels[0],
        isChallenge: false
    ))
}
