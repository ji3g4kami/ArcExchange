import Foundation

enum RateServiceError: Error, Equatable {
    case invalidURL
    case http(Int)
    case decoding(String)
    case transport(String)
}
