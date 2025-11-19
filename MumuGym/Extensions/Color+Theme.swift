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
    static let primaryBlue1 = Color(red: 0.30, green: 0.60, blue: 0.98) // #4C99FA
    static let primaryBlue2 = Color(red: 0.20, green: 0.45, blue: 0.90) // #3372E6
    static let primaryOrange1 = Color(red: 0.98, green: 0.35, blue: 0.10) // #FA5A1A
    static let primaryOrange2 = Color(red: 0.95, green: 0.55, blue: 0.10) // #F28C1A
    static let primaryGreen1 = Color(red: 0.10, green: 0.70, blue: 0.30) // #19B34D
    static let primaryGreen2 = Color(red: 0.15, green: 0.85, blue: 0.40) // #26D966
    static let accentTeal = Color(red: 0.1, green: 0.7, blue: 0.8)       // #1AB3CC
    
    // Background colors
    static let appBackground = Color(.systemGroupedBackground)           // Light gray background
    static let cardBackground = Color.white
    static let surfaceBackground = Color(.secondarySystemGroupedBackground)
    
    // Gradient definitions
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [primaryOrange1, primaryOrange2]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        gradient: Gradient(colors: [primaryGreen1, primaryGreen2]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warningGradient = LinearGradient(
        gradient: Gradient(colors: [primaryOrange1, primaryOrange2]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
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
    
    // Action color gradients
    static let editButtonGradient = LinearGradient(
        gradient: Gradient(colors: [accentTeal, accentTeal.opacity(0.8)]),
        startPoint: .leading,
        endPoint: .trailing
    )
    static let deleteButtonGradient = LinearGradient(
        gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
        startPoint: .leading,
        endPoint: .trailing
    )
    static let successGradientButton = LinearGradient(
        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Solid colors for specific cases
    static let editButtonColor = accentTeal
    static let deleteButtonColor = Color.red
    static let successColor = Color.green
    
    // Shadow colors
    static let shadowLight = Color.black.opacity(0.05)
    static let shadowMedium = Color.black.opacity(0.1)
    static let shadowStrong = Color.black.opacity(0.15)
}
