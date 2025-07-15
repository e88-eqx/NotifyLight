import Foundation

// MARK: - Crypto Asset Model

struct CryptoAsset: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let amount: Double
    let price: Double
    let isPositive: Bool
    
    // Computed properties for display
    var totalValue: Double {
        amount * price
    }
    
    var formattedAmount: String {
        if amount < 1 {
            return String(format: "%.4f", amount)
        } else if amount < 10 {
            return String(format: "%.3f", amount)
        } else {
            return String(format: "%.2f", amount)
        }
    }
    
    var formattedPrice: String {
        return String(format: "$%.2f", price)
    }
    
    var formattedTotalValue: String {
        return String(format: "$%.2f", totalValue)
    }
    
    var changeIndicator: String {
        return isPositive ? "↗" : "↘"
    }
}

// MARK: - Mock Data Provider

class MockData {
    static let shared = MockData()
    
    private init() {
        // NOTIFYLIGHT SDK INTEGRATION POINT: Mock Data Initialization
        print("MockData: ========== MOCK DATA INITIALIZED ==========")
        print("MockData: Creating sample crypto portfolio data...")
        print("MockData: SDK Integration Point - Portfolio data loaded, could trigger SDK events...")
        // Example: NotifyLight.shared.onPortfolioDataLoaded(assets: cryptoAssets)
    }
    
    // Sample crypto assets for testing
    let cryptoAssets: [CryptoAsset] = [
        CryptoAsset(
            symbol: "BTC",
            name: "Bitcoin",
            amount: 0.5,
            price: 43250.00,
            isPositive: true
        ),
        CryptoAsset(
            symbol: "ETH",
            name: "Ethereum",
            amount: 2.5,
            price: 2650.00,
            isPositive: false
        ),
        CryptoAsset(
            symbol: "ADA",
            name: "Cardano",
            amount: 1500.0,
            price: 0.48,
            isPositive: true
        ),
        CryptoAsset(
            symbol: "SOL",
            name: "Solana",
            amount: 25.0,
            price: 105.50,
            isPositive: true
        )
    ]
    
    // Calculate total portfolio value
    var totalPortfolioValue: Double {
        cryptoAssets.reduce(0) { total, asset in
            total + asset.totalValue
        }
    }
    
    var formattedTotalValue: String {
        return String(format: "$%.2f", totalPortfolioValue)
    }
    
    // Get asset count for logging
    var assetCount: Int {
        return cryptoAssets.count
    }
}