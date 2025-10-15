//
//  CARDinalApp.swift
//  CARDinal
//
//  Main app entry point with deep linking support for QR codes.
//
//  Created by AI Assistant on 9/30/25.

import SwiftUI

@main
struct CARDinalApp: App {
    @StateObject private var cardStore = CardStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cardStore)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        // Handle deep links from QR codes scanned with native camera
        if url.scheme == "cardinal" {
            if url.host == "addcard" {
                // Extract card data from URL query parameters
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let queryItems = components.queryItems {
                    
                    // Look for card data in query parameters
                    if let cardDataParam = queryItems.first(where: { $0.name == "data" }),
                       let cardDataString = cardDataParam.value {
                        // Try to add the card from the URL data
                        try? cardStore.addReceived(from: cardDataString)
                    }
                }
            }
        } else if url.absoluteString.hasPrefix("https://cardinal.app/card/") {
            // Handle universal links (for web-based QR codes)
            let cardId = String(url.absoluteString.dropFirst("https://cardinal.app/card/".count))
            // In a real app, you'd fetch the card data from your server using this ID
            // For now, we'll just show that the link was recognized
            print("Recognized universal link for card: \(cardId)")
        }
    }
}
