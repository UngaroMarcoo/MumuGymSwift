import SwiftUI
import CoreData

struct HomeView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedTab: Int
    
    @State private var currentWeight = ""
    @State private var showingWeightEntry = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome section with logout button
                    HStack {
                        Text("Welcome Back")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color.cardBackground)
                        
                        Spacer()
                        
                        Button("Logout") {
                            authManager.logout()
                        }
                        .foregroundColor(Color.red)
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
                    
                    headerSection
                    weightSection
                    quickStatsSection
                    quickActionsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .background(Color.warningGradient)
            .navigationBarHidden(true)
        }
        .onAppear {
            loadUserWeights()
        }
        .sheet(isPresented: $showingWeightEntry) {
            WeightEntryView(currentWeight: $currentWeight, targetWeight: .constant(""))
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Gradient header bar
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hello, \(authManager.currentUser?.firstName ?? "User")!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        Text("Ready for today's workout?")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { selectedTab = 5 }) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 34))
                            .foregroundColor(.primaryOrange1)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 4)
            )
        }
    }
    
    private var weightSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "scalemass.fill")
                    .foregroundColor(Color.primaryOrange1)
                    .font(.title3)
                
                Text("Current Weight")
                    .font(.headline)
                    .fontWeight(.semibold)
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
            
            VStack(spacing: 8) {
                Text(currentWeight.isEmpty ? "--" : "\(currentWeight) kg")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.primaryOrange1)
                
                Text("Current Weight")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.surfaceBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primaryOrange1.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
        )
    }
    
    
    private var quickStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(Color.accentTeal)
                    .font(.title3)
                
                Text("This Week")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                statCard(title: "Workouts", value: "3", icon: "dumbbell")
                statCard(title: "Duration", value: "4.5h", icon: "clock")
                statCard(title: "Calories", value: "1,250", icon: "flame")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
        )
    }
    
    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color.accentTeal)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surfaceBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentTeal.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(Color.primaryOrange2)
                    .font(.title3)
                
                Text("Quick Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 10) {
                Button(action: { selectedTab = 2 }) {
                    actionButton(title: "Start Quick Workout", icon: "play.fill", gradient: Color.successGradient)
                }
                
                Button(action: { selectedTab = 1 }) {
                    actionButton(title: "Browse Templates", icon: "doc.text.fill", gradient: Color.primaryGradient)
                }
                
                Button(action: { selectedTab = 4 }) {
                    actionButton(title: "Log Personal Record", icon: "trophy.fill", gradient: Color.warningGradient)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
        )
    }
    
    private func actionButton(title: String, icon: String, gradient: LinearGradient) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
            
            Text(title)
                .fontWeight(.semibold)
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
                .fill(gradient)
                .shadow(color: Color.shadowMedium, radius: 6, x: 0, y: 2)
        )
    }
    
    private func loadUserWeights() {
        guard let user = authManager.currentUser else { return }
        
        if user.currentWeight > 0 {
            currentWeight = String(format: "%.1f", user.currentWeight)
        }
    }
}

struct WeightEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var currentWeight: String
    @Binding var targetWeight: String
    
    @State private var tempCurrentWeight = ""
    @State private var tempTargetWeight = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with gradient
                    VStack(spacing: 12) {
                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        
                        Text("Update Your Weights")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.primaryGradient)
                            .shadow(color: Color.primaryOrange1.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                    
                    // Weight entry form
                    VStack(spacing: 20) {
                        weightEntryField(title: "Current Weight (kg)", text: $tempCurrentWeight)
                        weightEntryField(title: "Target Weight (kg)", text: $tempTargetWeight)
                        
                        Button("Save Changes") {
                            saveWeights()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.successGradient)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                        .disabled(tempCurrentWeight.isEmpty && tempTargetWeight.isEmpty)
                        .opacity(tempCurrentWeight.isEmpty && tempTargetWeight.isEmpty ? 0.6 : 1.0)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cardBackground)
                            .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
                    )
                }
                .padding(16)
            }
            .background(Color.appBackground)
            .navigationTitle("Weight Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primaryBlue1)
                    .fontWeight(.medium)
                }
            }
        }
    }
    
    private func weightEntryField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            TextField("Enter weight", text: text)
                .keyboardType(.decimalPad)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.surfaceBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primaryOrange1.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .onAppear {
            tempCurrentWeight = currentWeight
            tempTargetWeight = targetWeight
        }
    }
    
    private func saveWeights() {
        guard let user = authManager.currentUser else { return }
        
        if !tempCurrentWeight.isEmpty, let weight = Double(tempCurrentWeight) {
            user.currentWeight = weight
            currentWeight = tempCurrentWeight
        }
        
        if !tempTargetWeight.isEmpty, let weight = Double(tempTargetWeight) {
            user.targetWeight = weight
            targetWeight = tempTargetWeight
        }
        
        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    HomeView(selectedTab: .constant(0))
        .environmentObject(AuthenticationManager.shared)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
