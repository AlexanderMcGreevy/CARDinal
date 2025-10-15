//  GlassCardView.swift
//  CARDinal
//
//  A reusable glass / liquid glass style business card view.
//
//  Created by AI Assistant on 9/30/25.

import SwiftUI

struct GlassCardView: View {
    let card: BusinessCard
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline){
                Text(card.fullName)
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Spacer()
                if card.hasResume {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(card.accentColor)
                        .font(.caption)
                }
            }
            Text(card.role)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(card.company)
                .font(.footnote.weight(.medium))
                .foregroundStyle(card.accentColor.gradient)
                .lineLimit(1)
            Divider().opacity(0.25)
            infoRows
            if !compact { socials }
        }
        .padding(18)
        .background(MaterialBackground(material: card.material, tint: card.accentColor))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(card.accentColor.opacity(0.35), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: card.accentColor.opacity(0.25), radius: 20, y: 8)
        .contentShape(Rectangle())
    }

    private var infoRows: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let phone = card.phone, !phone.isEmpty {
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundStyle(card.accentColor)
                        .frame(width: 12)
                    Text(phone)
                        .font(.caption)
                }
            }
            
            if !card.email.isEmpty {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(card.accentColor)
                        .frame(width: 12)
                    Text(card.email)
                        .font(.caption)
                }
            }
            
            if let website = card.website {
                HStack {
                    Image(systemName: "globe")
                        .foregroundStyle(card.accentColor)
                        .frame(width: 12)
                    Text(website.absoluteString)
                        .font(.caption)
                }
            }
        }
    }
    
    private var socials: some View {
        HStack(spacing: 12) {
            if !card.linkedIn.isEmpty {
                Image(systemName: "person.crop.rectangle")
                    .foregroundStyle(card.accentColor)
            }
            if !card.twitter.isEmpty {
                Image(systemName: "at")
                    .foregroundStyle(card.accentColor)
            }
            if !card.instagram.isEmpty {
                Image(systemName: "camera")
                    .foregroundStyle(card.accentColor)
            }
            Spacer()
        }
    }
}

// MARK: - Material Background Component
struct MaterialBackground: View {
    let material: CardMaterial
    let tint: Color
    
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .background(
                LinearGradient(
                    colors: [tint.opacity(0.1), tint.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

#Preview {
    GlassCardView(card: BusinessCard(
        fullName: "John Doe",
        jobTitle: "Software Engineer",
        company: "Tech Corp",
        email: "john@techcorp.com",
        phone: "+1 (555) 123-4567",
        resumeURL: "https://johndoe.com/resume"
    ))
    .padding()
}
