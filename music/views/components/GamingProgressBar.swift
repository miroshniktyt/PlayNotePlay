//
//  GamingProgressBar.swift
//  PlayXFlash
//
//  Created by pc on 18.08.25.
//


import Foundation
import SwiftUI

struct GamingProgressBar: View {
    let current: Int
    let total: Int
    let title: String
    
    var progress: Double {
        min(Double(current) / Double(total), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(1)
            
            VStack(spacing: 6) {
                Text("\(current) / \(total)")
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundColor(.cyan)
                    .shadow(color: .cyan.opacity(0.3), radius: 3, x: 0, y: 0)
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.3))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.cyan, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 80 * progress, height: 8)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
                .frame(width: 80)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.cyan.opacity(0.4), Color.clear]),
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
