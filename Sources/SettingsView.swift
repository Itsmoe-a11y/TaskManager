import SwiftUI

public struct SettingsView: View {
    @ObservedObject var performanceVM: PerformanceViewModel
    @AppStorage("defaultToLogicalProcessors") private var defaultToLogicalProcessors: Bool = false
    
    public init(performanceVM: PerformanceViewModel) {
        self.performanceVM = performanceVM
    }
    
    public var body: some View {
        List {
            Section(header: Text("Performance Monitor")) {
                Picker("Update Speed", selection: $performanceVM.updateSpeed) {
                    ForEach(UpdateSpeed.allCases) { speed in
                        Text(speed.displayName).tag(speed)
                    }
                }
                
                Picker("Default CPU Mode", selection: $performanceVM.cpuViewMode) {
                    ForEach(CPUViewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
            }
            
            Section(header: Text("TrollStore & Privileges")) {
                entitlementRow(name: "platform-application", granted: true)
                entitlementRow(name: "com.apple.private.security.no-sandbox", granted: true)
                entitlementRow(name: "task_for_pid-allow", granted: true)
                entitlementRow(name: "proc_info-allow", granted: true)
                entitlementRow(name: "com.apple.system-task-ports", granted: true)
            }
            
            Section(header: Text("About Task Manager")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0 (Build 1)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Platform")
                    Spacer()
                    Text("iOS TrollStore / Unsandboxed")
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Windows Task Manager for iOS")
                        .font(.system(size: 14, weight: .bold))
                    Text("Engineered for low-overhead hardware telemetry, per-core CPU metrics, GPU utilization, network throughput, Wi-Fi link speed, and process termination.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func entitlementRow(name: String, granted: Bool) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.primary)
            Spacer()
            Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(granted ? .green : .red)
        }
    }
}
