import SwiftUI

struct MySQLSyncStatusView: View {
    @StateObject private var syncManager = MySQLSyncManager.shared
    @StateObject private var mysqlManager = MySQLManager.shared
    
    var body: some View {
        HStack(spacing: 8) {
            // 连接状态指示器
            Circle()
                .fill(connectionColor)
                .frame(width: 8, height: 8)
            
            // 状态文本
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 手动同步按钮
            if mysqlManager.isConnected {
                Button(action: {
                    Task {
                        await syncManager.performSync()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .disabled(syncManager.syncStatus == .syncing)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var connectionColor: Color {
        if mysqlManager.isConnected {
            switch syncManager.syncStatus {
            case .syncing:
                return .orange
            case .success:
                return .green
            case .failed:
                return .red
            case .idle:
                return .blue
            }
        } else {
            return .red
        }
    }
    
    private var statusText: String {
        if !mysqlManager.isConnected {
            return "MySQL未连接"
        }
        
        switch syncManager.syncStatus {
        case .idle:
            if let lastSync = syncManager.lastSyncDate {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "上次同步: \(formatter.string(from: lastSync))"
            } else {
                return "等待同步"
            }
        case .syncing:
            return "正在同步..."
        case .success:
            return "同步成功"
        case .failed(let error):
            return "同步失败: \(error)"
        }
    }
}

struct MySQLSyncStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            MySQLSyncStatusView()
            MySQLSyncStatusView()
            MySQLSyncStatusView()
        }
        .padding()
    }
}
