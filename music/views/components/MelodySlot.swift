//
//  MelodySlot.swift
//  PlayXFlash
//
//  Created by pc on 18.08.25.
//


import Foundation
import SwiftUI

struct MelodySlot: View {
    let note: Note?
    let index: Int
    let isPulsing: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    private var buttonImageName: String {
        if let note = note {
            let noteIndex = Note.allCases.firstIndex(of: note) ?? 0
            return "button-\(noteIndex)"
        } else {
            return "button-grey" // Default empty slot image
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
                // Background image
                Image(buttonImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(note == nil ? 0.5 : 1.0)
                    .overlay(
                        // Pulsing border when active
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isPulsing ? Color.cyan : Color.clear,
                                lineWidth: isPulsing ? 4 : 0
                            )
                            .shadow(
                                color: isPulsing ? Color.cyan.opacity(0.8) : Color.clear,
                                radius: isPulsing ? 10 : 0,
                                x: 0,
                                y: 0
                            )
                    )
                
                VStack(spacing: 4) {
                    if let note = note {
                        Text(note.rawValue)
                            .font(.system(.title3, design: .rounded, weight: .black))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 3, x: 2, y: 2)
                    } else {
                        Text("?")
                            .font(.system(.title3, design: .rounded, weight: .black))
                            .foregroundColor(.white.opacity(0.7))
                            .shadow(color: .black.opacity(0.6), radius: 3, x: 2, y: 2)
                    }
                    
                    Text("\(index)")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
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
                }
            }
            .frame(width: 55, height: 55)
            .scaleEffect(isPressed ? 0.95 : (isPulsing ? 1.1 : 1.0))
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .animation(.easeInOut(duration: 0.3), value: isPulsing)
        }
    }
}
