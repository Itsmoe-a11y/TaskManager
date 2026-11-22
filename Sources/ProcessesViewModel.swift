import Foundation
import SwiftUI
import Combine

public enum ProcessSortColumn: String, CaseIterable, Identifiable {
    case cpu = "CPU"
    case memory = "Memory"
    case name = "Name"
    case pid = "PID"
    
    public var id: String { rawValue }
}

public enum ProcessFilterGroup: String, CaseIterable, Identifiable {
    case all = "All"
    case apps = "Apps"
    case daemons = "Daemons"
    
    public var id: String { rawValue }
}

@MainActor
public final class ProcessesViewModel: ObservableObject {
    @Published public var processes: [ProcessItem] = []
    @Published public var searchQuery: String = ""
    @Published public var sortColumn: ProcessSortColumn = .cpu
    @Published public var sortAscending: Bool = false
    @Published public var filterGroup: ProcessFilterGroup = .all
    @Published public var selectedProcess: ProcessItem?
    @Published public var toastMessage: String?
    
    private var timerCancellable: AnyCancellable?
    private let bridge = DarwinBridge.shared
    
    public init() {
        refresh()
        startTimer()
    }
    
    public func startTimer() {
        timerCancellable = Timer.publish(every: 1.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh()
            }
    }
    
    public func refresh() {
        let list = bridge.listProcesses()
        self.processes = list
    }
    
    public var filteredProcesses: [ProcessItem] {
        var result = processes
        
        // Filter group
        switch filterGroup {
        case .all:
            break
        case .apps:
            result = result.filter { $0.isApp }
        case .daemons:
            result = result.filter { !$0.isApp }
        }
        
        // Search query
        if !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = searchQuery.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(q) || String($0.pid).contains(q)
            }
        }
        
        // Sorting
        result.sort { a, b in
            switch sortColumn {
            case .cpu:
                return sortAscending ? a.cpuPercentage < b.cpuPercentage : a.cpuPercentage > b.cpuPercentage
            case .memory:
                return sortAscending ? a.memoryBytes < b.memoryBytes : a.memoryBytes > b.memoryBytes
            case .name:
                return sortAscending ? a.name.localizedCompare(b.name) == .orderedAscending : a.name.localizedCompare(b.name) == .orderedDescending
            case .pid:
                return sortAscending ? a.pid < b.pid : a.pid > b.pid
            }
        }
        
        return result
    }
    
    public func endTask(pid: Int32, force: Bool = false) {
        let success = bridge.terminateProcess(pid: pid, force: force)
        if success {
            toastMessage = "Terminated PID \(pid)"
            refresh()
        } else {
            toastMessage = "Failed to terminate PID \(pid) (Permission denied)"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            if self?.toastMessage?.contains(String(pid)) == true {
                self?.toastMessage = nil
            }
        }
    }
}
