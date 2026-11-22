import SwiftUI

public struct WindowsGraphView: View {
    public let values: [Double]
    public let maxValue: Double
    public let unit: String
    public let accentColor: Color
    public let title: String?
    public let showGrid: Bool
    
    public init(
        values: [Double],
        maxValue: Double = 100.0,
        unit: String = "%",
        accentColor: Color = Color(red: 0.0, green: 0.72, blue: 0.95),
        title: String? = nil,
        showGrid: Bool = true
    ) {
        self.values = values
        self.maxValue = max(0.01, maxValue)
        self.unit = unit
        self.accentColor = accentColor
        self.title = title
        self.showGrid = showGrid
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title = title {
                HStack {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    if let latest = values.last {
                        Text(String(format: "%.1f %@", latest, unit))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(accentColor)
                    }
                }
            }
            
            ZStack {
                // Background container
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(UIColor.secondarySystemBackground).opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                
                // Grid lines (Windows style 25%, 50%, 75%)
                if showGrid {
                    GeometryReader { geo in
                        let w = geo.size.width
                        let h = geo.size.height
                        
                        Path { path in
                            for step in [0.25, 0.50, 0.75] {
                                let y = h * CGFloat(1.0 - step)
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: w, y: y))
                            }
                            // Vertical grid lines
                            for step in [0.25, 0.50, 0.75] {
                                let x = w * CGFloat(step)
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: h))
                            }
                        }
                        .stroke(
                            Color.primary.opacity(0.06),
                            style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                        )
                    }
                }
                
                // Chart path & area fill
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    
                    if values.count >= 2 {
                        let stepX = w / CGFloat(values.count - 1)
                        
                        // Area fill
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: h))
                            for (index, val) in values.enumerated() {
                                let normalized = CGFloat(min(maxValue, max(0.0, val)) / maxValue)
                                let x = CGFloat(index) * stepX
                                let y = h * (1.0 - normalized)
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                            path.addLine(to: CGPoint(x: w, y: h))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    accentColor.opacity(0.35),
                                    accentColor.opacity(0.03)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        // Stroke line
                        Path { path in
                            for (index, val) in values.enumerated() {
                                let normalized = CGFloat(min(maxValue, max(0.0, val)) / maxValue)
                                let x = CGFloat(index) * stepX
                                let y = h * (1.0 - normalized)
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(
                            accentColor,
                            style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
                        )
                    }
                }
                
                // Corner axis indicators
                VStack {
                    HStack {
                        Spacer()
                        Text(String(format: "%.0f %@", maxValue, unit))
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.7))
                            .padding([.top, .trailing], 4)
                    }
                    Spacer()
                    HStack {
                        Text("60 seconds")
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(.secondary.opacity(0.6))
                            .padding([.bottom, .leading], 4)
                        Spacer()
                        Text("0 \(unit)")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.7))
                            .padding([.bottom, .trailing], 4)
                    }
                }
            }
        }
    }
}

public struct SparklineView: View {
    public let values: [Double]
    public let maxValue: Double
    public let accentColor: Color
    
    public init(values: [Double], maxValue: Double = 100.0, accentColor: Color) {
        self.values = values
        self.maxValue = max(0.01, maxValue)
        self.accentColor = accentColor
    }
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            if values.count >= 2 {
                let stepX = w / CGFloat(values.count - 1)
                
                // Area fill
                Path { path in
                    path.move(to: CGPoint(x: 0, y: h))
                    for (index, val) in values.enumerated() {
                        let normalized = CGFloat(min(maxValue, max(0.0, val)) / maxValue)
                        let x = CGFloat(index) * stepX
                        let y = h * (1.0 - normalized)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [accentColor.opacity(0.3), accentColor.opacity(0.02)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Line
                Path { path in
                    for (index, val) in values.enumerated() {
                        let normalized = CGFloat(min(maxValue, max(0.0, val)) / maxValue)
                        let x = CGFloat(index) * stepX
                        let y = h * (1.0 - normalized)
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(accentColor, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
            }
        }
    }
}
