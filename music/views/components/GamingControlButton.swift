//
//  GamingControlButton.swift
//  PlayXFlash
//
//  Created by pc on 18.08.25.
//


import Foundation
import SwiftUI

struct GamingControlButton: View {
    let title: String
    let icon: String
    let imageName: String
    var isDisabled: Bool = false
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 50)
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
    HStack(spacing: 15) {
        GamingControlButton(
            title: "Play",
            icon: "play.fill",
            imageName: "play-button",
            action: {}
        )
        
        GamingControlButton(
            title: "Submit",
            icon: "checkmark.circle.fill",
            imageName: "submit-button",
            action: {}
        )
    }
    .padding()
    .background(Color.black)
}