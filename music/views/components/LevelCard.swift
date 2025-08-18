//
//  LevelCard.swift
//  PlayXFlash
//
//  Created by pc on 18.08.25.
//


import SwiftUI

struct LevelCard: View {
    let configuration: LevelConfiguration
    let isUnlocked: Bool
    @State private var isPressed = false
    
    private var buttonImageName: String {
        if isUnlocked {
            // Use colorful button images based on level number
            let imageIndex = (configuration.levelNumber - 1) % 12 // Cycle through button-0 to button-11
            return "button-\(imageIndex)"
        } else {
            return "button-grey"
        }
    }
    
    var body: some View {
        Group {
            if isUnlocked {
                NavigationLink(destination: GameView(configuration: configuration)) {
                    cardContent
                }
            } else {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
        ZStack {
            // Background button image
            Image(buttonImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 90)
            
            VStack(spacing: 8) {
                // Level number with gaming style
                Text("\(configuration.levelNumber)")
                    .font(.system(.title, design: .rounded, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 3, x: 2, y: 2)
                
                if isUnlocked {
                    // Gaming stats display
                    HStack(spacing: 2) {
                        Text("\(configuration.gridSize)")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                        Text("/")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                        Text("\(configuration.melodyLength)")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                } else {
                    // Lock icon with glow effect
                    Image(systemName: "lock.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.6), radius: 3, x: 2, y: 2)
                }
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}