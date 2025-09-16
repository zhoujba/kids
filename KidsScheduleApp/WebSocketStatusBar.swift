import SwiftUI

struct WebSocketStatusBar: View {
    @ObservedObject var webSocketManager = WebSocketManager.shared
    
    var body: some View {
        HStack {
            // 连接状态指示器
            Circle()
                .fill(webSocketManager.isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            // 状态文本
            Text(webSocketManager.isConnected ? "实时同步已连接" : "实时同步断开")
                .font(.caption)
                .foregroundColor(webSocketManager.isConnected ? .green : .red)
            
            Spacer()
            
            // 连接按钮（仅在断开时显示）
            if !webSocketManager.isConnected {
                Button("重连") {
                    webSocketManager.connect()
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    WebSocketStatusBar()
}
