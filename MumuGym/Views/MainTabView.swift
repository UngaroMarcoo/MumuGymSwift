import SwiftUI
import CoreData

struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            TemplatesView()
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Templates")
                }
            
            LiveWorkoutView()
                .tabItem {
                    Image(systemName: "play.circle.fill")
                    Text("Workout")
                }
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
            
            PersonalRecordsView()
                .tabItem {
                    Image(systemName: "trophy.fill")
                    Text("Records")
                }
        }
        .accentColor(Color.primaryOrange1)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager.shared)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
