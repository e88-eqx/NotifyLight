import SwiftUI

struct PortfolioView: View {
    @State private var mockData = MockData.shared
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isLoading {
                    loadingView
                } else {
                    portfolioContent
                }
            }
            .navigationTitle("My Portfolio")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            // NOTIFYLIGHT SDK INTEGRATION POINT: Portfolio Screen Load
            print("PortfolioView: ========== PORTFOLIO VIEW LOADED ==========")
            print("PortfolioView: Loading portfolio data...")
            
            // NOTIFYLIGHT SDK INTEGRATION: Check for In-App Messages
            print("PortfolioView: SDK Integration Point - Checking for in-app messages on portfolio load...")
            Task {
                await NotifyLight.shared.checkForInAppMessages()
            }
            
            // NOTIFYLIGHT SDK INTEGRATION: Track Screen View
            print("PortfolioView: SDK Integration Point - Portfolio screen viewed by user...")
            NotifyLight.shared.trackScreenView(screen: "portfolio")
            
            // Simulate loading delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoading = false
                }
                
                // NOTIFYLIGHT SDK INTEGRATION: Portfolio Data Loaded
                print("PortfolioView: Portfolio data loaded successfully")
                print("PortfolioView: Total assets: \(mockData.assetCount)")
                print("PortfolioView: Total portfolio value: \(mockData.formattedTotalValue)")
                print("PortfolioView: SDK Integration Point - Portfolio data ready for SDK events...")
                
                // Track portfolio loaded event
                NotifyLight.shared.trackScreenView(screen: "portfolio_loaded")
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(red: 0.1, green: 0.137, blue: 0.196))
            
            Text("Loading Portfolio...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    private var portfolioContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Portfolio header
                portfolioHeader
                
                // Assets list
                assetsList
                
                // Footer spacer
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
    
    private var portfolioHeader: some View {
        VStack(spacing: 12) {
            Text("Total Portfolio Value")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(mockData.formattedTotalValue)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var assetsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(mockData.cryptoAssets) { asset in
                AssetRowView(asset: asset)
                    .onTapGesture {
                        // NOTIFYLIGHT SDK INTEGRATION: Asset Interaction
                        print("PortfolioView: User tapped on \(asset.symbol)")
                        print("PortfolioView: SDK Integration Point - Asset selected: \(asset.symbol)")
                        
                        // Track asset interaction
                        NotifyLight.shared.trackAssetInteraction(symbol: asset.symbol)
                        
                        // NOTIFYLIGHT SDK INTEGRATION: Show "Hello Again World" message on portfolio object click
                        print("PortfolioView: SDK Integration Point - Showing 'Hello Again World' message...")
                        Task {
                            await NotifyLight.shared.showInAppMessage(
                                title: "Hello Again World",
                                message: "You clicked on \(asset.symbol)! This is triggered by portfolio object interaction."
                            )
                        }
                    }
            }
        }
    }
}

struct AssetRowView: View {
    let asset: CryptoAsset
    
    var body: some View {
        HStack(spacing: 16) {
            // Asset symbol circle
            Circle()
                .fill(Color(red: 0.1, green: 0.137, blue: 0.196))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(asset.symbol)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
            
            // Asset info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(asset.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(asset.formattedTotalValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("\(asset.formattedAmount) \(asset.symbol)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text(asset.changeIndicator)
                            .font(.system(size: 12))
                            .foregroundColor(asset.isPositive ? .green : .red)
                        
                        Text(asset.formattedPrice)
                            .font(.system(size: 14))
                            .foregroundColor(asset.isPositive ? .green : .red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

#Preview {
    PortfolioView()
}