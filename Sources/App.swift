import SwiftUI

@main
struct TaskManagerApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark) // Windows 11 Task Manager Dark Aesthetic
        }
    }
}
