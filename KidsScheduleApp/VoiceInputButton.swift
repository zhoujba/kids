import SwiftUI

struct VoiceInputButton: View {
    @StateObject private var speechManager = SpeechRecognitionManager()
    @Binding var text: String
    @State private var showingPermissionAlert = false
    @State private var isPressed = false

    var body: some View {
        HStack {
            Button(action: {
                // 添加触觉反馈
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()

                if speechManager.hasPermission {
                    if speechManager.isRecording {
                        speechManager.stopRecording()
                        // 将识别的文字设置到绑定的text中
                        if !speechManager.recognizedText.isEmpty {
                            text = speechManager.recognizedText
                        }
                    } else {
                        speechManager.clearText()
                        speechManager.startRecording()
                    }
                } else {
                    // 首次使用时请求权限
                    speechManager.requestPermissions()
                }
            }) {
                ZStack {
                    // 背景圆圈，增大点击区域
                    Circle()
                        .fill(speechManager.isRecording ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                        .scaleEffect(isPressed ? 0.95 : 1.0)

                    // 麦克风图标
                    Image(systemName: speechManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title)
                        .foregroundColor(speechManager.isRecording ? .red : .blue)
                        .scaleEffect(speechManager.isRecording ? 1.1 : 1.0)
                }
            }
            .buttonStyle(PlainButtonStyle()) // 移除默认按钮样式
            .scaleEffect(speechManager.isRecording ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: speechManager.isRecording)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onLongPressGesture(
                minimumDuration: 0,
                maximumDistance: .infinity,
                pressing: { pressing in
                    isPressed = pressing
                    if pressing {
                        // 按下时的触觉反馈
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                },
                perform: {
                    // 长按完成时的操作
                }
            )

            // 状态指示器
            VStack(alignment: .leading, spacing: 2) {
                if speechManager.isRecording {
                    HStack(spacing: 4) {
                        // 录音动画指示器
                        HStack(spacing: 2) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 4, height: 4)
                                    .scaleEffect(speechManager.isRecording ? 1.0 : 0.5)
                                    .animation(
                                        .easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                        value: speechManager.isRecording
                                    )
                            }
                        }

                        Text("正在录音...")
                            .font(.caption)
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else if !speechManager.recognizedText.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)

                        Text("识别完成")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Text("点击开始录音")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                }
            }
            .frame(minWidth: 80, alignment: .leading)
        }
        .alert("需要权限", isPresented: $showingPermissionAlert) {
            Button("去设置") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("需要麦克风和语音识别权限才能使用语音输入功能。请在设置中开启权限。")
        }
        .alert("错误", isPresented: .constant(!speechManager.errorMessage.isEmpty)) {
            Button("确定") {
                speechManager.errorMessage = ""
            }
        } message: {
            Text(speechManager.errorMessage)
        }
        .onChange(of: speechManager.recognizedText) { _, newValue in
            if !newValue.isEmpty && !speechManager.isRecording {
                text = newValue
                // 识别成功时的触觉反馈
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)
            }
        }
        .onChange(of: speechManager.errorMessage) { _, newValue in
            if !newValue.isEmpty {
                // 错误时的触觉反馈
                let errorFeedback = UINotificationFeedbackGenerator()
                errorFeedback.notificationOccurred(.error)
            }
        }
    }
}

#Preview {
    @State var sampleText = ""
    return VStack {
        TextField("测试文本", text: $sampleText)
        VoiceInputButton(text: $sampleText)
    }
    .padding()
}
