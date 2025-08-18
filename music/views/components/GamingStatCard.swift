//
//  GamingStatCard.swift
//  PlayXFlash
//
//  Created by pc on 18.08.25.
//


import Foundation
import SwiftUI

struct GamingStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundColor(.white)
                .textCase(.uppercase)
                .tracking(1)
            
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .black))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
