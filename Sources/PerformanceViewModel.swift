import Foundation
import SwiftUI
import Combine

public enum CPUViewMode: String, CaseIterable, Identifiable {
    case overall = "Overall Utilization"
    case logicalProcessors = "Logical Processors"
    
    public var id: String { rawValue }
}

public enum UpdateSpeed: Double, CaseIterable, Identifiable {
    case high = 0.5
    case normal = 1.0
    case low = 2.0
    case paused = 0.0
    
    public var id: Double { rawValue }
    
    public var displayName: String {
        switch self {
        case .high: return "High (0.5s)"
        case .normal: return "Normal (1.0s)"
        case .low: return "Low (2.0s)"
        case .paused: return "Paused"
        }
    }
}

@MainActor
public final class PerformanceViewModel: ObservableObject {
    @Published public var selectedCategory: MetricCategory = .cpu
    @Published public var cpuViewMode: CPUViewMode = .overall
    @Published public var updateSpeed: UpdateSpeed = .normal {
        didSet { restartTimer() }
    }
    
    // Live metrics
    @Published public var cpuMetrics: CPUMetrics = CPUMetrics()
    @Published public var gpuMetrics: GPUMetrics = GPUMetrics()
    @Published public var memoryMetrics: MemoryMetrics = MemoryMetrics()
    @Published public var storageMetrics: StorageMetrics = StorageMetrics()
    @Published public var networkInterfaces: [NetworkInterfaceMetrics] = []
    @Published public var wifiMetrics: WiFiMetrics?
    
    // 60-second rolling history buffers
    @Published public var cpuOverallHistory = HistoryBuffer(capacity: 60)
    @Published public var coreHistories: [Int: HistoryBuffer] = [:]
    @Published public var gpuHistory = HistoryBuffer(capacity: 60)
    @Published public var memoryHistory = HistoryBuffer(capacity: 60)
    @Published public var diskReadHistory = HistoryBuffer(capacity: 60)
    @Published public var diskWriteHistory = HistoryBuffer(capacity: 60)
    @Published public var networkDownHistory = HistoryBuffer(capacity: 60)
    @Published public var networkUpHistory = HistoryBuffer(capacity: 60)
    
    private var timerCancellable: AnyCancellable?
    private let bridge = DarwinBridge.shared
    private var isRefreshing: Bool = false
    
    public init() {
        // Keep init completely pure and lightweight to allow immediate first-frame launch
    }
    
    public func startMonitoring() {
        refresh()
        restartTimer()
    }
    
    public func stopMonitoring() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    public func restartTimer() {
        timerCancellable?.cancel()
        guard updateSpeed != .paused else { return }
        
        timerCancellable = Timer.publish(every: updateSpeed.rawValue, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh()
            }
    }
    
    public func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        
        Task.detached(priority: .userInitiated) { [weak self, bridge] in
            let cpu = bridge.sampleCPUMetrics()
            let gpu = bridge.sampleGPUMetrics()
            let mem = bridge.sampleMemoryMetrics()
            let st = bridge.sampleStorageMetrics()
            let net = bridge.sampleNetworkMetrics()
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.isRefreshing = false
                
                self.cpuMetrics = cpu
                self.cpuOverallHistory.append(cpu.overallLoad)
                
                for core in cpu.coreLoads {
                    if self.coreHistories[core.coreIndex] == nil {
                        self.coreHistories[core.coreIndex] = HistoryBuffer(capacity: 60)
                    }
                    self.coreHistories[core.coreIndex]?.append(core.loadPercentage)
                }
                
                self.gpuMetrics = gpu
                self.gpuHistory.append(gpu.rendererUtilization > 0 ? gpu.rendererUtilization : gpu.deviceUtilization)
                
                self.memoryMetrics = mem
                self.memoryHistory.append(mem.usedPercentage)
                
                self.storageMetrics = st
                self.diskReadHistory.append(st.readBytesPerSec / 1_048_576.0)
                self.diskWriteHistory.append(st.writeBytesPerSec / 1_048_576.0)
                
                self.networkInterfaces = net.interfaces
                self.wifiMetrics = net.wifi
                
                var totalDown: Double = 0
                var totalUp: Double = 0
                for iface in net.interfaces {
                    totalDown += iface.downloadBytesPerSec
                    totalUp += iface.uploadBytesPerSec
                }
                self.networkDownHistory.append(totalDown / 1_048_576.0)
                self.networkUpHistory.append(totalUp / 1_048_576.0)
            }
        }
    }
}
