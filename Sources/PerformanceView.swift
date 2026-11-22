import SwiftUI

public struct PerformanceView: View {
    @ObservedObject var viewModel: PerformanceViewModel
    
    public init(viewModel: PerformanceViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 14) {
                // Top Master Cards Carousel
                masterCardsCarousel
                
                // Detailed View for Selected Metric
                detailedViewForSelected
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Performance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Update Speed", selection: $viewModel.updateSpeed) {
                        ForEach(UpdateSpeed.allCases) { speed in
                            Text(speed.displayName).tag(speed)
                        }
                    }
                } label: {
                    Image(systemName: "timer")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
    }
    
    // MARK: - Master Cards Carousel
    private var masterCardsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // CPU Card
                cardView(
                    category: .cpu,
                    title: "CPU",
                    subtitle: String(format: "%.0f%%", viewModel.cpuMetrics.overallLoad),
                    detail: viewModel.cpuMetrics.cpuName.replacingOccurrences(of: "Apple ", with: ""),
                    history: viewModel.cpuOverallHistory.values,
                    unit: "%"
                )
                
                // Memory Card
                cardView(
                    category: .memory,
                    title: "Memory",
                    subtitle: String(format: "%.1f GB (%.0f%%)", viewModel.memoryMetrics.usedGB, viewModel.memoryMetrics.usedPercentage),
                    detail: String(format: "%.1f GB Total", viewModel.memoryMetrics.totalGB),
                    history: viewModel.memoryHistory.values,
                    unit: "%"
                )
                
                // Disk Card
                cardView(
                    category: .disk,
                    title: "Disk (APFS)",
                    subtitle: String(format: "%.1f MB/s", viewModel.storageMetrics.totalSpeedMBs),
                    detail: String(format: "%.0f%% Active", viewModel.storageMetrics.activeTimePercentage),
                    history: viewModel.diskReadHistory.values,
                    unit: "MB/s"
                )
                
                // Wi-Fi Card
                let wifiLink = viewModel.wifiMetrics?.linkSpeedMbps ?? 866.0
                cardView(
                    category: .wifi,
                    title: "Wi-Fi",
                    subtitle: String(format: "%.0f Mbps", wifiLink),
                    detail: viewModel.wifiMetrics?.ssid ?? "Connected",
                    history: viewModel.networkDownHistory.values,
                    unit: "MB/s"
                )
                
                // GPU Card
                let gpuVal = viewModel.gpuMetrics.rendererUtilization > 0 ? viewModel.gpuMetrics.rendererUtilization : viewModel.gpuMetrics.deviceUtilization
                cardView(
                    category: .gpu,
                    title: "GPU",
                    subtitle: String(format: "%.0f%%", gpuVal),
                    detail: viewModel.gpuMetrics.gpuName,
                    history: viewModel.gpuHistory.values,
                    unit: "%"
                )
            }
            .padding(.vertical, 2)
        }
    }
    
    private func cardView(
        category: MetricCategory,
        title: String,
        subtitle: String,
        detail: String,
        history: [Double],
        unit: String
    ) -> some View {
        let isSelected = viewModel.selectedCategory == category
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedCategory = category
            }
        }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: category.iconName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(category.accentColor)
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                Text(subtitle)
                    .font(.system(size: 15, weight: .heavy, design: .monospaced))
                    .foregroundColor(isSelected ? category.accentColor : .primary)
                
                Text(detail)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                SparklineView(
                    values: history,
                    maxValue: category == .disk || category == .wifi ? 20.0 : 100.0,
                    accentColor: category.accentColor
                )
                .frame(width: 120, height: 28)
                .padding(.top, 2)
            }
            .padding(10)
            .frame(width: 140)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? category.accentColor : Color.primary.opacity(0.06), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Detailed View Switcher
    @ViewBuilder
    private var detailedViewForSelected: some View {
        switch viewModel.selectedCategory {
        case .cpu:
            cpuDetailSection
        case .memory:
            memoryDetailSection
        case .disk:
            diskDetailSection
        case .wifi:
            wifiDetailSection
        case .cellular:
            cellularDetailSection
        case .gpu:
            gpuDetailSection
        }
    }
    
    // MARK: - CPU Detail Section
    private var cpuDetailSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel.cpuMetrics.cpuName)
                        .font(.system(size: 18, weight: .bold))
                    Text(String(format: "%.0f%% Utilization • %@ Uptime", viewModel.cpuMetrics.overallLoad, viewModel.cpuMetrics.uptimeFormatted))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MetricCategory.cpu.accentColor)
                }
                Spacer()
                
                // View Mode Picker (Overall vs Logical Processors)
                Picker("View", selection: $viewModel.cpuViewMode) {
                    ForEach(CPUViewMode.allCases) { mode in
                        Text(mode == .overall ? "Overall" : "All Cores").tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 150)
            }
            
            if viewModel.cpuViewMode == .overall {
                // 60-Second Overall Rolling Graph
                WindowsGraphView(
                    values: viewModel.cpuOverallHistory.values,
                    maxValue: 100.0,
                    unit: "%",
                    accentColor: MetricCategory.cpu.accentColor,
                    title: "% Utilization (60 Seconds)",
                    showGrid: true
                )
                .frame(height: 180)
            } else {
                // Windows Logical Processors Grid (All Cores!)
                LogicalCoresGrid(
                    coreLoads: viewModel.cpuMetrics.coreLoads,
                    coreHistories: viewModel.coreHistories,
                    accentColor: MetricCategory.cpu.accentColor
                )
            }
            
            // Windows-Style CPU Specifications Grid
            VStack(spacing: 8) {
                statRow(label1: "Utilization", value1: String(format: "%.1f%%", viewModel.cpuMetrics.overallLoad),
                        label2: "Logical Cores", value2: "\(viewModel.cpuMetrics.logicalCores)")
                statRow(label1: "Performance Cores", value1: "\(viewModel.cpuMetrics.performanceCores) P-Cores",
                        label2: "Efficiency Cores", value2: "\(viewModel.cpuMetrics.efficiencyCores) E-Cores")
                statRow(label1: "Processes", value1: "\(viewModel.cpuMetrics.processCount)",
                        label2: "Architecture", value2: viewModel.cpuMetrics.architecture)
                statRow(label1: "System Uptime", value1: viewModel.cpuMetrics.uptimeFormatted,
                        label2: "Sockets", value2: "1 (Integrated SoC)")
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Memory Detail Section
    private var memoryDetailSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Memory (RAM)")
                    .font(.system(size: 18, weight: .bold))
                Text(String(format: "%.2f GB In Use (%.0f%%) • %.2f GB Available", viewModel.memoryMetrics.usedGB, viewModel.memoryMetrics.usedPercentage, viewModel.memoryMetrics.availableGB))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MetricCategory.memory.accentColor)
            }
            
            // 60-Second Memory Graph
            WindowsGraphView(
                values: viewModel.memoryHistory.values,
                maxValue: 100.0,
                unit: "%",
                accentColor: MetricCategory.memory.accentColor,
                title: "Memory Usage (60 Seconds)",
                showGrid: true
            )
            .frame(height: 180)
            
            // Memory Composition Bar
            VStack(alignment: .leading, spacing: 6) {
                Text("Memory Composition")
                    .font(.system(size: 13, weight: .semibold))
                
                GeometryReader { geo in
                    let total = max(1.0, Double(viewModel.memoryMetrics.totalBytes))
                    let wiredW = geo.size.width * CGFloat(Double(viewModel.memoryMetrics.wiredBytes) / total)
                    let activeW = geo.size.width * CGFloat(Double(viewModel.memoryMetrics.activeBytes) / total)
                    let compressedW = geo.size.width * CGFloat(Double(viewModel.memoryMetrics.compressedBytes) / total)
                    let freeW = geo.size.width * CGFloat(Double(viewModel.memoryMetrics.freeBytes) / total)
                    
                    HStack(spacing: 2) {
                        Rectangle().fill(Color.purple).frame(width: wiredW)
                        Rectangle().fill(Color.blue).frame(width: activeW)
                        Rectangle().fill(Color.orange).frame(width: compressedW)
                        Rectangle().fill(Color.green.opacity(0.6)).frame(width: freeW)
                    }
                    .cornerRadius(4)
                }
                .frame(height: 14)
                
                HStack(spacing: 12) {
                    legendItem(color: .purple, label: "Wired")
                    legendItem(color: .blue, label: "Active")
                    legendItem(color: .orange, label: "Compressed")
                    legendItem(color: .green.opacity(0.8), label: "Free")
                }
                .padding(.top, 2)
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
            
            // Specs table
            VStack(spacing: 8) {
                statRow(label1: "Total RAM", value1: String(format: "%.2f GB", viewModel.memoryMetrics.totalGB),
                        label2: "In Use", value2: String(format: "%.2f GB", viewModel.memoryMetrics.usedGB))
                statRow(label1: "Available", value1: String(format: "%.2f GB", viewModel.memoryMetrics.availableGB),
                        label2: "Wired Memory", value2: formatBytes(viewModel.memoryMetrics.wiredBytes))
                statRow(label1: "Active Memory", value1: formatBytes(viewModel.memoryMetrics.activeBytes),
                        label2: "Compressed", value2: formatBytes(viewModel.memoryMetrics.compressedBytes))
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Disk Detail Section
    private var diskDetailSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Disk 0 (Apple APFS NVMe)")
                    .font(.system(size: 18, weight: .bold))
                Text(String(format: "Read: %.2f MB/s • Write: %.2f MB/s", viewModel.storageMetrics.readBytesPerSec / 1_048_576.0, viewModel.storageMetrics.writeBytesPerSec / 1_048_576.0))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MetricCategory.disk.accentColor)
            }
            
            // 60-Second Read / Write Transfer Rate Graph
            WindowsGraphView(
                values: viewModel.diskReadHistory.values,
                maxValue: max(10.0, viewModel.diskReadHistory.peak * 1.2),
                unit: "MB/s",
                accentColor: MetricCategory.disk.accentColor,
                title: "Disk Transfer Rate (Read)",
                showGrid: true
            )
            .frame(height: 180)
            
            // Storage Capacity Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Storage Capacity")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text(String(format: "%.1f GB Free of %.1f GB", viewModel.storageMetrics.freeGB, viewModel.storageMetrics.totalGB))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: viewModel.storageMetrics.usedPercentage, total: 100.0)
                    .accentColor(MetricCategory.disk.accentColor)
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
            
            // Specs table
            VStack(spacing: 8) {
                statRow(label1: "Active Time", value1: String(format: "%.0f%%", viewModel.storageMetrics.activeTimePercentage),
                        label2: "Total Capacity", value2: String(format: "%.1f GB", viewModel.storageMetrics.totalGB))
                statRow(label1: "Read Speed", value1: String(format: "%.2f MB/s", viewModel.storageMetrics.readBytesPerSec / 1_048_576.0),
                        label2: "Write Speed", value2: String(format: "%.2f MB/s", viewModel.storageMetrics.writeBytesPerSec / 1_048_576.0))
                statRow(label1: "File System", value1: "APFS (Encrypted)",
                        label2: "Drive Type", value2: "Integrated NVMe Solid State")
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Wi-Fi Detail Section
    private var wifiDetailSection: some View {
        let wifi = viewModel.wifiMetrics ?? WiFiMetrics()
        
        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Wi-Fi (\(wifi.ssid))")
                    .font(.system(size: 18, weight: .bold))
                HStack(spacing: 8) {
                    Text("Link Speed: \(String(format: "%.0f Mbps", wifi.linkSpeedMbps))")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(MetricCategory.wifi.accentColor)
                    Text("• Signal: \(wifi.rssiDbm) dBm (\(wifi.signalQualityPercent)%)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            // 60-Second Download/Upload Throughput Graph
            WindowsGraphView(
                values: viewModel.networkDownHistory.values,
                maxValue: max(5.0, viewModel.networkDownHistory.peak * 1.2),
                unit: "MB/s",
                accentColor: MetricCategory.wifi.accentColor,
                title: "Wi-Fi Throughput (60 Seconds)",
                showGrid: true
            )
            .frame(height: 180)
            
            // Wi-Fi Radio & Link Details Table
            VStack(spacing: 8) {
                statRow(label1: "SSID", value1: wifi.ssid,
                        label2: "Wi-Fi Link Speed", value2: String(format: "%.0f Mbps", wifi.linkSpeedMbps))
                statRow(label1: "Signal Strength", value1: "\(wifi.rssiDbm) dBm (\(wifi.signalQualityPercent)%)",
                        label2: "Protocol / Generation", value2: wifi.standard)
                statRow(label1: "Band / Frequency", value1: wifi.band,
                        label2: "Channel", value2: "\(wifi.channel)")
                let en0IP = viewModel.networkInterfaces.first(where: { $0.isWiFi })?.ipAddress ?? "---"
                statRow(label1: "IPv4 Address", value1: en0IP,
                        label2: "Interface Name", value2: "en0 (802.11 NIC)")
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Cellular Detail Section
    private var cellularDetailSection: some View {
        let cell = viewModel.networkInterfaces.first(where: { $0.isCellular })
        
        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Cellular Data")
                    .font(.system(size: 18, weight: .bold))
                Text(cell != nil ? "Interface Active (\(cell!.interfaceName))" : "No Cellular Connection")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MetricCategory.cellular.accentColor)
            }
            
            WindowsGraphView(
                values: viewModel.networkUpHistory.values,
                maxValue: max(2.0, viewModel.networkUpHistory.peak * 1.2),
                unit: "MB/s",
                accentColor: MetricCategory.cellular.accentColor,
                title: "Cellular Throughput (Upload/Download)",
                showGrid: true
            )
            .frame(height: 180)
            
            VStack(spacing: 8) {
                statRow(label1: "Interface", value1: cell?.interfaceName ?? "pdp_ip0",
                        label2: "IP Address", value2: cell?.ipAddress ?? "---")
                statRow(label1: "Download", value1: String(format: "%.2f KB/s", (cell?.downloadBytesPerSec ?? 0) / 1024.0),
                        label2: "Upload", value2: String(format: "%.2f KB/s", (cell?.uploadBytesPerSec ?? 0) / 1024.0))
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
    }
    
    // MARK: - GPU Detail Section
    private var gpuDetailSection: some View {
        let gpu = viewModel.gpuMetrics
        let util = gpu.rendererUtilization > 0 ? gpu.rendererUtilization : gpu.deviceUtilization
        
        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(gpu.gpuName)
                    .font(.system(size: 18, weight: .bold))
                Text(String(format: "%.0f%% 3D / Renderer Utilization", util))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MetricCategory.gpu.accentColor)
            }
            
            // 60-Second GPU Graph
            WindowsGraphView(
                values: viewModel.gpuHistory.values,
                maxValue: 100.0,
                unit: "%",
                accentColor: MetricCategory.gpu.accentColor,
                title: "GPU 3D Utilization (60 Seconds)",
                showGrid: true
            )
            .frame(height: 180)
            
            // Specs table
            VStack(spacing: 8) {
                statRow(label1: "Device Utilization", value1: String(format: "%.1f%%", gpu.deviceUtilization),
                        label2: "Renderer 3D Load", value2: String(format: "%.1f%%", gpu.rendererUtilization))
                statRow(label1: "Tiler Utilization", value1: String(format: "%.1f%%", gpu.tilerUtilization),
                        label2: "Graphics API", value2: "Metal 3 Native")
                statRow(label1: "Architecture", value1: "Apple Unified Memory Architecture",
                        label2: "Hardware Accelerator", value2: "AGX Graphics Engine")
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Helper Layouts
    private func statRow(label1: String, value1: String, label2: String, value2: String) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label1)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Text(value1)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label2)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Text(value2)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let mb = Double(bytes) / 1_048_576.0
        if mb >= 1024 {
            return String(format: "%.2f GB", mb / 1024.0)
        }
        return String(format: "%.0f MB", mb)
    }
}
