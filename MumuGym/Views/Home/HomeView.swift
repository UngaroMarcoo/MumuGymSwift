import SwiftUI
import CoreData

struct HomeView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var currentWeight = ""
    @State private var targetWeight = ""
    @State private var showingWeightEntry = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    headerSection
                    weightSection
                    quickStatsSection
                    quickActionsSection
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationTitle("Welcome Back")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Logout") {
                        authManager.logout()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            loadUserWeights()
        }
        .sheet(isPresented: $showingWeightEntry) {
            WeightEntryView(currentWeight: $currentWeight, targetWeight: $targetWeight)
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello, \(authManager.currentUser?.firstName ?? "User")!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Ready for today's workout?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { showingWeightEntry = true }) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var weightSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Weight Tracking")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Update") {
                    showingWeightEntry = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            HStack(spacing: 20) {
                weightCard(
                    title: "Current Weight",
                    value: currentWeight.isEmpty ? "--" : "\(currentWeight) kg",
                    color: .blue
                )
                
                weightCard(
                    title: "Target Weight",
                    value: targetWeight.isEmpty ? "--" : "\(targetWeight) kg",
                    color: .green
                )
            }
            
            if !currentWeight.isEmpty && !targetWeight.isEmpty,
               let current = Double(currentWeight),
               let target = Double(targetWeight) {
                weightProgressView(current: current, target: target)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func weightCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private func weightProgressView(current: Double, target: Double) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Progress to Goal")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(abs(current - target), default: "%.1f") kg to go")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: min(current, target), total: max(current, target))
                .progressViewStyle(LinearProgressViewStyle(tint: current >= target ? .green : .orange))
        }
        .padding(.top, 8)
    }
    
    private var quickStatsSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("This Week")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack(spacing: 15) {
                statCard(title: "Workouts", value: "3", icon: "dumbbell")
                statCard(title: "Duration", value: "4.5h", icon: "clock")
                statCard(title: "Calories", value: "1,250", icon: "flame")
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                NavigationLink(destination: TemplatesView()) {
                    actionButton(title: "Start Quick Workout", icon: "play.fill", color: .green)
                }
                
                NavigationLink(destination: TemplatesView()) {
                    actionButton(title: "Create New Template", icon: "plus.circle.fill", color: .blue)
                }
                
                NavigationLink(destination: PersonalRecordsView()) {
                    actionButton(title: "Log Personal Record", icon: "trophy.fill", color: .orange)
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func actionButton(title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(title)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private func loadUserWeights() {
        guard let user = authManager.currentUser else { return }
        
        if user.currentWeight > 0 {
            currentWeight = String(format: "%.1f", user.currentWeight)
        }
        
        if user.targetWeight > 0 {
            targetWeight = String(format: "%.1f", user.targetWeight)
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
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    Text("Update Your Weights")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 16) {
                        CustomTextField(title: "Current Weight (kg)", text: $tempCurrentWeight, keyboardType: .decimalPad)
                        CustomTextField(title: "Target Weight (kg)", text: $tempTargetWeight, keyboardType: .decimalPad)
                    }
                }
                
                Button("Save") {
                    saveWeights()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(tempCurrentWeight.isEmpty && tempTargetWeight.isEmpty)
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Weight Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
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
    HomeView()
        .environmentObject(AuthenticationManager.shared)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}