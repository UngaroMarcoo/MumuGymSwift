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
    // Modern app theme colors
    static let primaryBlue = Color(red: 0.2, green: 0.4, blue: 0.9)      // #3366E6
    static let primaryPurple = Color(red: 0.5, green: 0.2, blue: 0.9)    // #8033E6
    static let accentTeal = Color(red: 0.1, green: 0.7, blue: 0.8)       // #1AB3CC
    
    // Background colors
    static let appBackground = Color(.systemGroupedBackground)           // Light gray background
    static let cardBackground = Color.white
    static let surfaceBackground = Color(.secondarySystemGroupedBackground)
    
    // Gradient definitions
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [primaryBlue, primaryPurple]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let warningGradient = LinearGradient(
        gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Text colors
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    
    // Button colors  
    static let buttonPrimary = primaryGradient
    static let buttonSecondary = LinearGradient(
        gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray4)]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Action colors
    static let editButtonColor = accentTeal
    static let deleteButtonColor = Color.red
    static let successColor = Color.green
    
    // Shadow colors
    static let shadowLight = Color.black.opacity(0.05)
    static let shadowMedium = Color.black.opacity(0.1)
    static let shadowStrong = Color.black.opacity(0.15)
}