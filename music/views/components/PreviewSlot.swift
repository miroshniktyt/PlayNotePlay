//
//  PreviewSlot.swift
//  PlayXFlash
//
//  Created by pc on 18.08.25.
//


import Foundation
import SwiftUI

struct PreviewSlot: View {
    let index: Int
    let isPulsing: Bool
    
    var body: some View {
        ZStack {
            // Background image (using a default button image)
            Image("button-grey")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .opacity(0.5)
                .overlay(
                    // Pulsing border when active
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isPulsing ? Color.cyan : Color.clear,
                            lineWidth: isPulsing ? 3 : 0
                        )
                        .shadow(
                            color: isPulsing ? Color.cyan.opacity(0.8) : Color.clear,
                            radius: isPulsing ? 8 : 0,
                            x: 0,
                            y: 0
                        )
                )
            
            VStack(spacing: 4) {
                Text("?")
                    .font(.system(.title3, design: .rounded, weight: .black))
                    .foregroundColor(.white.opacity(0.7))
                    .shadow(color: .black.opacity(0.6), radius: 3, x: 2, y: 2)
                
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
        .frame(width: 42, height: 42)
        .scaleEffect(isPulsing ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isPulsing)
    }
}
