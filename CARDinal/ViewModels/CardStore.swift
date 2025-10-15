//
//  CardStore.swift
//  CARDinal
//
//  Data store for managing business cards.
//
//  Created by Alexander McGreevy on 9/30/25.
//

import SwiftUI
import Foundation
import Combine

@MainActor
class CardStore: ObservableObject {
    @Published var myCard: BusinessCard
    @Published var receivedCards: [BusinessCard] = []
    
    // Computed property alias for backward compatibility
    var received: [BusinessCard] {
        return receivedCards
    }
    
    private let myCardKey = "MyBusinessCard"
    private let receivedCardsKey = "ReceivedBusinessCards"
    
    init() {
        // Load my card from UserDefaults
        if let data = UserDefaults.standard.data(forKey: myCardKey),
           let card = try? JSONDecoder().decode(BusinessCard.self, from: data) {
            self.myCard = card
        } else {
            // Create default card
            self.myCard = BusinessCard(
                fullName: "Your Name",
                jobTitle: "Your Title",
                company: "Your Company",
                email: "your.email@example.com",
                phone: "+1 (555) 123-4567",
                website: URL(string: "https://www.yourwebsite.com"),
                resumeURL: "https://yourresume.com"
            )
        }
        
        // Load received cards from UserDefaults
        if let data = UserDefaults.standard.data(forKey: receivedCardsKey),
           let cards = try? JSONDecoder().decode([BusinessCard].self, from: data) {
            self.receivedCards = cards
        }
    }
    
    func saveMyCard() {
        if let data = try? JSONEncoder().encode(myCard) {
            UserDefaults.standard.set(data, forKey: myCardKey)
        }
    }
    
    func saveReceivedCards() {
        if let data = try? JSONEncoder().encode(receivedCards) {
            UserDefaults.standard.set(data, forKey: receivedCardsKey)
        }
    }
    
    func addReceivedCard(_ card: BusinessCard) {
        receivedCards.append(card)
        saveReceivedCards()
    }
    
    // Method alias for backward compatibility
    func addReceived(from payload: String) throws {
        guard let data = payload.data(using: .utf8),
              let card = try? JSONDecoder().decode(BusinessCard.self, from: data) else {
            throw NSError(domain: "CardStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid card data"])
        }
        addReceivedCard(card)
    }
    
    func deleteReceivedCard(_ card: BusinessCard) {
        receivedCards.removeAll { $0.id == card.id }
        saveReceivedCards()
    }
    
    func updateMyCard(_ card: BusinessCard) {
        myCard = card
        saveMyCard()
    }
    
    // Overloaded method that accepts a closure for EditCardView compatibility
    func updateMyCard(_ updateBlock: (inout BusinessCard) -> Void) {
        var updatedCard = myCard
        updateBlock(&updatedCard)
        myCard = updatedCard
        saveMyCard()
    }
}
