//
//  ChallengeHelpView.swift
//  music
//
//  Created by pc on 06.08.25.
//

import SwiftUI

struct ChallengeHelpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gaming background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.2, green: 0.1, blue: 0.3),
                        Color(red: 0.1, green: 0.15, blue: 0.25)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 15) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                                .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 0)
                            
                            Text("Challenge Mode")
                                .font(.system(.largeTitle, design: .rounded, weight: .black))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)
                            
                            Text("The ultimate test of your musical memory")
                                .font(.system(.headline, design: .rounded, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Challenge Rules
                        VStack(spacing: 20) {
                            HelpCard(
                                icon: "dice",
                                title: "Random Melodies",
                                description: "Face unpredictable melodies with 4-7 notes from a pool of 9 different notes. Every round is different!",
                                color: .red
                            )
                            
                            HelpCard(
                                icon: "infinity",
                                title: "Endless Challenge",
                                description: "There's no finish line! Keep playing to build the longest streak possible.",
                                color: .purple
                            )
                            
                            HelpCard(
                                icon: "crown.fill",
                                title: "Beat Your Best",
                                description: "Your highest streak is saved as your personal record. Challenge yourself to beat it!",
                                color: .yellow
                            )
                            
                            HelpCard(
                                icon: "bolt.fill",
                                title: "Instant Reset",
                                description: "One wrong answer resets your streak to zero. Stay focused and trust your ear!",
                                color: .orange
                            )
                        }
                        
                        // Difficulty Info
                        VStack(spacing: 15) {
                            Text("Difficulty Level")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 15) {
                                HStack {
                                    Image(systemName: "9.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.red)
                                    
                                    VStack(alignment: .leading) {
                                        Text("9 Notes Available")
                                            .font(.system(.headline, design: .rounded, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("Choose from the full chromatic scale")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                }
                                
                                HStack {
                                    Image(systemName: "music.note.list")
                                        .font(.title)
                                        .foregroundColor(.orange)
                                    
                                    VStack(alignment: .leading) {
                                        Text("4-7 Note Melodies")
                                            .font(.system(.headline, design: .rounded, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("Length changes randomly each round")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        
                        // Tips
                        VStack(spacing: 15) {
                            Text("Pro Tips")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                TipRow(icon: "ear", text: "Listen multiple times before attempting")
                                TipRow(icon: "brain.head.profile", text: "Focus on the melody's pattern and rhythm")
                                TipRow(icon: "speaker.wave.2", text: "Use the play button to hear your attempt")
                                TipRow(icon: "target", text: "Stay calm and trust your musical instincts")
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 25)
                }
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.cyan)
                .frame(width: 20)
            
            Text(text)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
}

#Preview {
    ChallengeHelpView()
}