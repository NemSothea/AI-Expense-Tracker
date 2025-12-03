//
//  AnimatedPieChartView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 20/10/25.
//


import SwiftUI
import Charts

struct AnimatedPieChartView: View {
    let topCategories: [TopCategory]
    let colors: [Color]
    
    @State private var animateChart = false
    
    var body: some View {
        Chart(topCategories, id: \.categoryId) { category in
            SectorMark(
                angle: .value("Amount", animateChart ? category.totalAmount : 0),
                innerRadius: .ratio(0.5),
                angularInset: 1.5
            )
            .foregroundStyle(by: .value("Category", category.name))
            .annotation(position: .overlay) {
                if animateChart && category.pctOfTotal > 8 { // Only show percentage if slice is big enough
                    Text("\(String(format: "%.0f", category.pctOfTotal))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .scaleEffect(animateChart ? 1 : 0)
                }
            }
        }
        .chartForegroundStyleScale(range: colors)
        .frame(height: 200)
        .padding()
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.5)) {
                animateChart = true
            }
        }
    }
}

// Alternative: Custom animated pie chart
struct AnimatedCustomPieChartView: View {
    let topCategories: [TopCategory]
    let colors: [Color]
    
    @State private var animationProgress: Double = 0
    
    private var totalAmount: Double {
        topCategories.reduce(0) { $0 + $1.totalAmount }
    }
    
    var body: some View {
        ZStack {
            ForEach(Array(topCategories.enumerated()), id: \.offset) { index, category in
                AnimatedPieSliceView(
                    startAngle: angle(for: index),
                    endAngle: angle(for: index + 1),
                    color: colors[index % colors.count],
                    animationProgress: animationProgress
                )
            }
        }
        .frame(width: 200, height: 200)
        .overlay(
            Circle()
                .fill(Color.accentColor)
                .frame(width: 100, height: 100)
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                animationProgress = 1.0
            }
        }
    }
    
    private func angle(for index: Int) -> Double {
        guard index > 0 else { return 0 }
        let previousTotal = topCategories[0..<index].reduce(0) { $0 + $1.totalAmount }
        return 360 * (previousTotal / totalAmount)
    }
}

struct AnimatedPieSliceView: View {
    let startAngle: Double
    let endAngle: Double
    let color: Color
    let animationProgress: Double
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                let animatedEndAngle = startAngle + (endAngle - startAngle) * animationProgress
                
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(animatedEndAngle),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}
