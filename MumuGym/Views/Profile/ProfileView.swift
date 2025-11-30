import SwiftUI
import CoreData

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var networkManager = NetworkManager.shared
    
    @State private var showingWeightEntry = false
    @State private var showingEditProfile = false
    @State private var showingLogoutConfirmation = false
    @State private var showingWeightAnalytics = false
    @State private var showingBackgroundColorPicker = false
    @State private var refreshID = UUID()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    profileHeaderSection
                    personalInfoSection
                    weightInfoSection
                    appSettingsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                .id(refreshID) // This forces the view to refresh when refreshID changes
            }
            .background(Color.surfaceBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingWeightEntry) {
            WeightEntryView(currentWeight: .constant(""), targetWeight: .constant(""))
        }
        .sheet(isPresented: $showingWeightAnalytics) {
            WeightAnalyticsView()
        }
        .sheet(isPresented: $showingEditProfile, onDismiss: {
            // Refresh the view when the edit profile sheet is dismissed
            refreshID = UUID()
        }) {
            EditProfileView()
        }
        .sheet(isPresented: $showingBackgroundColorPicker) {
            BackgroundColorPickerView()
        }
        .alert("Logout Confirmation", isPresented: $showingLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
    
    private var profileHeaderSection: some View {
        VStack(spacing: 20) {
            // Profile title
            
            HStack {
                Text("Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                Button("Edit") {
                    showingEditProfile = true
                }
                .foregroundColor(.primaryRed)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cardBackground)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            
            // Avatar and basic info
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.cardBackground)
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                    
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(themeManager.customBackgroundColor)
                }
                .padding(.top, 19)
                
                VStack(spacing: 8) {
                    Text("\(authManager.currentUser?.firstName ?? "Unknown") \(authManager.currentUser?.lastName ?? "User")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text(authManager.currentUser?.email ?? "")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.shadowMedium, radius: 10, x: 0, y: 5)
            )
            
        }
        
    }
    
    private var personalInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(Color.accentTeal)
                    .font(.title2)
                
                Text("Personal Information")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                profileInfoRow(label: "Age", value: "\(authManager.currentUser?.age ?? 0) years old")
                profileInfoRow(label: "Gender", value: authManager.currentUser?.gender ?? "Not specified")
                profileInfoRow(label: "Email Notifications", value: (authManager.currentUser?.emailSubscription ?? false) ? "Enabled" : "Disabled")
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 10, x: 0, y: 5)
        )
    }
    
    private var weightInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(Color.primaryPurple1)
                    .font(.title2)
                
                Text("Weight Analytics")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            Button(action: { showingWeightAnalytics = true }) {
                HStack {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    Text("View Weight Analytics")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.primaryPurple1, Color.primaryPurple2]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .shadow(color: Color.primaryPurple1.opacity(0.3), radius: 6, x: 0, y: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 10, x: 0, y: 5)
        )
    }
    
    private var appSettingsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "gear.circle.fill")
                    .foregroundColor(Color.primaryOrange1)
                    .font(.title2)
                
                Text("App Settings")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Network Status Indicator
                HStack {
                    Image(systemName: networkManager.isConnected ? "wifi" : "wifi.slash")
                        .font(.title3)
                        .foregroundColor(networkManager.isConnected ? .green : .red)
                    
                    Text("Connection Status")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(networkManager.isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(networkManager.isConnected ? "Online" : "Offline")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(networkManager.isConnected ? .green : .red)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.surfaceBackground)
                )
                
                // Background Color Settings Button
                Button(action: { showingBackgroundColorPicker = true }) {
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .font(.title3)
                            .foregroundColor(.primaryBlue1)
                        
                        Text("Background Color")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        Circle()
                            .fill(themeManager.customBackgroundColor.gradient)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.surfaceBackground)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Logout Button
                Button(action: { showingLogoutConfirmation = true }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.title3)
                            .foregroundColor(.primaryRed)
                        
                        Text("Logout")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.primaryRed)
                        
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.surfaceBackground)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 10, x: 0, y: 5)
        )
    }
    
    private func profileInfoRow(label: String, value: String) -> some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundColor(Color.accentTeal)
                
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentTeal.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.accentTeal.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surfaceBackground.opacity(0.5))
        )
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager.shared)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
