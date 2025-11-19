import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegistration = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 50)
                    
                    VStack(spacing: 10) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("MumuGym")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Your personal fitness companion")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 30)
                    
                    VStack(spacing: 20) {
                        CustomTextField(title: "Email", text: $email, keyboardType: .emailAddress)
                        CustomSecureField(title: "Password", text: $password)
                        
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
                        }
                        .primaryButtonStyle(isDisabled: isLoading || email.isEmpty || password.isEmpty)
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.secondary)
                            
                            Button("Sign Up") {
                                showingRegistration = true
                            }
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                        }
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingRegistration) {
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
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField(title, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(.roundedBorder)
                .frame(height: 50)
                .background(Color(.systemGray6))
                .cornerRadius(12)
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
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                if isSecure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
                
                Button(action: { isSecure.toggle() }) {
                    Image(systemName: isSecure ? "eye" : "eye.slash")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 50)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager.shared)
}