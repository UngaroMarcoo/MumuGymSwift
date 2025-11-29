import SwiftUI
import UIKit
import Combine

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
        let secondaryColor = customBackgroundColor.opacity(0.8)
        
        return LinearGradient(
            gradient: Gradient(colors: [baseColor, secondaryColor]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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

extension Color {
    var gradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [self, self.opacity(0.8)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}