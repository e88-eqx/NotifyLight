import SwiftUI

struct LogsView: View {
    @Environment(\.dismiss) private var dismiss
    let logs: [LogEntry]
    
    @State private var searchText = ""
    @State private var selectedLogType: LogType? = nil
    @State private var showingExportSheet = false
    
    var filteredLogs: [LogEntry] {
        var filtered = logs
        
        // Filter by type
        if let selectedType = selectedLogType {
            filtered = filtered.filter { $0.type == selectedType }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { log in
                log.message.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter controls
                filterSection
                
                // Logs list
                if filteredLogs.isEmpty {
                    emptyStateView
                } else {
                    logsList
                }
            }
            .navigationTitle("Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        showingExportSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportLogsView(logs: filteredLogs)
            }
        }
    }
    
    // MARK: - View Components
    
    private var filterSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search logs...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .font(.caption)
                }
            }
            
            // Log type filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All (\(logs.count))",
                        isSelected: selectedLogType == nil,
                        action: { selectedLogType = nil }
                    )
                    
                    ForEach(LogType.allCases, id: \.self) { logType in
                        let count = logs.filter { $0.type == logType }.count
                        
                        FilterChip(
                            title: "\(logType.rawValue.capitalized) (\(count))",
                            isSelected: selectedLogType == logType,
                            color: logType.color,
                            action: { 
                                selectedLogType = selectedLogType == logType ? nil : logType
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private var logsList: some View {
        List {
            ForEach(filteredLogs) { log in
                LogRowView(log: log)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No logs found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if !searchText.isEmpty || selectedLogType != nil {
                Text("Try adjusting your filters")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Clear Filters") {
                    searchText = ""
                    selectedLogType = nil
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LogRowView: View {
    let log: LogEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon and timestamp
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: log.type.icon)
                    .foregroundColor(log.type.color)
                    .font(.caption)
                
                Text(log.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60, alignment: .leading)
            
            // Message
            VStack(alignment: .leading, spacing: 4) {
                Text(log.message)
                    .font(.caption)
                    .foregroundColor(log.type.color)
                    .multilineTextAlignment(.leading)
                
                Text(log.type.rawValue.uppercased())
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(log.type.color.opacity(0.1))
        )
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    init(title: String, isSelected: Bool, color: Color = .blue, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? color : Color(.systemGray5))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ExportLogsView: View {
    @Environment(\.dismiss) private var dismiss
    let logs: [LogEntry]
    
    @State private var exportFormat: ExportFormat = .text
    @State private var includeTimestamps = true
    @State private var includeLogTypes = true
    
    enum ExportFormat: String, CaseIterable {
        case text = "Plain Text"
        case json = "JSON"
        case csv = "CSV"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Export Options") {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Toggle("Include Timestamps", isOn: $includeTimestamps)
                    Toggle("Include Log Types", isOn: $includeLogTypes)
                }
                
                Section("Preview") {
                    Text(generateExportText())
                        .font(.caption)
                        .monospaced()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Section {
                    Button("Export Logs") {
                        exportLogs()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Export Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateExportText() -> String {
        switch exportFormat {
        case .text:
            return logs.prefix(3).map { log in
                var parts: [String] = []
                
                if includeTimestamps {
                    parts.append("[\(log.timestamp.formatted(.dateTime.hour().minute().second()))]")
                }
                
                if includeLogTypes {
                    parts.append("[\(log.type.rawValue.uppercased())]")
                }
                
                parts.append(log.message)
                
                return parts.joined(separator: " ")
            }.joined(separator: "\n") + "\n..."
            
        case .json:
            let jsonLogs = logs.prefix(2).map { log in
                """
                {
                  "timestamp": "\(log.timestamp.ISO8601Format())",
                  "type": "\(log.type.rawValue)",
                  "message": "\(log.message)"
                }
                """
            }
            return "[\n" + jsonLogs.joined(separator: ",\n") + "\n...]"
            
        case .csv:
            var lines = ["timestamp,type,message"]
            lines.append(contentsOf: logs.prefix(3).map { log in
                "\(log.timestamp.ISO8601Format()),\(log.type.rawValue),\"\(log.message)\""
            })
            lines.append("...")
            return lines.joined(separator: "\n")
        }
    }
    
    private func exportLogs() {
        let exportText = generateFullExportText()
        
        let activityVC = UIActivityViewController(
            activityItems: [exportText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            var topVC = rootVC
            while let presentedVC = topVC.presentedViewController {
                topVC = presentedVC
            }
            
            activityVC.popoverPresentationController?.sourceView = topVC.view
            topVC.present(activityVC, animated: true)
        }
        
        dismiss()
    }
    
    private func generateFullExportText() -> String {
        let header = "NotifyLight iOS Test App - Debug Logs\n"
        let timestamp = "Generated: \(Date().formatted())\n"
        let count = "Total Logs: \(logs.count)\n"
        let separator = String(repeating: "=", count: 50) + "\n\n"
        
        let content: String
        
        switch exportFormat {
        case .text:
            content = logs.map { log in
                var parts: [String] = []
                
                if includeTimestamps {
                    parts.append("[\(log.timestamp.formatted(.dateTime.hour().minute().second()))]")
                }
                
                if includeLogTypes {
                    parts.append("[\(log.type.rawValue.uppercased())]")
                }
                
                parts.append(log.message)
                
                return parts.joined(separator: " ")
            }.joined(separator: "\n")
            
        case .json:
            let jsonLogs = logs.map { log in
                [
                    "timestamp": log.timestamp.ISO8601Format(),
                    "type": log.type.rawValue,
                    "message": log.message
                ]
            }
            
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonLogs, options: .prettyPrinted)
            content = String(data: jsonData ?? Data(), encoding: .utf8) ?? "JSON encoding failed"
            
        case .csv:
            var lines = ["timestamp,type,message"]
            lines.append(contentsOf: logs.map { log in
                "\(log.timestamp.ISO8601Format()),\(log.type.rawValue),\"\(log.message.replacingOccurrences(of: "\"", with: "\"\""))\""
            })
            content = lines.joined(separator: "\n")
        }
        
        return header + timestamp + count + separator + content
    }
}

#Preview {
    LogsView(logs: [
        LogEntry(id: UUID(), timestamp: Date(), message: "SDK initialized successfully", type: .success),
        LogEntry(id: UUID(), timestamp: Date(), message: "Token received", type: .info),
        LogEntry(id: UUID(), timestamp: Date(), message: "Network connection failed", type: .error),
        LogEntry(id: UUID(), timestamp: Date(), message: "Retrying connection", type: .warning)
    ])
}