//
//  NoteButton.swift
//  PlayXFlash
//
//  Created by pc on 18.08.25.
//


import Foundation
import SwiftUI

struct NoteButton: View {
    let note: Note
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    private var buttonImageName: String {
        let noteIndex = Note.allCases.firstIndex(of: note) ?? 0
        return "button-\(noteIndex)"
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
                    .overlay(
                        // Selected state overlay
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.cyan : Color.clear,
                                lineWidth: isSelected ? 4 : 0
                            )
                            .shadow(
                                color: isSelected ? Color.cyan.opacity(0.8) : Color.clear,
                                radius: isSelected ? 10 : 0,
                                x: 0,
                                y: 0
                            )
                    )
                
                // Note text overlay
                Text(note.rawValue)
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 3, x: 2, y: 2)
            }
            .frame(width: 65, height: 65)
            .scaleEffect(isPressed ? 0.95 : (isSelected ? 1.1 : 1.0))
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
}