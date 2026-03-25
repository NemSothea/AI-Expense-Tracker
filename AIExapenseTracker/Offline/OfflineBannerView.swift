//
//  OfflineBannerView.swift
//  AIExapenseTracker
//

import SwiftUI

struct OfflineBannerView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.caption)
            Text("You're offline — showing cached data")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.orange)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// Convenience modifier — add .offlineBanner() to any NavigationStack or root view
extension View {
    func offlineBanner() -> some View {
        modifier(OfflineBannerModifier())
    }
}

private struct OfflineBannerModifier: ViewModifier {
    @State private var monitor = NetworkMonitor.shared

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            if !monitor.isConnected {
                OfflineBannerView()
                    .animation(.easeInOut(duration: 0.3), value: monitor.isConnected)
            }
            content
        }
        .animation(.easeInOut(duration: 0.3), value: monitor.isConnected)
    }
}
