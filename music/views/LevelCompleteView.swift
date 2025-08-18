//
//  LevelCompleteView.swift
//  PlayXFlash
//
//  Created by pc on 18.08.25.
//


import Foundation
import SwiftUI

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
                    NavigationLink(destination: GameView(
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