import Foundation
import Network
import Combine

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    @Published var isConnected = false
    @Published var connectionType: ConnectionType = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkManager")
    private var periodicTimer: Timer?
    
    enum ConnectionType {
        case wifi
        case cellular
        case unknown
    }
    
    private init() {
        startMonitoring()
        startPeriodicCheck()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.updateConnectionType(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func startPeriodicCheck() {
        // Controllo periodico ogni 30 secondi per verificare la connessione effettiva
        periodicTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.performConnectivityCheck()
        }
    }
    
    private func performConnectivityCheck() {
        guard let url = URL(string: "https://www.apple.com") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200,
                   error == nil {
                    // La connessione è effettivamente funzionante
                    if let isConnected = self?.isConnected, !isConnected {
                        self?.isConnected = true
                    }
                } else {
                    // Problemi di connettività
                    if let isConnected = self?.isConnected, isConnected {
                        self?.isConnected = false
                    }
                }
            }
        }
        task.resume()
    }
    
    private func updateConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else {
            connectionType = .unknown
        }
    }
    
    func stopMonitoring() {
        monitor.cancel()
        periodicTimer?.invalidate()
        periodicTimer = nil
    }
    
    deinit {
        stopMonitoring()
    }
}