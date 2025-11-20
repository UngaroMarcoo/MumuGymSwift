import SwiftUI
import CoreData

struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            TemplatesView()
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Templates")
                }
                .tag(1)
            
            LiveWorkoutView()
                .tabItem {
                    Image(systemName: "play.circle.fill")
                    Text("Workout")
                }
                .tag(2)
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
                .tag(3)
            
            PersonalRecordsView()
                .tabItem {
                    Image(systemName: "trophy.fill")
                    Text("Records")
                }
                .tag(4)
            
        }
        .accentColor(Color.black)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager.shared)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
