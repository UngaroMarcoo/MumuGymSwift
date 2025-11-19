import Foundation
import CoreData
import CryptoKit
import Combine

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private let persistenceController = PersistenceController.shared
    private let userDefaults = UserDefaults.standard
    
    init() {
        checkExistingSession()
    }
    
    func checkExistingSession() {
        if let userEmail = userDefaults.string(forKey: "currentUserEmail") {
            fetchUser(email: userEmail)
        }
    }
    
    func register(firstName: String, lastName: String, email: String, password: String, age: Int16, gender: String, emailSubscription: Bool) -> Result<User, AuthError> {
        
        guard !firstName.isEmpty, !lastName.isEmpty, !email.isEmpty, !password.isEmpty else {
            return .failure(.invalidInput)
        }
        
        guard email.contains("@") && email.contains(".") else {
            return .failure(.invalidEmail)
        }
        
        guard password.count >= 6 else {
            return .failure(.weakPassword)
        }
        
        if userExists(email: email) {
            return .failure(.userAlreadyExists)
        }
        
        let hashedPassword = hashPassword(password)
        let context = persistenceController.context
        
        let user = User(context: context)
        user.firstName = firstName
        user.lastName = lastName
        user.email = email
        user.passwordHash = hashedPassword
        user.age = age
        user.gender = gender
        user.emailSubscription = emailSubscription
        user.isActive = true
        
        persistenceController.save()
        
        setCurrentUser(user)
        return .success(user)
    }
    
    func login(email: String, password: String) -> Result<User, AuthError> {
        guard !email.isEmpty, !password.isEmpty else {
            return .failure(.invalidInput)
        }
        
        let hashedPassword = hashPassword(password)
        
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@ AND passwordHash == %@", email, hashedPassword)
        
        do {
            let users = try persistenceController.context.fetch(request)
            if let user = users.first {
                setCurrentUser(user)
                return .success(user)
            } else {
                return .failure(.invalidCredentials)
            }
        } catch {
            return .failure(.dataError)
        }
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
        userDefaults.removeObject(forKey: "currentUserEmail")
    }
    
    private func setCurrentUser(_ user: User) {
        currentUser = user
        isAuthenticated = true
        userDefaults.set(user.email, forKey: "currentUserEmail")
    }
    
    private func fetchUser(email: String) {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email)
        
        do {
            let users = try persistenceController.context.fetch(request)
            if let user = users.first {
                currentUser = user
                isAuthenticated = true
            }
        } catch {
            print("Failed to fetch user: \(error)")
        }
    }
    
    private func userExists(email: String) -> Bool {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email)
        
        do {
            let count = try persistenceController.context.count(for: request)
            return count > 0
        } catch {
            return false
        }
    }
    
    private func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

enum AuthError: Error, LocalizedError {
    case invalidInput
    case invalidEmail
    case weakPassword
    case userAlreadyExists
    case invalidCredentials
    case dataError
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Please fill in all required fields"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 6 characters long"
        case .userAlreadyExists:
            return "An account with this email already exists"
        case .invalidCredentials:
            return "Invalid email or password"
        case .dataError:
            return "A data error occurred. Please try again."
        }
    }
}