import SwiftUI
import Darwin

public struct SystemInfoView: View {
    @ObservedObject var performanceVM: PerformanceViewModel
    
    public init(performanceVM: PerformanceViewModel) {
        self.performanceVM = performanceVM
    }
    
    public var body: some View {
        List {
            // Processor & SoC Section
            Section(header: Text("Processor & Architecture")) {
                infoRow(label: "Processor", value: performanceVM.cpuMetrics.cpuName)
                infoRow(label: "Architecture", value: performanceVM.cpuMetrics.architecture)
                infoRow(label: "Total Cores", value: "\(performanceVM.cpuMetrics.logicalCores) Cores")
                infoRow(label: "Performance Cores", value: "\(performanceVM.cpuMetrics.performanceCores) P-Cores")
                infoRow(label: "Efficiency Cores", value: "\(performanceVM.cpuMetrics.efficiencyCores) E-Cores")
                infoRow(label: "Total Physical RAM", value: String(format: "%.2f GB", performanceVM.memoryMetrics.totalGB))
                infoRow(label: "GPU Accelerator", value: performanceVM.gpuMetrics.gpuName)
            }
            
            // Operating System & Darwin Kernel
            Section(header: Text("Operating System")) {
                infoRow(label: "OS Version", value: "iOS \(UIDevice.current.systemVersion)")
                infoRow(label: "Darwin Kernel", value: getDarwinKernelVersion())
                infoRow(label: "Host Name", value: ProcessInfo.processInfo.hostName)
                infoRow(label: "System Uptime", value: performanceVM.cpuMetrics.uptimeFormatted)
                infoRow(label: "Active Processor Count", value: "\(ProcessInfo.processInfo.activeProcessorCount)")
            }
            
            // Thermal & Battery State
            Section(header: Text("Device Diagnostics")) {
                thermalRow
                batteryRow
                lowPowerModeRow
            }
            
            // Storage Summary
            Section(header: Text("Internal Storage")) {
                infoRow(label: "File System", value: "Apple APFS (Encrypted)")
                infoRow(label: "Total Capacity", value: String(format: "%.2f GB", performanceVM.storageMetrics.totalGB))
                infoRow(label: "Available Storage", value: String(format: "%.2f GB", performanceVM.storageMetrics.freeGB))
                infoRow(label: "Storage Used", value: String(format: "%.1f%%", performanceVM.storageMetrics.usedPercentage))
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("System Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var thermalRow: some View {
        HStack {
            Text("Thermal State")
            Spacer()
            let state = ProcessInfo.processInfo.thermalState
            HStack(spacing: 4) {
                Circle()
                    .fill(thermalColor(state))
                    .frame(width: 8, height: 8)
                Text(thermalDescription(state))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(thermalColor(state))
            }
        }
    }
    
    private var batteryRow: some View {
        HStack {
            Text("Battery Level")
            Spacer()
            UIDevice.current.isBatteryMonitoringEnabled = true
            let level = UIDevice.current.batteryLevel
            let pct = level >= 0 ? Int(level * 100) : 100
            Text("\(pct)%")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
        }
    }
    
    private var lowPowerModeRow: some View {
        HStack {
            Text("Low Power Mode")
            Spacer()
            let enabled = ProcessInfo.processInfo.isLowPowerModeEnabled
            Text(enabled ? "Enabled" : "Disabled")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(enabled ? .orange : .secondary)
        }
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
        }
    }
    
    private func getDarwinKernelVersion() -> String {
        var size = 0
        sysctlbyname("kern.osrelease", nil, &size, nil, 0)
        if size > 0 {
            var release = [CChar](repeating: 0, count: size)
            if sysctlbyname("kern.osrelease", &release, &size, nil, 0) == 0 {
                return "Darwin " + String(cString: release)
            }
        }
        return "Darwin Kernel"
    }
    
    private func thermalColor(_ state: ProcessInfo.ThermalState) -> Color {
        switch state {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .green
        }
    }
    
    private func thermalDescription(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Nominal (Cool)"
        case .fair: return "Fair (Moderate)"
        case .serious: return "Serious (Throttled)"
        case .critical: return "Critical (Overheating)"
        @unknown default: return "Nominal"
        }
    }
}
