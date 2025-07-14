import Foundation

/// URLSession extensions for convenient async networking
extension URLSession {
    
    /// Performs async data task and returns decoded response
    func data<T: Codable>(
        for request: URLRequest,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let (data, response) = try await self.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard 200..<300 ~= httpResponse.statusCode else {
            // Try to decode error response
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                throw NetworkError.apiError(errorResponse.message, httpResponse.statusCode)
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        do {
            decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    /// Performs async data task without decoding response
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await self.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        return (data, httpResponse)
    }
}

/// Custom JSONDecoder for handling dates with fractional seconds
extension JSONDecoder.DateDecodingStrategy {
    static let iso8601WithFractionalSeconds = custom { decoder in
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        
        let formatters = [
            // ISO8601 with fractional seconds
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                return formatter
            }(),
            // ISO8601 without fractional seconds
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                return formatter
            }(),
            // Standard ISO8601
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                return formatter
            }()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Cannot decode date string \(string)"
        )
    }
}

/// Network error types
public enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String, Int)
    case decodingError(Error)
    case encodingError(Error)
    case noData
    case timeout
    case noInternetConnection
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let code):
            return "HTTP error with status code: \(code)"
        case .apiError(let message, let code):
            return "API error (\(code)): \(message)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Encoding error: \(error.localizedDescription)"
        case .noData:
            return "No data received"
        case .timeout:
            return "Request timeout"
        case .noInternetConnection:
            return "No internet connection"
        }
    }
}

/// API error response model
struct APIErrorResponse: Codable {
    let success: Bool
    let message: String
    let code: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case code
    }
}