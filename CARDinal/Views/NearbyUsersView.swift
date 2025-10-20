//
//  NearbyUsersView.swift
//  CARDinal
//
//  View for discovering and connecting to nearby users via MultipeerConnectivity.
//
//  Created by AI Assistant on 10/20/25.
//

import SwiftUI
import MultipeerConnectivity

struct NearbyUsersView: View {
    @EnvironmentObject var store: CardStore
    @StateObject private var multipeerManager = MultipeerManager()
    @State private var showingReceivedCard = false
    @State private var selectedPeer: MCPeerID?

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    if multipeerManager.isBrowsing {
                        if multipeerManager.discoveredPeers.isEmpty {
                            searchingView
                        } else {
                            discoveredPeersSection
                        }
                    }

                    connectedPeersSection
                }
                .padding()
            }
            .background(BackgroundGradient())
            .navigationTitle("Nearby")
        }
        .onAppear {
            multipeerManager.setMyCard(store.myCard)
            multipeerManager.startBrowsing()
            multipeerManager.startAdvertising()
        }
        .onDisappear {
            multipeerManager.disconnect()
        }
        .sheet(isPresented: $showingReceivedCard) {
            if let card = multipeerManager.receivedCard {
                ReceivedCardSheet(card: card, onSave: {
                    store.addReceivedCard(card)
                    multipeerManager.receivedCard = nil
                    showingReceivedCard = false
                }, onDismiss: {
                    showingReceivedCard = false
                })
                .preferredColorScheme(.dark)
            }
        }
        .onChange(of: multipeerManager.receivedCard) { _, newCard in
            if newCard != nil {
                showingReceivedCard = true
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "bird.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, 20)

            Text("Find Nearby Users")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Discover people with CARDinal nearby and exchange business cards wirelessly")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 20) {
                StatusBadge(
                    icon: "antenna.radiowaves.left.and.right",
                    text: multipeerManager.isBrowsing ? "Searching" : "Idle",
                    color: multipeerManager.isBrowsing ? .green : .gray
                )

                StatusBadge(
                    icon: "person.wave.2.fill",
                    text: "\(multipeerManager.connectedPeers.count) Connected",
                    color: multipeerManager.connectedPeers.isEmpty ? .gray : .blue
                )
            }
        }
    }

    private var searchingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()

            Text("Looking for nearby users...")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Make sure both devices have this screen open")
                .font(.caption)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }

    private var discoveredPeersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Discovered")
                .font(.headline)
                .foregroundStyle(.gray)
                .padding(.horizontal)

            ForEach(multipeerManager.discoveredPeers, id: \.self) { peer in
                DiscoveredPeerRow(
                    peer: peer,
                    isConnected: multipeerManager.connectedPeers.contains(peer),
                    onConnect: {
                        multipeerManager.invitePeer(peer)
                    }
                )
            }
        }
    }

    private var connectedPeersSection: some View {
        Group {
            if !multipeerManager.connectedPeers.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Connected")
                        .font(.headline)
                        .foregroundStyle(.gray)
                        .padding(.horizontal)

                    ForEach(multipeerManager.connectedPeers, id: \.self) { peer in
                        ConnectedPeerRow(
                            peer: peer,
                            transferStatus: multipeerManager.transferProgress[peer.displayName],
                            onRequestCard: {
                                multipeerManager.sendCard(to: peer)
                                selectedPeer = peer
                            },
                            onRetryCard: {
                                multipeerManager.retryCardTransfer(from: peer)
                            },
                            onRetryResume: {
                                multipeerManager.retryResumeTransfer(from: peer)
                            }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct StatusBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption.bold())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.2))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

struct DiscoveredPeerRow: View {
    let peer: MCPeerID
    let isConnected: Bool
    let onConnect: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)

            VStack(alignment: .leading) {
                Text(peer.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(isConnected ? "Connected" : "Nearby")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            if !isConnected {
                Button(action: onConnect) {
                    Text("Connect")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ConnectedPeerRow: View {
    let peer: MCPeerID
    let transferStatus: MultipeerManager.TransferStatus?
    let onRequestCard: () -> Void
    let onRetryCard: () -> Void
    let onRetryResume: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)

                VStack(alignment: .leading) {
                    Text(peer.displayName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    if let status = transferStatus {
                        transferStatusText(status)
                    } else {
                        Text("Connected")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }

                Spacer()

                Button(action: onRequestCard) {
                    Text("Request Card")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.green)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }

            // Show retry buttons if there were errors
            if let status = transferStatus {
                if status.cardError != nil || status.resumeError != nil {
                    HStack(spacing: 12) {
                        if status.cardError != nil {
                            Button(action: onRetryCard) {
                                Label("Retry Card", systemImage: "arrow.clockwise")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.orange)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }

                        if status.resumeError != nil && status.cardReceived {
                            Button(action: onRetryResume) {
                                Label("Retry Resume", systemImage: "arrow.clockwise")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.orange)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                if status.cardReceived && !status.resumeReceived {
                    ProgressView(value: status.progress) {
                        Text("Receiving resume...")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func transferStatusText(_ status: MultipeerManager.TransferStatus) -> some View {
        if status.cardReceived && status.resumeReceived {
            Text("Card received ✓")
                .font(.caption)
                .foregroundStyle(.green)
        } else if status.cardReceived {
            Text("Card received, getting resume...")
                .font(.caption)
                .foregroundStyle(.orange)
        } else if status.cardError != nil {
            Text("Transfer failed")
                .font(.caption)
                .foregroundStyle(.red)
        } else {
            Text("Connected")
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }
}

struct ReceivedCardSheet: View {
    let card: BusinessCard
    let onSave: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                        .padding(.top, 20)

                    Text("Card Received!")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    GlassCardView(card: card)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        Button(action: onSave) {
                            Text("Save to Received Cards")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button(action: onDismiss) {
                            Text("Dismiss")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.ultraThinMaterial)
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(BackgroundGradient())
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(colors: [Color.black, Color(white: 0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
}

#Preview {
    NavigationStack {
        NearbyUsersView()
            .environmentObject(CardStore())
    }
}
