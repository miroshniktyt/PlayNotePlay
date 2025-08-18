//
//  ListeningView.swift
//  PlayXFlash
//
//  Created by pc on 18.08.25.
//


import Foundation
import SwiftUI

struct ListeningView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 25) {
            Text("🎧 Listen to the melody")
                .font(.system(.title2, design: .rounded, weight: .black))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)
            
            // Show melody slots preview - Single line with dynamic sizing
            VStack(spacing: 12) {
                Text("🎵 Melody preview:")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                
                // Single row that adapts to screen width
                let melodyCount = viewModel.currentLevel.melody.notes.count
                let maxSlotSize: CGFloat = 42
                let minSlotSize: CGFloat = 30
                let availableWidth: CGFloat = UIScreen.main.bounds.width - 80 // Account for padding
                let spacing: CGFloat = 6
                let totalSpacing = spacing * CGFloat(melodyCount - 1)
                let slotSize = min(maxSlotSize, max(minSlotSize, (availableWidth - totalSpacing) / CGFloat(melodyCount)))
                
                HStack(spacing: spacing) {
                    ForEach(0..<melodyCount, id: \.self) { index in
                        PreviewSlot(
                            index: index + 1,
                            isPulsing: viewModel.playingNoteIndex == index
                        )
                        .frame(width: slotSize, height: slotSize)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            VStack(spacing: 20) {
                Button(action: {
                    viewModel.playTargetMelody()
                }) {
                    Image("play-melody-button")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                }
                
                Text("🎵 Tap to play melody")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 2, y: 2)
            }
            
            GamingActionButton(
                title: viewModel.hasListenedToMelody ? "Start Challenge" : "Listen First!",
                icon: viewModel.hasListenedToMelody ? "play.fill" : "headphones",
                imageName: viewModel.hasListenedToMelody ? "start-button" : "start-button",
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

#Preview {
    ListeningView(viewModel: GameViewModel(
        soundService: SoundService(),
        configuration: LevelConfiguration.allLevels[0],
        isChallenge: false
    ))
}
