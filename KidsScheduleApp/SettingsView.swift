import SwiftUI
import UserNotifications

struct SettingsView: View {
    @ObservedObject var mysqlSyncManager = MySQLSyncManager.shared
    @ObservedObject var mysqlManager = MySQLManager.shared
    @State private var showingNotificationSettings = false
    @State private var showingSyncDetails = false
    @State private var notificationStatus = "检查中..."
    
    var body: some View {
        NavigationView {
            List {
                // MySQL同步设置部分
                Section(header: Text("数据同步")) {
                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("MySQL同步")
                                .font(.headline)
                            Text("通过MySQL服务器在设备间同步数据")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()

                        VStack(alignment: .trailing) {
                            mysqlSyncStatusIndicator
                            if let lastSync = mysqlSyncManager.lastSyncDate {
                                Text(formatSyncTime(lastSync))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingSyncDetails = true
                    }

                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundColor(mysqlManager.isConnected ? .green : .red)
                        Text("MySQL连接")
                        Spacer()
                        Text(mysqlManager.isConnected ? "已连接" : "未连接")
                            .foregroundColor(.secondary)
                    }

                    Button(action: {
                        mysqlSyncManager.manualSync()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("立即同步")
                        }
                    }
                    .disabled(mysqlSyncManager.syncStatus == .syncing || !mysqlManager.isConnected)
                }
                
                // 通知设置部分
                Section(header: Text("通知设置")) {
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text("推送通知")
                                .font(.headline)
                            Text(notificationStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("设置") {
                            openNotificationSettings()
                        }
                        .font(.caption)
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                        Text("事项提醒")
                        Spacer()
                        Text("截止前15分钟")
                            .foregroundColor(.secondary)
                    }
                }
                
                // 应用信息部分
                Section(header: Text("应用信息")) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(.green)
                        Text("开发者")
                        Spacer()
                        Text("家长助手")
                            .foregroundColor(.secondary)
                    }
                }
                
                // 数据管理部分
                Section(header: Text("数据管理")) {
                    Button(action: {
                        // 导出数据功能
                        exportData()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("导出数据")
                        }
                    }
                    
                    Button(action: {
                        // 清除缓存功能
                        clearCache()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("清除缓存")
                        }
                    }
                }
                
                // 帮助和支持部分
                Section(header: Text("帮助和支持")) {
                    Button(action: {
                        // 使用指南
                        showUserGuide()
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                            Text("使用指南")
                        }
                    }
                    
                    Button(action: {
                        // 反馈问题
                        provideFeedback()
                    }) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.green)
                            Text("反馈问题")
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .onAppear {
                checkNotificationStatus()
            }
            .sheet(isPresented: $showingSyncDetails) {
                VStack {
                    Text("MySQL同步详情")
                        .font(.title2)
                        .padding()

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("连接状态:")
                            Spacer()
                            Text(mysqlManager.isConnected ? "已连接" : "未连接")
                                .foregroundColor(mysqlManager.isConnected ? .green : .red)
                        }

                        HStack {
                            Text("同步状态:")
                            Spacer()
                            Text(mysqlSyncManager.syncStatus.description)
                        }

                        if let lastSync = mysqlSyncManager.lastSyncDate {
                            HStack {
                                Text("上次同步:")
                                Spacer()
                                Text(formatSyncTime(lastSync))
                            }
                        }
                    }
                    .padding()

                    Spacer()

                    Button("关闭") {
                        showingSyncDetails = false
                    }
                    .padding()
                }
            }
        }
    }
    
    @ViewBuilder
    private var mysqlSyncStatusIndicator: some View {
        switch mysqlSyncManager.syncStatus {
        case .idle:
            Image(systemName: "cloud")
                .foregroundColor(.gray)
        case .syncing:
            ProgressView()
                .scaleEffect(0.8)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failed(_):
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
        }
    }
    
    private func formatSyncTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分钟前"
        } else {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    notificationStatus = "已开启"
                case .denied:
                    notificationStatus = "已拒绝"
                case .notDetermined:
                    notificationStatus = "未设置"
                case .provisional:
                    notificationStatus = "临时授权"
                case .ephemeral:
                    notificationStatus = "临时授权"
                @unknown default:
                    notificationStatus = "未知状态"
                }
            }
        }
    }
    
    private func openNotificationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func exportData() {
        // TODO: 实现数据导出功能
        print("导出数据功能待实现")
    }
    
    private func clearCache() {
        // TODO: 实现清除缓存功能
        print("清除缓存功能待实现")
    }
    
    private func showUserGuide() {
        // TODO: 显示使用指南
        print("使用指南功能待实现")
    }
    
    private func provideFeedback() {
        // TODO: 反馈功能
        print("反馈功能待实现")
    }
}

#Preview {
    SettingsView()
}
