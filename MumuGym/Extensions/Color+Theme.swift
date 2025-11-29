import SwiftUI
import Combine
import UIKit

extension Color {
    static let theme = ColorTheme()
    
    // ThemeManager integration
    static var themeManager: ThemeManager { ThemeManager.shared }
    
    // Dynamic background gradient that uses ThemeManager
    static var dynamicBackgroundGradient: LinearGradient {
        themeManager.currentBackgroundGradient
    }
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
    static let primaryRed = Color(red: 0.90, green: 0.20, blue: 0.20)
    static let primaryPurple1 = Color(red: 0.553, green: 0.224, blue: 0.839) // #8D39D6
    static let primaryPurple2 = Color(red: 0.694, green: 0.286, blue: 0.898) // #B149E5
    static let primaryWater1 = Color(red: 0.58, green: 0.84, blue: 0.70)  // #95D5B2
    static let primaryWater2 = Color(red: 0.32, green: 0.72, blue: 0.53) // #52B788
    static let accentTeal = Color(red: 0.1, green: 0.7, blue: 0.8)       // #1AB3CC
    
    
    // Background colors
    static let appBackground = Color(.systemGroupedBackground)           // Light gray background
    static let cardBackground = Color(.systemGroupedBackground)
    static let surfaceBackground = Color(.secondarySystemGroupedBackground)
    
    // Gradient definitions
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [primaryBlue1, primaryBlue2]),
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
    
    static let purpleGradient = LinearGradient(
        gradient: Gradient(colors: [primaryPurple1, primaryPurple2]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let waterGradient = LinearGradient(
        gradient: Gradient(colors: [primaryWater1, primaryWater2]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Text colors
    static let textWhiteStatic = Color(red: 1.0, green: 1.0, blue: 1.0) // #FFFFFF
    static let textBlackStatic = Color(red: 0.0, green: 0.0, blue: 0.0) // #000000
    static let textGrayStatic = Color(red: 0.60, green: 0.60, blue: 0.60) // #999999
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    
    // Button colors  
    static let buttonPrimary = primaryGradient
    static let buttonSuccess = successGradient
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

// MARK: - ThemeManager Definition
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var customBackgroundColor: Color = Color.primaryOrange1
    @Published var useDeviceAccentColor: Bool = false
    
    private let customColorKey = "CustomBackgroundColor"
    private let useDeviceAccentKey = "UseDeviceAccentColor"
    
    private init() {
        loadSettings()
    }
    
    func loadSettings() {
        // Load custom color
        if let colorData = UserDefaults.standard.data(forKey: customColorKey),
           let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            customBackgroundColor = Color(color)
        }
        
        // Load device accent color preference
        useDeviceAccentColor = UserDefaults.standard.bool(forKey: useDeviceAccentKey)
    }
    
    func saveCustomColor(_ color: Color) {
        customBackgroundColor = color
        let uiColor = UIColor(color)
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false) {
            UserDefaults.standard.set(colorData, forKey: customColorKey)
        }
    }
    
    func saveDeviceAccentPreference(_ useDeviceColor: Bool) {
        useDeviceAccentColor = useDeviceColor
        UserDefaults.standard.set(useDeviceColor, forKey: useDeviceAccentKey)
    }
    
    var currentBackgroundGradient: LinearGradient {
        if useDeviceAccentColor {
            return deviceAccentGradient
        } else {
            return customBackgroundGradient
        }
    }
    
    private var customBackgroundGradient: LinearGradient {
        let baseColor = customBackgroundColor
        
        // Usa i gradient predefiniti per i colori del tema
        switch baseColor {
        case Color.primaryOrange1:
            return Color.warningGradient
        case Color.primaryBlue1:
            return Color.primaryGradient
        case Color.primaryGreen1:
            return Color.successGradient
        case Color.primaryPurple1:
            return Color.purpleGradient
        case Color.primaryWater1:
            return Color.waterGradient
        default:
            // Per colori personalizzati, usa opacity
            let secondaryColor = customBackgroundColor.opacity(0.8)
            return LinearGradient(
                gradient: Gradient(colors: [baseColor, secondaryColor]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var deviceAccentGradient: LinearGradient {
        let accentColor = Color.accentColor
        let secondaryColor = accentColor.opacity(0.8)
        
        return LinearGradient(
            gradient: Gradient(colors: [accentColor, secondaryColor]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Funzione per rilevare il colore del dispositivo iOS (se disponibile)
    func getDeviceAccentColor() -> Color {
        if #available(iOS 14.0, *) {
            return Color.accentColor
        } else {
            return Color.blue
        }
    }
}
