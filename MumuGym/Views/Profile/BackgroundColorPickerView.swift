import SwiftUI

struct BackgroundColorPickerView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedColor: Color = Color.primaryOrange1
    
    // Struct per associare colore e gradient
    struct ColorOption {
        let color: Color
        let gradient: LinearGradient
    }
    
    let predefinedColorOptions: [ColorOption] = [
        ColorOption(color: Color.primaryOrange1, gradient: Color.warningGradient),
        ColorOption(color: Color.primaryBlue1, gradient: Color.primaryGradient),
        ColorOption(color: Color.primaryGreen1, gradient: Color.successGradient),
        ColorOption(color: Color.primaryPurple1, gradient: Color.purpleGradient),
        ColorOption(color: Color.primaryWater1, gradient: Color.waterGradient),
        ColorOption(color: Color.primaryRed, gradient: LinearGradient(gradient: Gradient(colors: [Color.primaryRed, Color.primaryRed.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)),
        ColorOption(color: Color.accentTeal, gradient: LinearGradient(gradient: Gradient(colors: [Color.accentTeal, Color.accentTeal.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)),
        ColorOption(color: Color.pink, gradient: LinearGradient(gradient: Gradient(colors: [Color.pink, Color.pink.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)),
        ColorOption(color: Color.indigo, gradient: LinearGradient(gradient: Gradient(colors: [Color.indigo, Color.indigo.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)),
        ColorOption(color: Color.mint, gradient: LinearGradient(gradient: Gradient(colors: [Color.mint, Color.mint.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Preview section
                    previewSection
                    
                    // Device accent color option
                    deviceAccentSection
                    
                    // Custom color picker
                    if !themeManager.useDeviceAccentColor {
                        customColorSection
                    }
                }
                .padding()
            }
            .background(themeManager.currentBackgroundGradient.ignoresSafeArea())
            .navigationTitle("Background Color")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    if !themeManager.useDeviceAccentColor {
                        themeManager.saveCustomColor(selectedColor)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                .fontWeight(.semibold)
            )
        }
        .onAppear {
            selectedColor = themeManager.customBackgroundColor
        }
    }
    
    private var previewSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                
                Text("Preview")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 35))
                                .foregroundColor(.primaryOrange1)
                        )
                    
                    VStack(alignment: .leading) {
                        Text("Profile Preview")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("This is how your background will look")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var deviceAccentSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "iphone")
                    .foregroundColor(.white)
                    .font(.title2)
                
                Text("Device Settings")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Use Device Accent Color")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Automatically matches your device's accent color")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $themeManager.useDeviceAccentColor)
                        .toggleStyle(SwitchToggleStyle())
                        .onChange(of: themeManager.useDeviceAccentColor) { _, newValue in
                            themeManager.saveDeviceAccentPreference(newValue)
                        }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var customColorSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "paintpalette.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                
                Text("Custom Colors")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 20) {
                // Predefined colors with their gradients
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                    ForEach(0..<predefinedColorOptions.count, id: \.self) { index in
                        let colorOption = predefinedColorOptions[index]
                        Button(action: {
                            selectedColor = colorOption.color
                            themeManager.saveCustomColor(colorOption.color)
                        }) {
                            Circle()
                                .fill(colorOption.gradient)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedColor == colorOption.color ? 3 : 1)
                                )
                                .scaleEffect(selectedColor == colorOption.color ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Native color picker
                ColorPicker("Choose Custom Color", selection: $selectedColor, supportsOpacity: false)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .onChange(of: selectedColor) { _, newColor in
                        themeManager.saveCustomColor(newColor)
                    }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    BackgroundColorPickerView()
}