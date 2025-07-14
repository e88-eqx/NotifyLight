import Foundation

/// API client for NotifyLight server communication
public final class APIClient {
    private let baseURL: URL
    private let apiKey: String
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    public init(baseURL: URL, apiKey: String, timeoutInterval: TimeInterval = 30) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval * 2
        
        self.session = URLSession(configuration: config)
        
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
    }
    
    // MARK: - Device Registration
    
    /// Register device with NotifyLight server
    public func registerDevice(_ request: DeviceRegistrationRequest) async throws -> DeviceRegistrationResponse {
        let url = baseURL.appendingPathComponent("register-device")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        do {
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            throw NetworkError.encodingError(error)
        }
        
        return try await session.data(for: urlRequest, decoder: decoder)
    }
    
    // MARK: - In-App Messages
    
    /// Fetch in-app messages for a user
    public func fetchMessages(userId: String) async throws -> InAppMessagesResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("messages/\(userId)"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "active", value: "true")]
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        return try await session.data(for: urlRequest, decoder: decoder)
    }
    
    /// Mark message as read
    public func markMessageAsRead(messageId: String) async throws -> MarkMessageReadResponse {
        let url = baseURL.appendingPathComponent("messages/\(messageId)/read")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        return try await session.data(for: urlRequest, decoder: decoder)
    }
    
    // MARK: - Health Check
    
    /// Check server health
    public func healthCheck() async throws -> HealthResponse {
        let url = baseURL.appendingPathComponent("health")
        let urlRequest = URLRequest(url: url)
        
        return try await session.data(for: urlRequest, decoder: decoder)
    }
}

// MARK: - Response Models

/// Response for in-app messages fetch
public struct InAppMessagesResponse: Codable {
    public let success: Bool
    public let messages: [InAppMessage]
    public let count: Int
    
    enum CodingKeys: String, CodingKey {
        case success
        case messages
        case count
    }
}

/// Response for marking message as read
public struct MarkMessageReadResponse: Codable {
    public let success: Bool
    public let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
    }
}

/// Health check response
public struct HealthResponse: Codable {
    public let status: String
    public let timestamp: Date?
    public let version: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case timestamp
        case version
    }
}