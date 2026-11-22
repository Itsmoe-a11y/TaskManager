import SwiftUI

public struct ProcessesView: View {
    @ObservedObject var viewModel: ProcessesViewModel
    @State private var showingDetailSheet: Bool = false
    @State private var confirmKillProcess: ProcessItem?
    
    public init(viewModel: ProcessesViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Toast notification bar
            if let toast = viewModel.toastMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(toast)
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemBackground))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Search Bar & Filter Chips
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search processes or PID...", text: $viewModel.searchQuery)
                        .font(.system(size: 14))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !viewModel.searchQuery.isEmpty {
                        Button(action: { viewModel.searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                
                // Filter Segment (All / Apps / Daemons)
                HStack {
                    Picker("Group", selection: $viewModel.filterGroup) {
                        ForEach(ProcessFilterGroup.allCases) { grp in
                            Text(grp.rawValue).tag(grp)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Spacer()
                    
                    Text("\(viewModel.filteredProcesses.count) processes")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
            
            Divider()
            
            // Table Header Bar (Windows Task Manager Columns)
            tableHeader
            
            Divider()
            
            // Process List (Decoupled from selection binding to prevent Int32 type mismatch)
            List {
                ForEach(viewModel.filteredProcesses) { proc in
                    processRow(proc)
                        .background(viewModel.selectedProcess?.pid == proc.pid ? Color.accentColor.opacity(0.15) : Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectedProcess = proc
                            showingDetailSheet = true
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                DispatchQueue.main.async {
                                    confirmKillProcess = proc
                                }
                            } label: {
                                Label("End Task", systemImage: "xmark.octagon.fill")
                            }
                        }
                }
            }
            .listStyle(PlainListStyle())
            
            // Bottom Action Bar: End Task button
            bottomBar
        }
        .navigationTitle("Processes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
        .sheet(isPresented: $showingDetailSheet) {
            if let proc = viewModel.selectedProcess {
                processDetailSheet(proc)
            }
        }
        .alert(item: $confirmKillProcess) { proc in
            Alert(
                title: Text("End Task"),
                message: Text("Are you sure you want to terminate \"\(proc.name)\" (PID \(proc.pid))?"),
                primaryButton: .destructive(Text("End Task")) {
                    viewModel.endTask(pid: proc.pid, force: true)
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - Table Header
    private var tableHeader: some View {
        HStack(spacing: 8) {
            headerButton(title: "Name", column: .name)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            headerButton(title: "PID", column: .pid)
                .frame(width: 50, alignment: .trailing)
            
            headerButton(title: "CPU", column: .cpu)
                .frame(width: 60, alignment: .trailing)
            
            headerButton(title: "Memory", column: .memory)
                .frame(width: 72, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color(UIColor.secondarySystemBackground).opacity(0.6))
    }
    
    private func headerButton(title: String, column: ProcessSortColumn) -> some View {
        Button(action: {
            if viewModel.sortColumn == column {
                viewModel.sortAscending.toggle()
            } else {
                viewModel.sortColumn = column
                viewModel.sortAscending = false
            }
        }) {
            HStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(viewModel.sortColumn == column ? .primary : .secondary)
                
                if viewModel.sortColumn == column {
                    Image(systemName: viewModel.sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Process Row
    private func processRow(_ proc: ProcessItem) -> some View {
        HStack(spacing: 8) {
            // Icon & Name
            HStack(spacing: 8) {
                Image(systemName: proc.isApp ? "app.badge.fill" : "gearshape.2.fill")
                    .font(.system(size: 14))
                    .foregroundColor(proc.isApp ? Color(red: 0.0, green: 0.72, blue: 0.95) : .secondary)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(proc.name)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    
                    Text("\(proc.user) • \(proc.threadsCount) thr")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // PID
            Text("\(proc.pid)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)
            
            // CPU %
            Text(String(format: "%.1f%%", proc.cpuPercentage))
                .font(.system(size: 12, weight: proc.cpuPercentage > 5.0 ? .bold : .regular, design: .monospaced))
                .foregroundColor(proc.cpuPercentage > 15.0 ? .red : (proc.cpuPercentage > 5.0 ? .orange : .primary))
                .frame(width: 60, alignment: .trailing)
            
            // Memory
            Text(String(format: "%.1f MB", proc.memoryMB))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.primary)
                .frame(width: 72, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Bottom Action Bar
    private var bottomBar: some View {
        HStack {
            if let selected = viewModel.selectedProcess {
                Text("Selected: \(selected.name) (PID \(selected.pid))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else {
                Text("Select a process to inspect or terminate")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                if let selected = viewModel.selectedProcess {
                    confirmKillProcess = selected
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                    Text("End Task")
                        .font(.system(size: 13, weight: .bold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(viewModel.selectedProcess != nil ? Color.red : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(viewModel.selectedProcess == nil)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - Process Detail Sheet
    private func processDetailSheet(_ proc: ProcessItem) -> some View {
        NavigationView {
            List {
                Section(header: Text("Process Overview")) {
                    detailRow(label: "Name", value: proc.name)
                    detailRow(label: "Process ID (PID)", value: "\(proc.pid)")
                    detailRow(label: "User / Owner", value: proc.user)
                    detailRow(label: "Type", value: proc.isApp ? "Application" : "Background System Daemon")
                }
                
                Section(header: Text("Resource Consumption")) {
                    detailRow(label: "CPU Utilization", value: String(format: "%.2f%%", proc.cpuPercentage))
                    detailRow(label: "Resident Memory", value: String(format: "%.2f MB (%llu bytes)", proc.memoryMB, proc.memoryBytes))
                    detailRow(label: "Active Threads", value: "\(proc.threadsCount)")
                }
                
                Section {
                    Button(role: .destructive, action: {
                        viewModel.endTask(pid: proc.pid, force: true)
                        showingDetailSheet = false
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "xmark.octagon.fill")
                            Text("End Task (Force Kill SIGKILL)")
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(proc.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingDetailSheet = false
                    }
                }
            }
        }
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
        }
    }
}
