//
//  CardDetailView.swift
//  CARDinal
//
//  Detail view for a single (received) business card with actionable links.
//
//  Created by AI Assistant on 9/30/25.

import SwiftUI

struct CardDetailView: View {
    let card: BusinessCard
    var isMyCard: Bool = false
    @Environment(\.openURL) private var openURL
    @State private var showingShareSheet = false
    @State private var showingPDFViewer = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                GlassCardView(card: card)
                    .tiltable()
                    .padding(.top, 32)
                
                if card.resumeData != nil || !card.resumeURL.isEmpty {
                    resumeSection
                }
                
                actionSection
                contactSection
                Spacer(minLength: 20)
            }
            .padding(.horizontal)
        }
        .background(LinearGradient(colors: [Color.black, Color(white: 0.12)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea())
        .navigationTitle(card.fullName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var resumeSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(.blue)
                    .font(.title2)

                VStack(alignment: .leading) {
                    Text("Resume Available")
                        .font(.headline)
                        .foregroundStyle(.white)
                    if let fileName = card.resumeFileName {
                        Text(fileName)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    } else {
                        Text("View or download their resume")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }

                Spacer()

                Button("View") {
                    if card.resumeData != nil {
                        // Show in-app PDF viewer
                        showingPDFViewer = true
                    } else if let url = URL(string: card.resumeURL) {
                        // Open external URL
                        openURL(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .sheet(isPresented: $showingPDFViewer) {
            Group {
                if let resumeData = card.resumeData {
                    PDFViewer(pdfData: resumeData, fileName: card.resumeFileName ?? "Resume.pdf")
                        .preferredColorScheme(.dark)
                } else {
                    EmptyView()
                }
            }
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            if !card.email.isEmpty {
                Button(action: { openEmail() }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text("Send Email")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .padding()
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                .foregroundStyle(.blue)
            }
            
            if let phone = card.phone, !phone.isEmpty {
                Button(action: { callPhone() }) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Call")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .padding()
                    .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                .foregroundStyle(.green)
            }
            
            if card.website != nil {
                Button(action: {
                    if let website = card.website {
                        openURL(website)
                    }
                }) {
                    HStack {
                        Image(systemName: "globe")
                        Text("Visit Website")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .padding()
                    .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                .foregroundStyle(.purple)
            }
        }
    }
    
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Information")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                if !card.email.isEmpty {
                    ContactRow(icon: "envelope", title: "Email", value: card.email)
                }
                
                if let phone = card.phone, !phone.isEmpty {
                    ContactRow(icon: "phone", title: "Phone", value: phone)
                }
                
                if card.website != nil {
                    ContactRow(icon: "globe", title: "Website", value: card.website?.absoluteString ?? "")
                }
                
                if !card.linkedIn.isEmpty {
                    ContactRow(icon: "person.crop.rectangle", title: "LinkedIn", value: card.linkedIn)
                }
                
                if !card.twitter.isEmpty {
                    ContactRow(icon: "at", title: "Twitter", value: card.twitter)
                }
                
                if !card.instagram.isEmpty {
                    ContactRow(icon: "camera", title: "Instagram", value: card.instagram)
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func openEmail() {
        if let url = URL(string: "mailto:\(card.email)") {
            openURL(url)
        }
    }
    
    private func callPhone() {
        guard let phone = card.phone else { return }
        let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel:\(cleanPhone)") {
            openURL(url)
        }
    }
}

struct ContactRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.gray)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.gray)
                Text(value)
                    .font(.body)
                    .foregroundStyle(.white)
            }
            
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        CardDetailView(card: BusinessCard(
            fullName: "John Doe",
            jobTitle: "Software Engineer",
            company: "Tech Corp",
            email: "john@techcorp.com",
            phone: "+1 (555) 123-4567",
            website: URL(string: "https://techcorp.com"),
            linkedIn: "johndoe",
            twitter: "johndoe",
            instagram: "johndoe",
            resumeURL: "https://johndoe.com/resume"
        ))
    }
}
