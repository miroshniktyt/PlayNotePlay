//
//  Helpers.swift
//  PlayXFlash
//
//  Created by pc on 18.08.25.
//

import SwiftUI

extension View {
    func fullScreenBackground(_ imageName: String) -> some View {
        ZStack {
            GeometryReader { geometry in
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .ignoresSafeArea()
            
            self
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
