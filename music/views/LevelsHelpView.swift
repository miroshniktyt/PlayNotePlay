//
//  LevelsHelpView.swift
//  music
//
//  Created by pc on 06.08.25.
//

import SwiftUI

struct LevelsHelpView: View {
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
                            Image(systemName: "graduationcap.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                                .shadow(color: .green.opacity(0.5), radius: 10, x: 0, y: 0)
                            
                            Text("Practice Levels")
                                .font(.system(.largeTitle, design: .rounded, weight: .black))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)
                            
                            Text("How to master your musical ear")
                                .font(.system(.headline, design: .rounded, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Game Rules
                        VStack(spacing: 20) {
                            HelpCard(
                                icon: "headphones",
                                title: "Listen Carefully",
                                description: "Each level starts with a melody. Listen to the sequence of notes and memorize their order.",
                                color: .blue
                            )
                            
                            HelpCard(
                                icon: "hand.tap",
                                title: "Recreate the Melody",
                                description: "Use the colorful note buttons to recreate what you heard. Each note has a unique color and sound.",
                                color: .purple
                            )
                            
                            HelpCard(
                                icon: "target",
                                title: "Build Your Streak",
                                description: "Get 5 correct answers in a row to complete a level and unlock the next one!",
                                color: .green
                            )
                            
                            HelpCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Progressive Difficulty",
                                description: "Start with 2 notes and 2-note melodies, progress to 9 notes and 7-note melodies.",
                                color: .orange
                            )
                        }
                        
                        // Level Format
                        VStack(spacing: 15) {
                            Text("Level Format")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 10) {
                                Text("Levels are shown as: Notes/Melody")
                                    .font(.system(.body, design: .rounded, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                HStack(spacing: 20) {
                                    VStack {
                                        Text("3/2")
                                            .font(.system(.title, design: .rounded, weight: .black))
                                            .foregroundColor(.cyan)
                                        Text("3 notes to choose\n2 notes in melody")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                            .multilineTextAlignment(.center)
                                    }
                                    
                                    Text("→")
                                        .font(.title)
                                        .foregroundColor(.white.opacity(0.5))
                                    
                                    VStack {
                                        Text("9/7")
                                            .font(.system(.title, design: .rounded, weight: .black))
                                            .foregroundColor(.red)
                                        Text("9 notes to choose\n7 notes in melody")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
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

struct HelpCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [color.opacity(0.4), Color.clear]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    LevelsHelpView()
}