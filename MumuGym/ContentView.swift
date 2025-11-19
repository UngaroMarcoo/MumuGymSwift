//
//  ContentView.swift
//  MumuGym
//
//  Created by Gianluca Ungaro on 19/11/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                Group {
                    if authManager.isAuthenticated {
                        MainTabView()
                    } else {
                        LoginView()
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager.shared)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
