import SwiftUI
import UserNotifications

struct SettingsView: View {
    @State private var showingNotificationSettings = false
    @State private var notificationStatus = "检查中..."
    
    var body: some View {
        NavigationView {
            List {
                // WebSocket实时同步部分
                Section(header: Text("实时同步")) {
                    NavigationLink(destination: WebSocketStatusView()) {
                        HStack {
                            Image(systemName: "bolt.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("WebSocket实时同步")
                                    .font(.headline)
                                Text("任务变更立即推送到所有设备")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // 清除数据按钮
                    Button(action: {
                        clearAllData()
                    }) {
                        HStack {
                            Image(systemName: "trash.circle.fill")
                                .foregroundColor(.red)
                            VStack(alignment: .leading) {
                                Text("清除所有数据")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Text("删除本地所有任务数据并重新同步")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
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

    private func clearAllData() {
        // 清除本地Core Data数据
        WebSocketManager.shared.clearAllLocalTasks()

        // 重新连接WebSocket并同步数据
        WebSocketManager.shared.disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            WebSocketManager.shared.connect()
        }

        print("✅ 已清除所有本地数据并重新同步")
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
