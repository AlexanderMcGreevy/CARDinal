//  ReceivedCardsView.swift
//  CARDinal
//
//  Lists received business cards with search and navigation to detail.
//
//  Created by AI Assistant on 9/30/25.

import SwiftUI

struct ReceivedCardsView: View {
    @EnvironmentObject var store: CardStore
    @State private var search = ""
    @State private var showScanner = false

    var filtered: [BusinessCard] {
        guard !search.isEmpty else { return store.received }
        return store.received.filter { card in
            [card.fullName, card.company, card.role, card.email, card.phone, card.instagram, card.linkedIn]
                .compactMap { $0 }
                .joined(separator: " ")
                .localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .symbolVariant(.slash)
                            .foregroundStyle(.secondary)
                        Text(search.isEmpty ? "No cards yet" : "No matches")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        if search.isEmpty { Text("Scan someone's QR to add their card.").font(.footnote).foregroundStyle(.secondary) }
                        Button { showScanner = true } label: { Label("Scan QR", systemImage: "qrcode.viewfinder") }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal, 32)
                    .multilineTextAlignment(.center)
                } else {
                    List(filtered) { card in
                        NavigationLink(value: card) {
                            GlassCardView(card: card, compact: true)
                                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationDestination(for: BusinessCard.self) { card in
                CardDetailView(card: card)
            }
            .navigationTitle("Received")
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showScanner = true } label: { Image(systemName: "qrcode.viewfinder") }
                }
            }
            .sheet(isPresented: $showScanner) {
                QRScannerSheet { result in
                    showScanner = false
                    switch result {
                    case .success(let payload):
                        try? store.addReceived(from: payload)
                    case .failure: break
                    }
                }
            }
            .background(LinearGradient(colors: [Color.black, Color(white: 0.12)], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        }
    }
}

#Preview {
    ReceivedCardsView().environmentObject(CardStore())
}
