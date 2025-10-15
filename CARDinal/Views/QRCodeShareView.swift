//  QRCodeShareView.swift
//  CARDinal
//
//  Displays QR code for sharing business card with deep linking support.
//
//  Created by AI Assistant on 9/30/25.

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeShareView: View {
    let card: BusinessCard
    @Environment(\.dismiss) private var dismiss
    
    private var qrCodeURL: String {
        // Create deep link URL that native camera can open
        guard let cardData = try? JSONEncoder().encode(card),
              let cardString = String(data: cardData, encoding: .utf8),
              let encodedData = cardString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return "cardinal://addcard"
        }
        return "cardinal://addcard?data=\(encodedData)"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Share Your Card")
                        .font(.title2.weight(.semibold))
                    Text("Others can scan this QR code with their camera app to add your card")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // QR Code
                if let qrImage = generateQRCode(from: qrCodeURL) {
                    VStack(spacing: 20) {
                        qrImage
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 280, height: 280)
                            .background(.white, in: RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        // Card preview
                        GlassCardView(card: card, compact: true)
                            .scaleEffect(0.8)
                    }
                } else {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .frame(width: 280, height: 280)
                        .overlay {
                            Text("QR Code Generation Failed")
                                .foregroundStyle(.secondary)
                        }
                }
                
                // Instructions
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "camera")
                            .foregroundStyle(.blue)
                            .font(.title3)
                        Text("Point any camera app at the QR code")
                            .font(.subheadline)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "app.badge.plus")
                            .foregroundStyle(.green)
                            .font(.title3)
                        Text("Tap the notification to open CARDinal")
                            .font(.subheadline)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(.purple)
                            .font(.title3)
                        Text("Your card will be automatically added")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Share button
                ShareLink(item: qrCodeURL) {
                    Label("Share QR Code", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .background(LinearGradient(colors: [Color.black, Color(white: 0.12)], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        }
    }
    
    private func generateQRCode(from string: String) -> Image? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return Image(uiImage: UIImage(cgImage: cgImage))
    }
}

#Preview {
    QRCodeShareView(card: BusinessCard(
        fullName: "Jane Doe",
        jobTitle: "Product Manager",
        company: "Acme Corp",
        email: "jane@acme.com",
        phone: "555-123-4567",
        website: URL(string: "https://acme.com"),
        accentColor: .blue,
        role: "Product Manager"
    ))
}
