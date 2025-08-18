//
//  GamingActionButton.swift
//  PlayXFlash
//
//  Created by pc on 18.08.25.
//


import Foundation
import SwiftUI

struct GamingActionButton: View {
    let title: String
    let icon: String
    let imageName: String // Custom image for the button
    var isDisabled: Bool = false
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
                .opacity(isDisabled ? 0.6 : 1.0)
        }
        .disabled(isDisabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            if !isDisabled {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }
        }, perform: {})
    }
}

#Preview {
    VStack(spacing: 20) {
        GamingActionButton(
            title: "Start Challenge",
            icon: "play.fill",
            imageName: "start-button",
            action: {}
        )
        
        GamingActionButton(
            title: "Try Again",
            icon: "arrow.clockwise",
            imageName: "tryagain-button",
            action: {}
        )
    }
    .padding()
    .background(Color.black)
}