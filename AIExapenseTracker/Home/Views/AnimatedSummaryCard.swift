//
//  AnimatedSummaryCard.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 20/10/25.
//


import SwiftUI

struct AnimatedSummaryCard: View {
    
    let title       : String
    let value       : Double
    let format      : FloatingPointFormatStyle<Double>.Currency
    let subtitle    : String?
    let icon        : String
    let color       : Color
    let delay       : Double
    
    @State private var animatedValue: Double = 0
    @State private var isAppeared = false
    
    init(title: String, value: Double, format: FloatingPointFormatStyle<Double>.Currency,
         subtitle: String? = nil, icon: String,
         color: Color, delay: Double = 0) {
        self.title = title
        self.value = value
        self.format = format
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.delay = delay
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .scaleEffect(isAppeared ? 1 : 0.5)
                    .opacity(isAppeared ? 1 : 0)
                
                Spacer()
            }
            
            Text(animatedValue, format: format)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .monospacedDigit()
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .opacity(isAppeared ? 1 : 0)
                .offset(y: isAppeared ? 0 : 10)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(color)
                    .fontWeight(.medium)
                    .opacity(isAppeared ? 1 : 0)
                    .offset(y: isAppeared ? 0 : 5)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .scaleEffect(isAppeared ? 1 : 0.8)
        .opacity(isAppeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                isAppeared = true
            }
            
            // Animate the number counting up
            withAnimation(.easeOut(duration: 1.5).delay(delay + 0.2)) {
                animatedValue = value
            }
        }
    }
}
