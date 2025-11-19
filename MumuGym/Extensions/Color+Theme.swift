import SwiftUI

extension Color {
    static let theme = ColorTheme()
}

struct ColorTheme {
    let primary = Color("PrimaryColor")
    let secondary = Color("SecondaryColor") 
    let accent = Color("AccentColor")
    let background = Color("BackgroundColor")
    let surface = Color("SurfaceColor")
    let success = Color.green
    let warning = Color.orange
    let error = Color.red
    
    // Fallback colors for when custom colors aren't available
    var primaryFallback: Color { Color.blue }
    var secondaryFallback: Color { Color.gray }
    var accentFallback: Color { Color.blue }
    var backgroundFallback: Color { Color(.systemBackground) }
    var surfaceFallback: Color { Color(.secondarySystemBackground) }
}

extension Color {
    // App theme colors matching splash screen
    static let primaryBlue = Color.blue.opacity(0.8)
    static let primaryPurple = Color.purple.opacity(0.6)
    static let appGradientStart = Color.blue.opacity(0.8)
    static let appGradientEnd = Color.purple.opacity(0.6)
    
    // UI colors
    static let lightGray = Color(.systemGray6)
    static let cardBackground = Color.white
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    
    // Button colors
    static let buttonPrimary = LinearGradient(
        gradient: Gradient(colors: [appGradientStart, appGradientEnd]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let editButtonColor = Color.blue.opacity(0.8)
    static let deleteButtonColor = Color.red.opacity(0.8)
}