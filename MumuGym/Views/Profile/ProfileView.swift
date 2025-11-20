import SwiftUI
import CoreData

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingWeightEntry = false
    @State private var showingEditProfile = false
    @State private var showingLogoutConfirmation = false
    
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
            }
            .background(Color.warningGradient)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingWeightEntry) {
            WeightEntryView(currentWeight: .constant(""), targetWeight: .constant(""))
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
                    .foregroundColor(Color.cardBackground)
                
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
                        .foregroundColor(.primaryOrange1)
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
                    .foregroundColor(Color.primaryOrange1)
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
                Image(systemName: "scalemass.fill")
                    .foregroundColor(Color.primaryOrange1)
                    .font(.title2)
                
                Text("Weight Information")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button("Update") {
                    showingWeightEntry = true
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primaryOrange1)
                )
            }
            
            VStack(spacing: 12) {
                profileInfoRow(label: "Current Weight", value: authManager.currentUser?.currentWeight ?? 0 > 0 ? "\(String(format: "%.1f", authManager.currentUser?.currentWeight ?? 0)) kg" : "Not set")
                profileInfoRow(label: "Target Weight", value: authManager.currentUser?.targetWeight ?? 0 > 0 ? "\(String(format: "%.1f", authManager.currentUser?.targetWeight ?? 0)) kg" : "Not set")
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
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surfaceBackground)
        )
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager.shared)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
