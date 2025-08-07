//
//  LevelsView.swift
//  music
//
//  Created by pc on 06.08.25.
//

import SwiftUI

struct LevelsView: View {
    @AppStorage("unlockedLevels") private var unlockedLevelsData: Data = Data()
    @Environment(\.presentationMode) var presentationMode
    @State private var showingHelp = false
    
    var unlockedLevels: Set<Int> {
        (try? JSONDecoder().decode(Set<Int>.self, from: unlockedLevelsData)) ?? [1]
    }
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    
    var body: some View {
        ZStack {
            // Gaming background gradient
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
            
            VStack(spacing: 20) {
                // Gaming Subtitle
                Text("🎯 Master Each Challenge")
                    .font(.system(.headline, design: .rounded, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                    .padding(.top, 10)
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(LevelConfiguration.allLevels, id: \.levelNumber) { config in
                            LevelCard(
                                configuration: config,
                                isUnlocked: unlockedLevels.contains(config.levelNumber)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("Practice Levels")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(false)
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
            LevelsHelpView()
        }
    }
}

struct LevelCard: View {
    let configuration: LevelConfiguration
    let isUnlocked: Bool
    @State private var isPressed = false
    
    private var cardGradient: LinearGradient {
        if isUnlocked {
            let level = configuration.levelNumber
            switch level {
            case 1...7:
                return LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.8), Color.mint.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case 8...14:
                return LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.yellow.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case 15...21:
                return LinearGradient(
                    gradient: Gradient(colors: [Color.red.opacity(0.8), Color.pink.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            default:
                return LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        Group {
            if isUnlocked {
                NavigationLink(destination: StreakGameView(configuration: configuration)) {
                    cardContent
                }
            } else {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
        ZStack {
            // Gaming card background
            RoundedRectangle(cornerRadius: 16)
                .fill(cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: isUnlocked ? [Color.white.opacity(0.6), Color.clear] : [Color.gray.opacity(0.3), Color.clear]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(
                    color: isUnlocked ? Color.black.opacity(0.3) : Color.clear,
                    radius: isPressed ? 2 : 8,
                    x: 0,
                    y: isPressed ? 2 : 4
                )
            
            VStack(spacing: 8) {
                // Level number with gaming style
                Text("\(configuration.levelNumber)")
                    .font(.system(.title, design: .rounded, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                
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
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                    )
                } else {
                    // Lock icon with glow effect
                    Image(systemName: "lock.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                }
            }
        }
        .frame(width: 90, height: 90)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

#Preview {
    NavigationView {
        LevelsView()
    }
}