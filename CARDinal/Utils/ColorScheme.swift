//
//  ColorScheme.swift
//  CARDinal
//
//  Centralized color definitions to enforce dark mode throughout the app.
//
//  Created by AI Assistant on 10/20/25.
//

import SwiftUI

/// Centralized color scheme that always uses dark mode colors
struct AppColors {
    // Text Colors
    static let primaryText = Color.white
    static let secondaryText = Color.gray
    static let tertiaryText = Color(white: 0.6)

    // Background Colors
    static let primaryBackground = Color.black
    static let secondaryBackground = Color(white: 0.12)
    static let cardBackground = Color(white: 0.15)

    // Accent Colors
    static let accent = Color.blue
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red

    // UI Element Colors
    static let separator = Color(white: 0.3)
    static let materialBackground = Color.clear // Uses .ultraThinMaterial
}

/// View modifier to enforce dark mode colors on all text
struct DarkModeText: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .foregroundStyle(color)
            .colorScheme(.dark)
    }
}

extension View {
    /// Apply primary text color (white)
    func primaryText() -> some View {
        self.modifier(DarkModeText(color: AppColors.primaryText))
    }

    /// Apply secondary text color (gray)
    func secondaryText() -> some View {
        self.modifier(DarkModeText(color: AppColors.secondaryText))
    }

    /// Apply tertiary text color (light gray)
    func tertiaryText() -> some View {
        self.modifier(DarkModeText(color: AppColors.tertiaryText))
    }

    /// Enforce dark mode for this view and all subviews
    func forceDarkMode() -> some View {
        self
            .preferredColorScheme(.dark)
            .environment(\.colorScheme, .dark)
    }
}
