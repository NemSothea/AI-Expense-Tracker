//
//  BackgroundShapes.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 6/11/25.
//
import SwiftUI

// MARK: - Background Shapes
struct BackgroundShapes: View {
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 300, height: 300)
                .offset(x: -150, y: -300)
                .blur(radius: 20)
            
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 200, height: 200)
                .offset(x: 150, y: 300)
                .blur(radius: 20)
            
            Rectangle()
                .fill(color.opacity(0.05))
                .frame(width: 400, height: 400)
                .rotationEffect(.degrees(45))
                .offset(x: 100, y: -200)
                .blur(radius: 30)
        }
    }
}
