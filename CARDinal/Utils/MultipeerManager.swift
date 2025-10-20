//
//  MultipeerManager.swift
//  CARDinal
//
//  Manager for peer-to-peer device discovery and business card exchange.
//
//  Created by AI Assistant on 10/20/25.
//

import Foundation
import MultipeerConnectivity
import Combine

@MainActor
class MultipeerManager: NSObject, ObservableObject {
    private let serviceType = "cardinal-card"
    private let myPeerID: MCPeerID
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var session: MCSession?

    @Published var discoveredPeers: [MCPeerID] = []
    @Published var connectedPeers: [MCPeerID] = []
    @Published var receivedCard: BusinessCard?
    @Published var isAdvertising = false
    @Published var isBrowsing = false

    // Transfer progress tracking
    @Published var transferProgress: [String: TransferStatus] = [:]

    struct TransferStatus {
        var cardReceived: Bool = false
        var resumeReceived: Bool = false
        var cardError: String?
        var resumeError: String?
        var progress: Double = 0.0
    }

    private var myCard: BusinessCard?

    override init() {
        // Create peer ID with device name
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()

        // Initialize session
        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.session?.delegate = self
    }

    func setMyCard(_ card: BusinessCard) {
        self.myCard = card
    }

    func startAdvertising() {
        guard let myCard = myCard else { return }

        // Include name in discovery info so others can see who they're connecting to
        let discoveryInfo = ["name": myCard.fullName]

        advertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: discoveryInfo,
            serviceType: serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        isAdvertising = true
    }

    func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        isAdvertising = false
    }

    func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        isBrowsing = true
    }

    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        discoveredPeers.removeAll()
        isBrowsing = false
    }

    func invitePeer(_ peerID: MCPeerID) {
        guard let browser = browser, let session = session else { return }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }

    func sendCard(to peerID: MCPeerID) {
        guard let myCard = myCard, let session = session else { return }

        do {
            // Create a card without resume data for initial transfer
            var cardToSend = myCard
            let hasResume = cardToSend.resumeData != nil

            // Send card data first (without resume to keep it small)
            let originalResumeData = cardToSend.resumeData
            cardToSend.resumeData = nil

            let cardData = try JSONEncoder().encode(cardToSend)
            try session.send(cardData, toPeers: [peerID], with: .reliable)

            // Send resume separately if it exists
            if hasResume, let resumeData = originalResumeData {
                sendResume(resumeData, fileName: myCard.resumeFileName, to: peerID)
            }
        } catch {
            print("Error sending card: \(error.localizedDescription)")
        }
    }

    func sendResume(_ data: Data, fileName: String?, to peerID: MCPeerID) {
        guard let session = session else { return }

        do {
            // Create a payload with filename metadata
            let payload: [String: Any] = [
                "type": "resume",
                "data": data,
                "fileName": fileName ?? "Resume.pdf"
            ]

            let payloadData = try JSONSerialization.data(withJSONObject: payload)
            try session.send(payloadData, toPeers: [peerID], with: .reliable)
        } catch {
            print("Error sending resume: \(error.localizedDescription)")
            Task { @MainActor in
                if var status = transferProgress[peerID.displayName] {
                    status.resumeError = "Failed to send resume"
                    transferProgress[peerID.displayName] = status
                }
            }
        }
    }

    func retryCardTransfer(from peerID: MCPeerID) {
        // Request card resend
        guard let session = session else { return }

        do {
            let request = ["type": "retry_card"]
            let data = try JSONSerialization.data(withJSONObject: request)
            try session.send(data, toPeers: [peerID], with: .reliable)
        } catch {
            print("Error requesting card retry: \(error)")
        }
    }

    func retryResumeTransfer(from peerID: MCPeerID) {
        // Request resume resend
        guard let session = session else { return }

        do {
            let request = ["type": "retry_resume"]
            let data = try JSONSerialization.data(withJSONObject: request)
            try session.send(data, toPeers: [peerID], with: .reliable)
        } catch {
            print("Error requesting resume retry: \(error)")
        }
    }

    func disconnect() {
        session?.disconnect()
        stopAdvertising()
        stopBrowsing()
        connectedPeers.removeAll()
        discoveredPeers.removeAll()
        transferProgress.removeAll()
    }
}

// MARK: - MCSessionDelegate
extension MultipeerManager: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                if !connectedPeers.contains(peerID) {
                    connectedPeers.append(peerID)
                }
                // Initialize transfer status
                transferProgress[peerID.displayName] = TransferStatus()

            case .notConnected:
                connectedPeers.removeAll { $0 == peerID }
                transferProgress.removeValue(forKey: peerID.displayName)

            case .connecting:
                break

            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            // Try to decode as JSON first (for resume or retry requests)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let type = json["type"] as? String {
                    switch type {
                    case "resume":
                        // Handle resume data
                        if let resumeData = json["data"] as? Data,
                           let fileName = json["fileName"] as? String {
                            handleReceivedResume(resumeData, fileName: fileName, from: peerID)
                        }
                        return

                    case "retry_card":
                        // Resend card
                        sendCard(to: peerID)
                        return

                    case "retry_resume":
                        // Resend resume
                        if let card = myCard, let resumeData = card.resumeData {
                            sendResume(resumeData, fileName: card.resumeFileName, to: peerID)
                        }
                        return

                    default:
                        break
                    }
                }
            }

            // Try to decode as BusinessCard
            if let card = try? JSONDecoder().decode(BusinessCard.self, from: data) {
                handleReceivedCard(card, from: peerID)
            }
        }
    }

    private func handleReceivedCard(_ card: BusinessCard, from peerID: MCPeerID) {
        receivedCard = card

        if var status = transferProgress[peerID.displayName] {
            status.cardReceived = true
            status.progress = card.resumeData == nil ? 1.0 : 0.5
            transferProgress[peerID.displayName] = status
        }
    }

    private func handleReceivedResume(_ data: Data, fileName: String, from peerID: MCPeerID) {
        guard var card = receivedCard else { return }

        card.resumeData = data
        card.resumeFileName = fileName
        receivedCard = card

        if var status = transferProgress[peerID.displayName] {
            status.resumeReceived = true
            status.progress = 1.0
            transferProgress[peerID.displayName] = status
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not used
    }

    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not used
    }

    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not used
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor in
            // Auto-accept invitations
            invitationHandler(true, session)
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            if !discoveredPeers.contains(peerID) && peerID != myPeerID {
                discoveredPeers.append(peerID)
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            discoveredPeers.removeAll { $0 == peerID }
        }
    }
}
