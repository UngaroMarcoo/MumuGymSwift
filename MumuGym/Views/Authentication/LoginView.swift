import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @ObservedObject private var themeManager = Color.themeManager
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegistration = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            themeManager.currentBackgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
            
                // App branding with clean design
                    VStack(spacing: 20) {
                        // Clean icon
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 3)
                        
                        VStack(spacing: 8) {
                            Text("MumuGym")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 2)
                            
                            Text("Your personal fitness companion")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.95))
                                .fontWeight(.medium)
                                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 30)
                    
                    // Login form
                    VStack(spacing: 24) {
                        VStack(spacing: 20) {
                            CustomTextField(title: "Email", text: $email, keyboardType: .emailAddress)
                            CustomSecureField(title: "Password", text: $password)
                        }
                        
                        Button(action: handleLogin) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Text("Login")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.warningGradient)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .opacity(isLoading || email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                        
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.textGrayStatic)
                            
                            Button("Sign Up") {
                                showingRegistration = true
                            }
                            .foregroundColor(.primaryBlue1)
                            .fontWeight(.semibold)
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cardBackground)
                            .shadow(color: Color.shadowMedium, radius: 8, x: 0, y: 2)
                    )
                    
                    Spacer()
            }
            .padding(.horizontal, 20)
        }
        .fullScreenCover(isPresented: $showingRegistration) {
            RegistrationView()
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func handleLogin() {
        isLoading = true
        HapticManager.shared.light()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let result = authManager.login(email: email, password: password)
            
            switch result {
            case .success(_):
                HapticManager.shared.success()
            case .failure(let error):
                HapticManager.shared.error()
                alertMessage = error.localizedDescription
                showingAlert = true
            }
            
            isLoading = false
        }
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            TextField(title, text: $text)
                .keyboardType(keyboardType)
                .padding(16)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.surfaceBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primaryOrange1.opacity(0.3), lineWidth: 1)
                        )
                )
                .autocapitalization(.none)
        }
    }
}

struct CustomSecureField: View {
    let title: String
    @Binding var text: String
    @State private var isSecure = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            HStack {
                if isSecure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
                
                Button(action: { isSecure.toggle() }) {
                    Image(systemName: isSecure ? "eye" : "eye.slash")
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.surfaceBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primaryOrange1.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager.shared)
}
