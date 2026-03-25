//
//  NetworkMonitor.swift
//  AIExapenseTracker
//

import Network
import Combine
import Observation

@Observable
final class NetworkMonitor: @unchecked Sendable {

    static let shared = NetworkMonitor()

    private(set) var isConnected: Bool = true

    // Combine subject so SyncManager can react to transitions
    let connectionPublisher = PassthroughSubject<Bool, Never>()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.aiexpense.NetworkMonitor", qos: .utility)

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            DispatchQueue.main.async {
                guard let self else { return }
                let wasConnected = self.isConnected
                self.isConnected = connected
                if connected != wasConnected {
                    self.connectionPublisher.send(connected)
                }
            }
        }
        monitor.start(queue: queue)
    }
}
