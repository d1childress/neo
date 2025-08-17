import Foundation
import Network
import Combine

/// Centralized network monitoring and management utility for improved performance
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var connectionStatus: NWPath.Status = .unsatisfied
    @Published var isExpensiveConnection = false
    @Published var currentInterface: NWInterface?
    
    private let pathMonitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor", qos: .utility)
    
    // Connection pool for reusing URLSessions
    private var sessionPool: [String: URLSession] = [:]
    private let sessionQueue = DispatchQueue(label: "SessionPool", attributes: .concurrent)
    
    // Rate limiting for network requests
    private var lastRequestTimes: [String: Date] = [:]
    private let minimumRequestInterval: TimeInterval = 0.1 // 100ms between requests
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        pathMonitor.cancel()
    }
    
    private func startMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.connectionStatus = path.status
                self?.isExpensiveConnection = path.isExpensive
                self?.currentInterface = path.availableInterfaces.first
            }
        }
        pathMonitor.start(queue: queue)
    }
    
    // MARK: - Connection Pool Management
    
    /// Get or create an optimized URLSession for a specific use case
    func getOptimizedSession(for purpose: SessionPurpose) -> URLSession {
        return sessionQueue.sync(flags: .barrier) {
            let key = purpose.rawValue

            if let existingSession = sessionPool[key] {
                return existingSession
            }

            let config = purpose.configuration
            let session = URLSession(configuration: config, delegate: purpose.delegate, delegateQueue: nil)
            sessionPool[key] = session
            return session
        }
    }
    
    /// Clear session pool to free memory
    func clearSessionPool() {
        sessionQueue.async(flags: .barrier) {
            for session in self.sessionPool.values {
                session.invalidateAndCancel()
            }
            self.sessionPool.removeAll()
        }
    }
    
    // MARK: - Rate Limiting
    
    /// Check if a request type can be executed based on rate limiting
    func canExecuteRequest(for identifier: String) -> Bool {
        let now = Date()
        
        if let lastTime = lastRequestTimes[identifier] {
            let timeSinceLastRequest = now.timeIntervalSince(lastTime)
            if timeSinceLastRequest < minimumRequestInterval {
                return false
            }
        }
        
        lastRequestTimes[identifier] = now
        return true
    }
    
    // MARK: - Network Quality Assessment
    
    /// Assess current network quality for optimal request configuration
    func getNetworkQuality() -> NetworkQuality {
        switch connectionStatus {
        case .satisfied:
            if isExpensiveConnection {
                return .limited
            } else if currentInterface?.type == .wifi {
                return .excellent
            } else {
                return .good
            }
        case .requiresConnection, .unsatisfied:
            return .poor
        @unknown default:
            return .poor
        }
    }
    
    /// Get recommended timeout based on network quality
    func getRecommendedTimeout() -> TimeInterval {
        switch getNetworkQuality() {
        case .excellent:
            return 30.0
        case .good:
            return 45.0
        case .limited:
            return 60.0
        case .poor:
            return 90.0
        }
    }
    
    /// Get recommended concurrent connection limit
    func getRecommendedConcurrentLimit() -> Int {
        switch getNetworkQuality() {
        case .excellent:
            return 100
        case .good:
            return 50
        case .limited:
            return 20
        case .poor:
            return 10
        }
    }
}

// MARK: - Supporting Types

enum SessionPurpose: String, CaseIterable {
    case speedTest = "speedTest"
    case ping = "ping"
    case portScan = "portScan"
    case generalNetwork = "general"
    
    var configuration: URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        
        switch self {
        case .speedTest:
            config.timeoutIntervalForRequest = 120
            config.timeoutIntervalForResource = 300
            config.httpMaximumConnectionsPerHost = 1
            config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            config.urlCache = nil
            config.httpShouldUsePipelining = false
            
        case .ping, .portScan:
            config.timeoutIntervalForRequest = 10
            config.timeoutIntervalForResource = 30
            config.httpMaximumConnectionsPerHost = 50
            config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            config.urlCache = nil
            
        case .generalNetwork:
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 60
            config.httpMaximumConnectionsPerHost = 6
            config.requestCachePolicy = .useProtocolCachePolicy
            
            // Enable caching for general requests
            let cache = URLCache(memoryCapacity: 50 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024)
            config.urlCache = cache
        }
        
        return config
    }
    
    var delegate: URLSessionDelegate? {
        switch self {
        case .speedTest, .generalNetwork:
            return RelaxedURLSessionDelegate()
        case .ping, .portScan:
            return nil
        }
    }
}

enum NetworkQuality {
    case excellent  // WiFi, fast connection
    case good      // Ethernet or good cellular
    case limited   // Expensive/metered connection
    case poor      // Slow or unstable connection
}

// MARK: - Performance Metrics

/// Track and report performance metrics for network operations
class NetworkPerformanceTracker {
    static let shared = NetworkPerformanceTracker()
    
    private var metrics: [String: [TimeInterval]] = [:]
    private let metricsQueue = DispatchQueue(label: "MetricsQueue", attributes: .concurrent)
    
    private init() {}
    
    func recordOperation(_ operation: String, duration: TimeInterval) {
        metricsQueue.async(flags: .barrier) {
            if self.metrics[operation] == nil {
                self.metrics[operation] = []
            }
            self.metrics[operation]?.append(duration)
            
            // Keep only last 100 measurements to prevent memory growth
            if let count = self.metrics[operation]?.count, count > 100 {
                self.metrics[operation]?.removeFirst(count - 100)
            }
        }
    }
    
    func getAverageTime(for operation: String) -> TimeInterval? {
        return metricsQueue.sync {
            guard let times = metrics[operation], !times.isEmpty else { return nil }
            return times.reduce(0, +) / Double(times.count)
        }
    }
    
    func getMetricsSummary() -> [String: (average: TimeInterval, count: Int)] {
        return metricsQueue.sync {
            var summary: [String: (average: TimeInterval, count: Int)] = [:]
            
            for (operation, times) in metrics {
                guard !times.isEmpty else { continue }
                let average = times.reduce(0, +) / Double(times.count)
                summary[operation] = (average: average, count: times.count)
            }
            
            return summary
        }
    }
}

// MARK: - Convenience Extensions

extension NetworkMonitor {
    /// Execute a network operation with automatic rate limiting and error handling
    func executeNetworkOperation<T>(
        identifier: String,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        // Check rate limiting
        guard canExecuteRequest(for: identifier) else {
            throw NetworkError.rateLimited
        }
        
        // Check network availability
        guard connectionStatus == .satisfied else {
            throw NetworkError.networkUnavailable
        }
        
        let startTime = Date()
        
        do {
            let result = try await operation()
            
            // Record performance metrics
            let duration = Date().timeIntervalSince(startTime)
            NetworkPerformanceTracker.shared.recordOperation(identifier, duration: duration)
            
            return result
        } catch {
            // Record failed operations
            let duration = Date().timeIntervalSince(startTime)
            NetworkPerformanceTracker.shared.recordOperation("\(identifier)_failed", duration: duration)
            throw error
        }
    }
}

enum NetworkError: LocalizedError {
    case rateLimited
    case networkUnavailable
    case timeout
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .rateLimited:
            return "Request rate limited. Please wait before trying again."
        case .networkUnavailable:
            return "Network connection unavailable."
        case .timeout:
            return "Request timed out."
        case .invalidResponse:
            return "Invalid network response."
        }
    }
}