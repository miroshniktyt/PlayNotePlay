//
//  GamingNoteButton.swift
//  PlayXFlash
//
//  Created by pc on 18.08.25.
//


import SwiftUI

struct GamingNoteButton: View {
    let note: Note
    let soundService: SoundService
    @State private var isPressed = false
    
    private var buttonImageName: String {
        let noteIndex = Note.allCases.firstIndex(of: note) ?? 0
        return "button-\(noteIndex)"
    }
    
    var body: some View {
        Button(action: {
            soundService.playNote(note, octave: 4, duration: 0.8)
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
                
                // Note text overlay
                Text(note.rawValue)
                    .font(.system(.headline, design: .rounded, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 3, x: 2, y: 2)
            }
            .aspectRatio(1, contentMode: .fit) // Make it square
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .disabled(soundService.isMelodyPlaying)
    }
}

#Preview {
    VStack {
        HStack {
            GamingNoteButton(note: .C, soundService: SoundService())
            GamingNoteButton(note: .CSharp, soundService: SoundService())
            GamingNoteButton(note: .D, soundService: SoundService())
        }
        HStack {
            GamingNoteButton(note: .E, soundService: SoundService())
            GamingNoteButton(note: .F, soundService: SoundService())
            GamingNoteButton(note: .G, soundService: SoundService())
        }
    }
    .padding()
    .background(Color.black)
}