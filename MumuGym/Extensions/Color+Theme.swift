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
    static let primaryBlue = Color(red: 0.2, green: 0.4, blue: 0.9)
    static let lightGray = Color(.systemGray6)
    static let cardBackground = Color.white
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
}