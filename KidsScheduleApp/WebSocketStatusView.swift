import SwiftUI
import Foundation
import CoreData

struct WebSocketStatusView: View {
    @State private var isConnected = false
    @State private var connectionStatus = "检查连接状态..."

    var body: some View {
        VStack(spacing: 16) {
            // WebSocket连接状态
            HStack {
                Circle()
                    .fill(isConnected ? Color.green : Color.red)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading) {
                    Text("WebSocket实时同步")
                        .font(.headline)
                    Text(connectionStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    isConnected.toggle()
                    connectionStatus = isConnected ? "已连接" : "已断开"
                }) {
                    Text(isConnected ? "断开" : "连接")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isConnected ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            Divider()

            // 测试按钮
            HStack {
                Button("测试WebSocket连接") {
                    testWebSocket()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)

                Spacer()
            }
            
            // 连接说明
            VStack(alignment: .leading, spacing: 8) {
                Text("实时同步说明")
                    .font(.headline)

                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.green)
                    Text("WebSocket实时同步：任务变更立即推送到所有设备")
                        .font(.caption)
                }

                HStack {
                    Image(systemName: "iphone.and.arrow.forward")
                        .foregroundColor(.blue)
                    Text("初始化同步：连接时自动同步所有任务")
                        .font(.caption)
                }

                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                    Text("删除任务：通过WebSocket实时删除，所有设备同步")
                        .font(.caption)
                }

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                    Text("状态更新：完成状态变更实时同步")
                        .font(.caption)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }

    private func testWebSocket() {
        // 简化的测试功能
        print("WebSocket测试功能")
    }
}

#Preview {
    WebSocketStatusView()
}
