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
        VStack(spacing: 20) {
            // Gaming Subtitle
            Text("🎯 Master Each Challenge")
                .font(.system(.headline, design: .rounded, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .shadow(color: .black.opacity(0.5), radius: 3, x: 2, y: 2)
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
        .fullScreenBackground("bg")
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


#Preview {
    NavigationView {
        LevelsView()
    }
}
