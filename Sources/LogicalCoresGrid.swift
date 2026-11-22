import SwiftUI

public struct LogicalCoresGrid: View {
    public let coreLoads: [CoreLoad]
    public let coreHistories: [Int: HistoryBuffer]
    public let accentColor: Color
    
    public init(
        coreLoads: [CoreLoad],
        coreHistories: [Int: HistoryBuffer],
        accentColor: Color = Color(red: 0.0, green: 0.72, blue: 0.95)
    ) {
        self.coreLoads = coreLoads
        self.coreHistories = coreHistories
        self.accentColor = accentColor
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Logical Processors (\(coreLoads.isEmpty ? ProcessInfo.processInfo.activeProcessorCount : coreLoads.count) Cores)")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Text("Real-Time Load")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 2)
            
            if coreLoads.isEmpty {
                VStack(spacing: 8) {
                    ProgressView()
                        .padding(.top, 20)
                    Text("Sampling CPU Cores...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(8)
            } else {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(coreLoads) { core in
                        let history = coreHistories[core.coreIndex]?.values ?? Array(repeating: 0.0, count: 60)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Core \(core.coreIndex)")
                                    .font(.system(size: 12, weight: .bold))
                                
                                if core.isPerformanceCore {
                                    Text("P-Core")
                                        .font(.system(size: 9, weight: .heavy))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1.5)
                                        .background(Color.orange.opacity(0.2))
                                        .foregroundColor(.orange)
                                        .cornerRadius(3)
                                } else {
                                    Text("E-Core")
                                        .font(.system(size: 9, weight: .heavy))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1.5)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(3)
                                }
                                
                                Spacer()
                                
                                Text(String(format: "%.0f%%", core.loadPercentage))
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(accentColor)
                            }
                            
                            WindowsGraphView(
                                values: history,
                                maxValue: 100.0,
                                unit: "%",
                                accentColor: accentColor,
                                title: nil,
                                showGrid: true
                            )
                            .frame(height: 72)
                        }
                        .padding(8)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
}
