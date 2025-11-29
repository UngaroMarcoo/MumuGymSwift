//
//  MumuGymApp.swift
//  MumuGym
//
//  Created by Gianluca Ungaro on 19/11/25.
//

import SwiftUI
import CoreData

@main
struct MumuGymApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.context)
                .environmentObject(AuthenticationManager.shared)
        }
    }
}
