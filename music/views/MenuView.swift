//
//  MenuView.swift
//  music
//
//  Created by pc on 06.08.25.
//

import SwiftUI

struct MenuView: View {
    @AppStorage("unlockedLevels") private var unlockedLevelsData: Data = Data()
    @AppStorage("challengeBestStreak") private var challengeBestStreak: Int = 0
    @StateObject private var soundService = SoundService()
    @State private var showingHelp = false
    
    var unlockedLevels: Set<Int> {
        (try? JSONDecoder().decode(Set<Int>.self, from: unlockedLevelsData)) ?? [1]
    }
    
    var highestUnlockedLevel: Int {
        unlockedLevels.max() ?? 1
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gaming background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.15, green: 0.05, blue: 0.25),
                        Color(red: 0.1, green: 0.1, blue: 0.3),
                        Color(red: 0.05, green: 0.15, blue: 0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Gaming Subtitle
                    VStack(spacing: 15) {
                        Text("🎮 TRAIN YOUR MUSICAL EAR")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                    }
                    .padding(.top, 20)
                    
                    // Gaming Menu Options
                    VStack(spacing: 20) {
                        // Practice/Levels Mode
                        NavigationLink(destination: LevelsView()) {
                            GamingMenuCard(
                                title: "PRACTICE LEVELS",
                                subtitle: "Level \(highestUnlockedLevel) / \(LevelConfiguration.allLevels.count)",
                                icon: "graduationcap.fill",
                                gradient: LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.cyan]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }
                        
                        // Challenge Mode
                        NavigationLink(destination: StreakGameView(
                            configuration: LevelConfiguration.challengeMode,
                            isChallenge: true
                        )) {
                            GamingMenuCard(
                                title: "CHALLENGE MODE",
                                subtitle: challengeBestStreak > 0 ? "Best streak: \(challengeBestStreak)" : "Try your best!",
                                icon: "flame.fill",
                                gradient: LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.red]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }
                    }
                    .padding(.horizontal, 25)
                    
                    Spacer()
                    
                    // Gaming Note Pad
                    VStack(spacing: 20) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                            ForEach([Note.C, .CSharp, .D, .DSharp, .E, .F, .FSharp, .G, .GSharp, .A, .ASharp, .B], id: \.self) { note in
                                GamingNoteButton(note: note, soundService: soundService)
                            }
                        }
                        .padding(.horizontal, 15)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Melody Memory")
            .navigationBarTitleDisplayMode(.large)
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
                OnboardingView()
            }
        }
    }
}

struct GamingMenuCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    
    var body: some View {
        HStack(spacing: 20) {
            // Gaming icon with glow
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.5), radius: 4, x: 0, y: 0)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(gradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.6), Color.clear]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
        )
    }
}

struct GamingNoteButton: View {
    let note: Note
    let soundService: SoundService
    @State private var isPressed = false
    
    private var noteGradient: LinearGradient {
        let noteIndex = Note.allCases.firstIndex(of: note) ?? 0
        let hue = Double(noteIndex) / Double(Note.allCases.count)
        let color1 = Color(hue: hue, saturation: 0.8, brightness: 0.9)
        let color2 = Color(hue: hue, saturation: 0.6, brightness: 0.7)
        
        return LinearGradient(
            gradient: Gradient(colors: [color1, color2]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
                RoundedRectangle(cornerRadius: 12)
                    .fill(noteGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.6), Color.clear]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: isPressed ? 2 : 6, x: 0, y: isPressed ? 1 : 3)
                
                Text(note.rawValue)
                    .font(.system(.body, design: .rounded, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
            }
            .frame(width: 70, height: 50)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .disabled(soundService.isMelodyPlaying)
    }
}

#Preview {
    MenuView()
}
