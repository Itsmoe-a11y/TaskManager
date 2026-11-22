import Foundation
import SwiftUI

// MARK: - History Ring Buffer
public struct HistoryBuffer {
    public let capacity: Int
    private var elements: [Double]
    
    public init(capacity: Int = 60, initialValue: Double = 0.0) {
        let safeCapacity = max(2, capacity)
        self.capacity = safeCapacity
        let safeInit = (initialValue.isNaN || initialValue.isInfinite) ? 0.0 : initialValue
        self.elements = Array(repeating: safeInit, count: safeCapacity)
    }
    
    public mutating func append(_ value: Double) {
        let safeVal = (value.isNaN || value.isInfinite) ? 0.0 : value
        while elements.count >= capacity {
            elements.removeFirst()
        }
        elements.append(safeVal)
    }
    
    public var values: [Double] {
        return elements
    }
    
    public var latest: Double {
        return elements.last ?? 0.0
    }
    
    public var peak: Double {
        let maxVal = elements.max() ?? 0.0
        return (maxVal.isNaN || maxVal.isInfinite) ? 0.0 : maxVal
    }
    
    public var average: Double {
        guard !elements.isEmpty else { return 0.0 }
        let sum = elements.reduce(0.0) { $0 + ($1.isNaN ? 0.0 : $1) }
        return sum / Double(elements.count)
    }
}

// MARK: - CPU Models
public struct CoreLoad: Identifiable, Equatable {
    public let id: Int
    public let coreIndex: Int
    public let loadPercentage: Double
    public let isPerformanceCore: Bool
    
    public init(coreIndex: Int, loadPercentage: Double, isPerformanceCore: Bool = false) {
        self.id = coreIndex
        self.coreIndex = coreIndex
        let val = (loadPercentage.isNaN || loadPercentage.isInfinite) ? 0.0 : loadPercentage
        self.loadPercentage = min(100.0, max(0.0, val))
        self.isPerformanceCore = isPerformanceCore
    }
}

public struct CPUMetrics: Equatable {
    public var overallLoad: Double
    public var coreLoads: [CoreLoad]
    public var userPercentage: Double
    public var systemPercentage: Double
    public var idlePercentage: Double
    public var uptimeSeconds: TimeInterval
    public var processCount: Int
    public var threadCount: Int
    public var cpuName: String
    public var architecture: String
    public var physicalCores: Int
    public var logicalCores: Int
    public var performanceCores: Int
    public var efficiencyCores: Int
    
    public init(
        overallLoad: Double = 0.0,
        coreLoads: [CoreLoad] = [],
        userPercentage: Double = 0.0,
        systemPercentage: Double = 0.0,
        idlePercentage: Double = 100.0,
        uptimeSeconds: TimeInterval = 0,
        processCount: Int = 0,
        threadCount: Int = 0,
        cpuName: String = "Apple Silicon",
        architecture: String = "arm64",
        physicalCores: Int = 6,
        logicalCores: Int = 6,
        performanceCores: Int = 2,
        efficiencyCores: Int = 4
    ) {
        let loadVal = (overallLoad.isNaN || overallLoad.isInfinite) ? 0.0 : overallLoad
        self.overallLoad = min(100.0, max(0.0, loadVal))
        self.coreLoads = coreLoads
        self.userPercentage = userPercentage
        self.systemPercentage = systemPercentage
        self.idlePercentage = idlePercentage
        self.uptimeSeconds = uptimeSeconds
        self.processCount = processCount
        self.threadCount = threadCount
        self.cpuName = cpuName
        self.architecture = architecture
        self.physicalCores = physicalCores
        self.logicalCores = logicalCores
        self.performanceCores = performanceCores
        self.efficiencyCores = efficiencyCores
    }
    
    public var uptimeFormatted: String {
        let total = Int(uptimeSeconds)
        let days = total / 86400
        let hours = (total % 86400) / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if days > 0 {
            return String(format: "%d:%02d:%02d:%02d", days, hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
}

// MARK: - GPU Models
public struct GPUMetrics: Equatable {
    public var deviceUtilization: Double
    public var rendererUtilization: Double
    public var tilerUtilization: Double
    public var gpuName: String
    
    public init(
        deviceUtilization: Double = 0.0,
        rendererUtilization: Double = 0.0,
        tilerUtilization: Double = 0.0,
        gpuName: String = "Apple GPU"
    ) {
        let dev = (deviceUtilization.isNaN || deviceUtilization.isInfinite) ? 0.0 : deviceUtilization
        let rend = (rendererUtilization.isNaN || rendererUtilization.isInfinite) ? 0.0 : rendererUtilization
        let tile = (tilerUtilization.isNaN || tilerUtilization.isInfinite) ? 0.0 : tilerUtilization
        self.deviceUtilization = min(100.0, max(0.0, dev))
        self.rendererUtilization = min(100.0, max(0.0, rend))
        self.tilerUtilization = min(100.0, max(0.0, tile))
        self.gpuName = gpuName
    }
}

// MARK: - Memory Models
public struct MemoryMetrics: Equatable {
    public var totalBytes: UInt64
    public var usedBytes: UInt64
    public var availableBytes: UInt64
    public var wiredBytes: UInt64
    public var activeBytes: UInt64
    public var inactiveBytes: UInt64
    public var compressedBytes: UInt64
    public var freeBytes: UInt64
    
    public init(
        totalBytes: UInt64 = 0,
        usedBytes: UInt64 = 0,
        availableBytes: UInt64 = 0,
        wiredBytes: UInt64 = 0,
        activeBytes: UInt64 = 0,
        inactiveBytes: UInt64 = 0,
        compressedBytes: UInt64 = 0,
        freeBytes: UInt64 = 0
    ) {
        self.totalBytes = totalBytes
        self.usedBytes = usedBytes
        self.availableBytes = availableBytes
        self.wiredBytes = wiredBytes
        self.activeBytes = activeBytes
        self.inactiveBytes = inactiveBytes
        self.compressedBytes = compressedBytes
        self.freeBytes = freeBytes
    }
    
    public var usedPercentage: Double {
        guard totalBytes > 0 else { return 0.0 }
        return Double(usedBytes) / Double(totalBytes) * 100.0
    }
    
    public var totalGB: Double {
        return Double(totalBytes) / 1_073_741_824.0
    }
    
    public var usedGB: Double {
        return Double(usedBytes) / 1_073_741_824.0
    }
    
    public var availableGB: Double {
        return Double(availableBytes) / 1_073_741_824.0
    }
}

// MARK: - Storage Models
public struct StorageMetrics: Equatable {
    public var readBytesPerSec: Double
    public var writeBytesPerSec: Double
    public var totalBytes: UInt64
    public var freeBytes: UInt64
    public var usedBytes: UInt64
    public var activeTimePercentage: Double
    
    public init(
        readBytesPerSec: Double = 0.0,
        writeBytesPerSec: Double = 0.0,
        totalBytes: UInt64 = 0,
        freeBytes: UInt64 = 0,
        usedBytes: UInt64 = 0,
        activeTimePercentage: Double = 0.0
    ) {
        let r = (readBytesPerSec.isNaN || readBytesPerSec.isInfinite) ? 0.0 : readBytesPerSec
        let w = (writeBytesPerSec.isNaN || writeBytesPerSec.isInfinite) ? 0.0 : writeBytesPerSec
        let a = (activeTimePercentage.isNaN || activeTimePercentage.isInfinite) ? 0.0 : activeTimePercentage
        self.readBytesPerSec = max(0.0, r)
        self.writeBytesPerSec = max(0.0, w)
        self.totalBytes = totalBytes
        self.freeBytes = freeBytes
        self.usedBytes = usedBytes
        self.activeTimePercentage = min(100.0, max(0.0, a))
    }
    
    public var usedPercentage: Double {
        guard totalBytes > 0 else { return 0.0 }
        return Double(usedBytes) / Double(totalBytes) * 100.0
    }
    
    public var totalGB: Double {
        return Double(totalBytes) / 1_073_741_824.0
    }
    
    public var freeGB: Double {
        return Double(freeBytes) / 1_073_741_824.0
    }
    
    public var usedGB: Double {
        return Double(usedBytes) / 1_073_741_824.0
    }
    
    public var totalSpeedMBs: Double {
        return (readBytesPerSec + writeBytesPerSec) / 1_048_576.0
    }
}

// MARK: - Network Models
public struct NetworkInterfaceMetrics: Identifiable, Equatable {
    public var id: String { interfaceName }
    public var interfaceName: String
    public var displayName: String
    public var downloadBytesPerSec: Double
    public var uploadBytesPerSec: Double
    public var totalReceivedBytes: UInt64
    public var totalSentBytes: UInt64
    public var ipAddress: String
    public var isWiFi: Bool
    public var isCellular: Bool
    
    public init(
        interfaceName: String,
        displayName: String,
        downloadBytesPerSec: Double = 0.0,
        uploadBytesPerSec: Double = 0.0,
        totalReceivedBytes: UInt64 = 0,
        totalSentBytes: UInt64 = 0,
        ipAddress: String = "---",
        isWiFi: Bool = false,
        isCellular: Bool = false
    ) {
        self.interfaceName = interfaceName
        self.displayName = displayName
        let d = (downloadBytesPerSec.isNaN || downloadBytesPerSec.isInfinite) ? 0.0 : downloadBytesPerSec
        let u = (uploadBytesPerSec.isNaN || uploadBytesPerSec.isInfinite) ? 0.0 : uploadBytesPerSec
        self.downloadBytesPerSec = max(0.0, d)
        self.uploadBytesPerSec = max(0.0, u)
        self.totalReceivedBytes = totalReceivedBytes
        self.totalSentBytes = totalSentBytes
        self.ipAddress = ipAddress
        self.isWiFi = isWiFi
        self.isCellular = isCellular
    }
}

public struct WiFiMetrics: Equatable {
    public var ssid: String
    public var bssid: String
    public var rssiDbm: Int
    public var signalQualityPercent: Int
    public var linkSpeedMbps: Double
    public var channel: Int
    public var band: String
    public var standard: String
    
    public init(
        ssid: String = "Wi-Fi",
        bssid: String = "---",
        rssiDbm: Int = -55,
        signalQualityPercent: Int = 85,
        linkSpeedMbps: Double = 866.0,
        channel: Int = 36,
        band: String = "5 GHz",
        standard: String = "Wi-Fi 6 (802.11ax)"
    ) {
        self.ssid = ssid
        self.bssid = bssid
        self.rssiDbm = rssiDbm
        self.signalQualityPercent = min(100, max(0, signalQualityPercent))
        let spd = (linkSpeedMbps.isNaN || linkSpeedMbps.isInfinite) ? 866.0 : linkSpeedMbps
        self.linkSpeedMbps = spd
        self.channel = channel
        self.band = band
        self.standard = standard
    }
}

// MARK: - Process Models
public struct ProcessItem: Identifiable, Equatable, Hashable {
    public let id: Int32
    public let pid: Int32
    public let name: String
    public let cpuPercentage: Double
    public let memoryBytes: UInt64
    public let threadsCount: Int
    public let user: String
    public let isApp: Bool
    public let path: String
    
    public init(
        pid: Int32,
        name: String,
        cpuPercentage: Double = 0.0,
        memoryBytes: UInt64 = 0,
        threadsCount: Int = 1,
        user: String = "mobile",
        isApp: Bool = false,
        path: String = ""
    ) {
        self.id = pid
        self.pid = pid
        self.name = name
        let cpu = (cpuPercentage.isNaN || cpuPercentage.isInfinite) ? 0.0 : cpuPercentage
        self.cpuPercentage = min(100.0, max(0.0, cpu))
        self.memoryBytes = memoryBytes
        self.threadsCount = threadsCount
        self.user = user
        self.isApp = isApp
        self.path = path
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(pid)
    }
    
    public var memoryMB: Double {
        return Double(memoryBytes) / 1_048_576.0
    }
}

// MARK: - Metric Category Selection
public enum MetricCategory: String, CaseIterable, Identifiable {
    case cpu = "CPU"
    case memory = "Memory"
    case disk = "Disk"
    case wifi = "Wi-Fi"
    case cellular = "Cellular"
    case gpu = "GPU"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .disk: return "internaldrive"
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .gpu: return "display"
        }
    }
    
    public var accentColor: Color {
        switch self {
        case .cpu: return Color(red: 0.0, green: 0.72, blue: 0.95) // Neon Cyan
        case .memory: return Color(red: 0.65, green: 0.35, blue: 0.95) // Neon Purple
        case .disk: return Color(red: 0.05, green: 0.85, blue: 0.55) // Neon Emerald
        case .wifi: return Color(red: 0.98, green: 0.20, blue: 0.55) // Vibrant Magenta
        case .cellular: return Color(red: 0.95, green: 0.45, blue: 0.15) // Neon Orange
        case .gpu: return Color(red: 1.0, green: 0.75, blue: 0.1) // Amber Gold
        }
    }
}
