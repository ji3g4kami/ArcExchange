import Foundation

enum TickersFixture {
    static let twoTickersJSON = """
    [
        {
            "ask": "18.4105000000",
            "bid": "18.4069700000",
            "book": "usdc_mxn",
            "date": "2025-10-20T20:14:57.361483956"
        },
        {
            "ask": "1551.0000000000",
            "bid": "1539.4290300000",
            "book": "usdc_ars",
            "date": "2025-10-21T09:44:18.512194175"
        }
    ]
    """

    static var twoTickersData: Data { Data(twoTickersJSON.utf8) }
}
