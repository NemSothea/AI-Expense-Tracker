//
//  PieChartView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 20/10/25.
//

import SwiftUI
import Charts


// Alternative: Custom Pie Chart without Charts framework
struct CustomPieChartView: View {
    let topCategories: [TopCategory]
    let colors: [Color]
    
    private var totalAmount: Double {
        topCategories.reduce(0) { $0 + $1.totalAmount }
    }
    
    var body: some View {
        ZStack {
            ForEach(Array(topCategories.enumerated()), id: \.offset) { index, category in
                PieSliceView(
                    startAngle: angle(for: index),
                    endAngle: angle(for: index + 1),
                    color: colors[index % colors.count]
                )
            }
        }
        .frame(width: 200, height: 200)
        .overlay(
            Circle()
                .fill(Color(.systemBackground))
                .frame(width: 100, height: 100)
        )
    }
    
    private func angle(for index: Int) -> Double {
        guard index > 0 else { return 0 }
        let previousTotal = topCategories[0..<index].reduce(0) { $0 + $1.totalAmount }
        return 360 * (previousTotal / totalAmount)
    }
}

struct PieSliceView: View {
    let startAngle: Double
    let endAngle: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(endAngle),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}
