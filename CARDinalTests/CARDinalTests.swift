//
//  CARDinalTests.swift
//  CARDinalTests
//
//  Created by Alexander McGreevy on 9/30/25.
//

import Testing
import SwiftUI
@testable import CARDinal

struct CARDinalTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @Test func testCardMaterialTypes() async throws {
        // Test that all material types can be created and have distinct properties
        let materials: [CardMaterial] = [.glass, .neon, .metal, .frosted, .holographic, .matte]

        #expect(materials.count == 6, "Should have 6 different material types")

        for material in materials {
            #expect(!material.displayName.isEmpty, "Material \(material) should have a display name")
            #expect(!material.icon.isEmpty, "Material \(material) should have an icon")
        }
    }

    @Test func testBusinessCardWithAllMaterials() async throws {
        // Create a card with each material type
        let testCards = [
            BusinessCard(
                fullName: "Glass Card Test",
                jobTitle: "Designer",
                company: "Glass Co",
                email: "glass@test.com",
                phone: "+1 (555) 111-1111",
                material: .glass
            ),
            BusinessCard(
                fullName: "Neon Card Test",
                jobTitle: "Developer",
                company: "Neon Inc",
                email: "neon@test.com",
                phone: "+1 (555) 222-2222",
                material: .neon
            ),
            BusinessCard(
                fullName: "Metal Card Test",
                jobTitle: "Engineer",
                company: "Metal Corp",
                email: "metal@test.com",
                phone: "+1 (555) 333-3333",
                material: .metal
            ),
            BusinessCard(
                fullName: "Frosted Card Test",
                jobTitle: "Manager",
                company: "Frosted LLC",
                email: "frosted@test.com",
                phone: "+1 (555) 444-4444",
                material: .frosted
            ),
            BusinessCard(
                fullName: "Holographic Card Test",
                jobTitle: "Artist",
                company: "Holo Studios",
                email: "holo@test.com",
                phone: "+1 (555) 555-5555",
                material: .holographic
            ),
            BusinessCard(
                fullName: "Matte Card Test",
                jobTitle: "Consultant",
                company: "Matte Co",
                email: "matte@test.com",
                phone: "+1 (555) 666-6666",
                material: .matte
            )
        ]

        // Verify each card was created with the correct material
        #expect(testCards[0].material == .glass)
        #expect(testCards[1].material == .neon)
        #expect(testCards[2].material == .metal)
        #expect(testCards[3].material == .frosted)
        #expect(testCards[4].material == .holographic)
        #expect(testCards[5].material == .matte)

        // Verify all cards have unique identifiers
        let uniqueIds = Set(testCards.map { $0.id })
        #expect(uniqueIds.count == testCards.count, "All cards should have unique IDs")
    }

    @Test func testCardPersistence() async throws {
        // Test that cards can be encoded and decoded
        let originalCard = BusinessCard(
            fullName: "Test User",
            jobTitle: "Test Engineer",
            company: "Test Corp",
            email: "test@test.com",
            phone: "+1 (555) 123-4567",
            material: .neon,
            accentColor: .blue
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(originalCard)
        let decodedCard = try decoder.decode(BusinessCard.self, from: data)

        #expect(decodedCard.fullName == originalCard.fullName)
        #expect(decodedCard.email == originalCard.email)
        #expect(decodedCard.material == originalCard.material)
        #expect(decodedCard.accentColorHex == originalCard.accentColorHex)
    }

    @MainActor
    @Test func testCardStoreAddAndDelete() async throws {
        // Test adding and deleting cards from the store
        let store = CardStore()
        let initialCount = store.receivedCards.count

        let testCard = BusinessCard(
            fullName: "Test Contact",
            jobTitle: "Test Role",
            company: "Test Company",
            email: "contact@test.com",
            material: .glass
        )

        store.addReceivedCard(testCard)
        #expect(store.receivedCards.count == initialCount + 1, "Should have one more card after adding")

        store.deleteReceivedCard(testCard)
        #expect(store.receivedCards.count == initialCount, "Should return to initial count after deleting")
    }

}
