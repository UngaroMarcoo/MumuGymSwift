import SwiftUI

struct RegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var age = ""
    @State private var gender = "Male"
    @State private var emailSubscription = true
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    private let genders = ["Male", "Female", "Other", "Prefer not to say"]
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.primaryBlue1, Color.primaryBlue2]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        headerSection
                        personalInfoSection
                        accountInfoSection
                        preferencesSection
                        registerButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .foregroundColor(.white)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.white)
                .shadow(color: Color.white.opacity(0.3), radius: 4, x: 0, y: 2)
            
            Text("Join MumuGym")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Start your fitness journey today")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 25)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private var personalInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(Color.primaryBlue1)
                    .font(.title2)
                
                Text("Personal Information")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 15) {
                HStack(spacing: 15) {
                    CustomTextField(title: "First Name", text: $firstName)
                    CustomTextField(title: "Last Name", text: $lastName)
                }
                
                CustomTextField(title: "Age", text: $age, keyboardType: .numberPad)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gender")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(genders, id: \.self) { gender in
                            Text(gender).tag(gender)
                        }
                    }
                    .pickerStyle(.segmented)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
    
    private var accountInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(Color.primaryBlue2)
                    .font(.title2)
                
                Text("Account Information")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 15) {
                CustomTextField(title: "Email", text: $email, keyboardType: .emailAddress)
                CustomSecureField(title: "Password", text: $password)
                
                VStack(alignment: .leading, spacing: 8) {
                    CustomSecureField(title: "Confirm Password", text: $confirmPassword)
                    
                    if !confirmPassword.isEmpty && password != confirmPassword {
                        Text("Passwords don't match")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.leading, 4)
                    }
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
    
    private var preferencesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "gear.circle.fill")
                    .foregroundColor(Color.primaryBlue1)
                    .font(.title2)
                
                Text("Preferences")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Toggle(isOn: $emailSubscription) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Email notifications")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Receive workout tips and updates")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: Color.primaryBlue1))
            .padding(16)
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
    
    private var registerButton: some View {
        Button(action: handleRegistration) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Text("Create Account")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.buttonPrimary)
            .foregroundColor(.white)
            .cornerRadius(25)
            .shadow(color: Color.primaryBlue1.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isLoading || !isFormValid)
        .opacity(isLoading || !isFormValid ? 0.6 : 1.0)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !age.isEmpty &&
        password == confirmPassword &&
        password.count >= 6 &&
        Int(age) != nil &&
        Int(age)! > 0
    }
    
    private func handleRegistration() {
        guard let ageInt = Int(age) else {
            alertMessage = "Please enter a valid age"
            showingAlert = true
            return
        }
        
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let result = authManager.register(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password,
                age: Int16(ageInt),
                gender: gender,
                emailSubscription: emailSubscription
            )
            
            switch result {
            case .success(_):
                dismiss()
            case .failure(let error):
                alertMessage = error.localizedDescription
                showingAlert = true
            }
            
            isLoading = false
        }
    }
}

#Preview {
    RegistrationView()
        .environmentObject(AuthenticationManager.shared)
}
