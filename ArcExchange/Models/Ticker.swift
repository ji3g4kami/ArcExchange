import Foundation

nonisolated struct Ticker: Sendable, Equatable {
    let ask: Decimal
    let bid: Decimal
    let book: String
}

extension Ticker: Decodable {
    enum CodingKeys: String, CodingKey {
        case ask, bid, book
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.ask = try container.decodeDecimalString(forKey: .ask)
        self.bid = try container.decodeDecimalString(forKey: .bid)
        self.book = try container.decode(String.self, forKey: .book)
    }
}
