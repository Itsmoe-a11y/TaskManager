import SwiftUI

public struct MainTabView: View {
    @StateObject private var performanceVM = PerformanceViewModel()
    @StateObject private var processesVM = ProcessesViewModel()
    
    public init() {}
    
    public var body: some View {
        TabView {
            NavigationView {
                PerformanceView(viewModel: performanceVM)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Performance", systemImage: "chart.xyaxis.line")
            }
            
            NavigationView {
                ProcessesView(viewModel: processesVM)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Processes", systemImage: "list.bullet.rectangle.portrait")
            }
            
            NavigationView {
                SystemInfoView(performanceVM: performanceVM)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("System", systemImage: "cpu")
            }
            
            NavigationView {
                SettingsView(performanceVM: performanceVM)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .accentColor(Color(red: 0.0, green: 0.72, blue: 0.95)) // Windows Cyan accent
    }
}
