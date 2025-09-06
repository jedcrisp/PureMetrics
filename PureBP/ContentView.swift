import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = BPDataManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SessionView(dataManager: dataManager)
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Session")
                }
                .tag(0)
            
            DailyReadingsView(dataManager: dataManager)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Daily")
                }
                .tag(1)
            
            TrendsView(dataManager: dataManager)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Trends")
                }
                .tag(2)
            
            ProfileView(dataManager: dataManager)
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
