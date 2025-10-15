//
//  BusinessCard.swift
//  CARDinal
//
//  Business card data model.
//
//  Created by Alexander McGreevy on 9/30/25.
//

import SwiftUI
import Foundation

struct BusinessCard: Identifiable, Codable, Hashable {
    var id = UUID()
    var fullName: String
    var jobTitle: String
    var company: String
    var email: String
    var phone: String?  // Optional to match EditCardView expectations
    var website: URL?
    var linkedIn: String
    var twitter: String
    var instagram: String
    var notes: String
    var resumeURL: String
    var profileImageData: Data?
    var role: String
    var material: CardMaterial
    var resumeData: Data?
    var resumeFileName: String?
    
    // Make accentColorHex a stored property that can be set
    private var _accentColor: Color
    private var _accentColorHex: String
    
    var accentColor: Color {
        get { _accentColor }
        set {
            _accentColor = newValue
            _accentColorHex = newValue.toHex()
        }
    }
    
    var accentColorHex: String {
        get { _accentColorHex }
        set {
            _accentColorHex = newValue
            if let color = Color(hex: newValue) {
                _accentColor = color
            }
        }
    }
    
    var backgroundColor: Color
    var textColor: Color

    init(
        fullName: String = "",
        jobTitle: String = "",
        company: String = "",
        email: String = "",
        phone: String? = nil,
        website: URL? = nil,
        linkedIn: String = "",
        twitter: String = "",
        instagram: String = "",
        notes: String = "",
        resumeURL: String = "",
        accentColor: Color = .blue,
        backgroundColor: Color = .white,
        textColor: Color = .black,
        profileImageData: Data? = nil,
        role: String = "",
        material: CardMaterial = .standard,
        resumeData: Data? = nil,
        resumeFileName: String? = nil
    ) {
        self.fullName = fullName
        self.jobTitle = jobTitle
        self.company = company
        self.email = email
        self.phone = phone
        self.website = website
        self.linkedIn = linkedIn
        self.twitter = twitter
        self.instagram = instagram
        self.notes = notes
        self.resumeURL = resumeURL
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.profileImageData = profileImageData
        self.role = role.isEmpty ? jobTitle : role
        self.material = material
        self.resumeData = resumeData
        self.resumeFileName = resumeFileName
        
        // Initialize color properties
        self._accentColor = accentColor
        self._accentColorHex = accentColor.toHex()
    }

    var cardURL: String {
        return "cardinal://card/\(id.uuidString)"
    }

    var isEmpty: Bool {
        return fullName.isEmpty && jobTitle.isEmpty && company.isEmpty && email.isEmpty
    }

    var hasResume: Bool {
        return !resumeURL.isEmpty
    }
}

enum CardMaterial: String, CaseIterable, Codable {
    case standard = "Standard"
    case premium = "Premium"
    case luxury = "Luxury"
    case eco = "Eco-Friendly"

    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .standard:
            return "rectangle"
        case .premium:
            return "rectangle.fill"
        case .luxury:
            return "sparkles.rectangle.stack"
        case .eco:
            return "leaf"
        }
    }
}

// MARK: - Color Extensions
extension Color {
    func toHex() -> String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "#007AFF"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
    
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Codable Implementation
extension BusinessCard {
    enum CodingKeys: String, CodingKey {
        case id, fullName, jobTitle, company, email, phone, linkedIn, twitter, instagram, notes, resumeURL, profileImageData, role, material
        case websiteString, accentColorHex, backgroundColor, textColor, resumeData, resumeFileName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let idString = try container.decode(String.self, forKey: .id)
        id = UUID(uuidString: idString) ?? UUID()

        fullName = try container.decode(String.self, forKey: .fullName)
        jobTitle = try container.decode(String.self, forKey: .jobTitle)
        company = try container.decode(String.self, forKey: .company)
        email = try container.decode(String.self, forKey: .email)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        linkedIn = try container.decode(String.self, forKey: .linkedIn)
        twitter = try container.decode(String.self, forKey: .twitter)
        instagram = try container.decodeIfPresent(String.self, forKey: .instagram) ?? ""
        notes = try container.decode(String.self, forKey: .notes)
        resumeURL = try container.decode(String.self, forKey: .resumeURL)
        profileImageData = try container.decodeIfPresent(Data.self, forKey: .profileImageData)
        role = try container.decodeIfPresent(String.self, forKey: .role) ?? ""
        material = try container.decodeIfPresent(CardMaterial.self, forKey: .material) ?? .standard
        resumeData = try container.decodeIfPresent(Data.self, forKey: .resumeData)
        resumeFileName = try container.decodeIfPresent(String.self, forKey: .resumeFileName)

        // Decode website
        if let websiteString = try container.decodeIfPresent(String.self, forKey: .websiteString) {
            website = URL(string: websiteString)
        } else {
            website = nil
        }

        // Decode colors
        let accentHex = try container.decodeIfPresent(String.self, forKey: .accentColorHex) ?? "#007AFF"
        _accentColorHex = accentHex
        _accentColor = Color(hex: accentHex) ?? .blue
        backgroundColor = .white  // Default values for now
        textColor = .black
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id.uuidString, forKey: .id)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(jobTitle, forKey: .jobTitle)
        try container.encode(company, forKey: .company)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encode(linkedIn, forKey: .linkedIn)
        try container.encode(twitter, forKey: .twitter)
        try container.encode(instagram, forKey: .instagram)
        try container.encode(notes, forKey: .notes)
        try container.encode(resumeURL, forKey: .resumeURL)
        try container.encodeIfPresent(profileImageData, forKey: .profileImageData)
        try container.encode(role, forKey: .role)
        try container.encode(material, forKey: .material)
        try container.encodeIfPresent(resumeData, forKey: .resumeData)
        try container.encodeIfPresent(resumeFileName, forKey: .resumeFileName)
        try container.encode(accentColorHex, forKey: .accentColorHex)

        // Encode website
        try container.encodeIfPresent(website?.absoluteString, forKey: .websiteString)
    }
}
