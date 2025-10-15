//  SettingsView.swift
//  CARDinal
//
//  Settings and preferences including Apple Wallet integration.
//
//  Created by Alexander McGreevy on 10/8/25.
//

import SwiftUI
import PassKit

struct SettingsView: View {
    @EnvironmentObject var store: CardStore
    @State private var showingWalletError = false
    @State private var walletErrorMessage = ""
    @State private var isAddingToWallet = false
    @State private var showingAbout = false
    @State private var enableNotifications = true
    @State private var enableQRScanning = true
    @State private var autoSaveCards = true
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Digital Wallet Section
                Section("Digital Wallet") {
                    Button(action: addToWallet) {
                        HStack {
                            Image(systemName: "wallet.pass")
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 24)
                                .background(
                                    LinearGradient(colors: [.black, .gray], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    in: RoundedRectangle(cornerRadius: 6)
                                )
                            
                            VStack(alignment: .leading) {
                                Text("Add to Apple Wallet")
                                    .foregroundStyle(.primary)
                                Text("Create a wallet pass for your business card")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if isAddingToWallet {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isAddingToWallet || store.myCard.isEmpty)
                    
                    Text("Your wallet pass will include a QR code linking to your digital business card and a link to view your resume.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                // MARK: - Card Settings Section
                Section("Card Settings") {
                    NavigationLink(destination: EditCardView()) {
                        HStack {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundStyle(store.myCard.accentColor)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text("Edit My Card")
                                Text("Update your business card information")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink(destination: QRCodeShareView(card: store.myCard)) {
                        HStack {
                            Image(systemName: "qrcode")
                                .foregroundStyle(.blue)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text("Share QR Code")
                                Text("Generate QR code for your card")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // MARK: - App Preferences Section
                Section("App Preferences") {
                    Toggle("Enable Notifications", isOn: $enableNotifications)
                        .onChange(of: enableNotifications) { _, newValue in
                            UserDefaults.standard.set(newValue, forKey: "enableNotifications")
                        }
                    
                    Toggle("Enable QR Scanning", isOn: $enableQRScanning)
                        .onChange(of: enableQRScanning) { _, newValue in
                            UserDefaults.standard.set(newValue, forKey: "enableQRScanning")
                        }
                    
                    Toggle("Auto-Save Received Cards", isOn: $autoSaveCards)
                        .onChange(of: autoSaveCards) { _, newValue in
                            UserDefaults.standard.set(newValue, forKey: "autoSaveCards")
                        }
                }
                
                // MARK: - Data Management Section
                Section("Data Management") {
                    Button("Clear Received Cards") {
                        store.receivedCards.removeAll()
                        store.saveReceivedCards()
                    }
                    .foregroundStyle(.orange)
                    
                    Button("Reset My Card") {
                        store.myCard = BusinessCard()
                        store.saveMyCard()
                    }
                    .foregroundStyle(.red)
                }
                
                // MARK: - Information Section
                Section("Information") {
                    Button("About CARDinal") {
                        showingAbout = true
                    }
                    .foregroundStyle(.primary)
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Apple Wallet", isPresented: $showingWalletError) {
                Button("OK") { }
            } message: {
                Text(walletErrorMessage)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
        .onAppear {
            loadPreferences()
        }
    }
    
    // MARK: - Apple Wallet Integration
    private func addToWallet() {
        guard !store.myCard.isEmpty else {
            showWalletError("Please complete your business card information first.")
            return
        }
        
        guard PKPassLibrary.isPassLibraryAvailable() else {
            showWalletError("Apple Wallet is not available on this device.")
            return
        }
        
        isAddingToWallet = true
        
        // Simulate creating a wallet pass
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isAddingToWallet = false
            
            // In a real implementation, you would:
            // 1. Generate a .pkpass file on your server with:
            //    - Business card information (front side)
            //    - QR code linking to your digital card
            //    - Resume link on the back side
            //    - Styled to match your business card design
            // 2. Download and present the pass to the user
            
            self.showWalletError("Success! Your business card would be added to Apple Wallet with:\n\n• Front: Your business card design\n• QR Code: Links to \(self.store.myCard.cardURL)\n• Back: Resume link to \(self.store.myCard.resumeURL)")
        }
    }
    
    private func showWalletError(_ message: String) {
        walletErrorMessage = message
        showingWalletError = true
    }
    
    private func loadPreferences() {
        enableNotifications = UserDefaults.standard.bool(forKey: "enableNotifications")
        enableQRScanning = UserDefaults.standard.bool(forKey: "enableQRScanning")
        autoSaveCards = UserDefaults.standard.bool(forKey: "autoSaveCards")
    }
}

// MARK: - Supporting Views
struct AboutView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.square")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                
                Text("CARDinal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("The modern way to share and manage business cards")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Features:")
                        .font(.headline)
                    
                    Label("Digital business cards", systemImage: "person.crop.square")
                    Label("QR code sharing", systemImage: "qrcode")
                    Label("Apple Wallet integration", systemImage: "wallet.pass")
                    Label("Resume linking", systemImage: "doc.text")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding()
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(CardStore())
}
