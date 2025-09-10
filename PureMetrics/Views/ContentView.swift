import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = BPDataManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SessionView(dataManager: dataManager)
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Health")
                }
                .tag(0)
            
            FitnessView(dataManager: dataManager)
                .tabItem {
                    Image(systemName: "dumbbell.fill")
                    Text("Fitness")
                }
                .tag(1)
            
            NutritionView(dataManager: dataManager)
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("Nutrition")
                }
                .tag(2)
            
            TrendsView(dataManager: dataManager)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Trends")
                }
                .tag(3)
            
            WorkoutHistoryView()
                .environmentObject(dataManager)
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("History")
                }
                .tag(4)
            
            CustomWorkoutsLibrary()
                .environmentObject(dataManager)
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Library")
                }
                .tag(5)
            
            ProfileView(dataManager: dataManager)
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(6)
        }
        .accentColor(.blue)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
