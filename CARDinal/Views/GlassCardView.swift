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
                    .foregroundStyle(.white)
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
                .foregroundStyle(.gray)
                .lineLimit(1)
            Text(card.company)
                .font(.footnote.weight(.medium))
                .foregroundStyle(card.accentColor)
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
                        .foregroundStyle(.white)
                }
            }

            if !card.email.isEmpty {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(card.accentColor)
                        .frame(width: 12)
                    Text(card.email)
                        .font(.caption)
                        .foregroundStyle(.white)
                }
            }

            if let website = card.website {
                HStack {
                    Image(systemName: "globe")
                        .foregroundStyle(card.accentColor)
                        .frame(width: 12)
                    Text(website.absoluteString)
                        .font(.caption)
                        .foregroundStyle(.white)
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
        switch material {
        case .glass:
            Rectangle()
                .fill(.ultraThinMaterial)
                .background(
                    LinearGradient(
                        colors: [tint.opacity(0.15), tint.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        case .neon:
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.8), tint.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(.ultraThinMaterial.opacity(0.3))
        case .metal:
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.gray.opacity(0.6),
                            Color.gray.opacity(0.3),
                            Color.gray.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    LinearGradient(
                        colors: [tint.opacity(0.3), .clear, tint.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        case .frosted:
            Rectangle()
                .fill(.thickMaterial)
                .background(
                    LinearGradient(
                        colors: [tint.opacity(0.2), tint.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        case .holographic:
            Rectangle()
                .fill(
                    AngularGradient(
                        colors: [
                            tint,
                            tint.opacity(0.7),
                            Color.purple.opacity(0.6),
                            Color.pink.opacity(0.6),
                            tint.opacity(0.7),
                            tint
                        ],
                        center: .topLeading
                    )
                )
                .overlay(.ultraThinMaterial.opacity(0.5))
        case .matte:
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.9), tint.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
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
