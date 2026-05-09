import Foundation

enum RateServiceError: Error, Equatable {
    case invalidURL
    case http(Int)
    case decoding(String)
    case transport(String)

    static func == (lhs: RateServiceError, rhs: RateServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL): return true
        case (.http(let a), .http(let b)): return a == b
        case (.decoding, .decoding): return true
        case (.transport, .transport): return true
        default: return false
        }
    }
}
