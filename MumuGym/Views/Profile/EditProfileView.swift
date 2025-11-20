import SwiftUI
import CoreData

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var age: String = ""
    @State private var gender: String = ""
    @State private var emailSubscription: Bool = false
    @State private var currentWeight: String = ""
    @State private var targetWeight: String = ""
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let genderOptions = ["Male", "Female", "Other", "Prefer not to say"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    personalDataSection
                    weightSection
                    emailPreferencesSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.appBackground)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                    .fontWeight(.medium)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .foregroundColor(.primaryPurple1)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadCurrentData()
        }
        .alert("Profile Update", isPresented: $showingAlert) {
            Button("OK") { 
                if alertMessage.contains("successfully") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.cardBackground)
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.primaryPurple1)
            }
            
            Text("Edit Your Profile")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 10, x: 0, y: 5)
        )
    }
    
    private var personalDataSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(Color.primaryPurple1)
                    .font(.title2)
                
                Text("Personal Information")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("First Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                        
                        TextField("Enter first name", text: $firstName)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                        
                        TextField("Enter last name", text: $lastName)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                        
                        TextField("Age", text: $age)
                            .keyboardType(.numberPad)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gender")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                        
                        Menu {
                            ForEach(genderOptions, id: \.self) { option in
                                Button(option) {
                                    gender = option
                                }
                            }
                        } label: {
                            HStack {
                                Text(gender.isEmpty ? "Select gender" : gender)
                                    .foregroundColor(gender.isEmpty ? .textSecondary : .textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.textSecondary)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.surfaceBackground)
                                    .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
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
    
    private var weightSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "scalemass.fill")
                    .foregroundColor(Color.accentTeal)
                    .font(.title2)
                
                Text("Weight Information")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Weight (kg)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)
                    
                    TextField("0.0", text: $currentWeight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Weight (kg)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)
                    
                    TextField("0.0", text: $targetWeight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(CustomTextFieldStyle())
                }
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
    
    private var emailPreferencesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(Color.primaryPurple2)
                    .font(.title2)
                
                Text("Email Preferences")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            Toggle(isOn: $emailSubscription) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Email Notifications")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    Text("Receive updates and workout reminders")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .tint(Color.primaryPurple1)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.surfaceBackground)
            )
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowMedium, radius: 10, x: 0, y: 5)
        )
    }
    
    private func loadCurrentData() {
        guard let user = authManager.currentUser else { return }
        
        firstName = user.firstName ?? ""
        lastName = user.lastName ?? ""
        age = user.age > 0 ? String(user.age) : ""
        gender = user.gender ?? ""
        emailSubscription = user.emailSubscription
        currentWeight = user.currentWeight > 0 ? String(format: "%.1f", user.currentWeight) : ""
        targetWeight = user.targetWeight > 0 ? String(format: "%.1f", user.targetWeight) : ""
    }
    
    private func saveProfile() {
        guard let user = authManager.currentUser else {
            alertMessage = "User not found"
            showingAlert = true
            return
        }
        
        // Validate required fields
        if firstName.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "First name is required"
            showingAlert = true
            return
        }
        
        if lastName.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Last name is required"
            showingAlert = true
            return
        }
        
        if !age.isEmpty {
            guard let ageValue = Int(age), ageValue >= 13 && ageValue <= 120 else {
                alertMessage = "Please enter a valid age between 13 and 120"
                showingAlert = true
                return
            }
            user.age = Int16(ageValue)
        }
        
        // Validate weight values
        if !currentWeight.isEmpty {
            guard let weightValue = Double(currentWeight), weightValue >= 30 && weightValue <= 300 else {
                alertMessage = "Please enter a valid current weight between 30 and 300 kg"
                showingAlert = true
                return
            }
            user.currentWeight = weightValue
        }
        
        if !targetWeight.isEmpty {
            guard let weightValue = Double(targetWeight), weightValue >= 30 && weightValue <= 300 else {
                alertMessage = "Please enter a valid target weight between 30 and 300 kg"
                showingAlert = true
                return
            }
            user.targetWeight = weightValue
        }
        
        // Update user data
        user.firstName = firstName.trimmingCharacters(in: .whitespaces)
        user.lastName = lastName.trimmingCharacters(in: .whitespaces)
        user.gender = gender
        user.emailSubscription = emailSubscription
        
        // Save to Core Data
        do {
            try viewContext.save()
            alertMessage = "Profile updated successfully"
            showingAlert = true
        } catch {
            alertMessage = "Failed to save profile: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.surfaceBackground)
                    .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
            )
            .font(.subheadline)
    }
}

#Preview {
    EditProfileView()
        .environmentObject(AuthenticationManager.shared)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}