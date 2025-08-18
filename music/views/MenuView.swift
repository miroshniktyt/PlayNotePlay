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
            VStack(spacing: 0) {
                // Custom Title
                VStack(spacing: 15) {
                    Text("Melody Memory")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.yellow, .orange]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .black.opacity(0.8), radius: 4, x: 2, y: 2)
                    
                    Text("Train Your Musical Ear")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                }
                Spacer()
                
                // Gaming Menu Options
                VStack(spacing: 16) {
                    // Practice/Levels Mode
                    NavigationLink(destination: LevelsView()) {
                        GamingMenuCard(
                            title: "PRACTICE",
                            subtitle: "Level \(highestUnlockedLevel) / \(LevelConfiguration.allLevels.count)",
                            icon: "practice",
                            color: .blue
                        )
                    }
                    
                    // Challenge Mode
                    NavigationLink(destination: GameView(
                        configuration: LevelConfiguration.challengeMode,
                        isChallenge: true
                    )) {
                        GamingMenuCard(
                            title: "CHALLENGE",
                            subtitle: challengeBestStreak > 0 ? "Best streak: \(challengeBestStreak)" : "Try your best!",
                            icon: "challange",
                            color: .orange
                        )
                    }
                }
                .padding(.horizontal, 25)
                
                Spacer()
                
                // Gaming Note Pad
                VStack(spacing: 20) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                        ForEach([Note.C, .CSharp, .D, .DSharp, .E, .F, .FSharp, .G, .GSharp, .A, .ASharp, .B], id: \.self) { note in
                            GamingNoteButton(note: note, soundService: soundService)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .fullScreenBackground("bg")
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
    let color: Color
    
    var body: some View {
        HStack(spacing: 20) {
            // Gaming icon with glow
            ZStack {
                Image(icon)
                    .resizable()
                    .frame(width: 36, height: 36)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 3, x: 2, y: 2)
                
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.6), radius: 2, x: 1, y: 1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.8), radius: 3, x: 2, y: 2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.8))
                )
        )
    }
}



#Preview {
    MenuView()
}
