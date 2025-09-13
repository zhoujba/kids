import SwiftUI
import CoreData

struct VoiceMemoView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechManager = SpeechRecognitionManager()
    
    @State private var memoTitle = ""
    @State private var memoContent = ""
    @State private var showingSaveAlert = false
    @State private var saveAlertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("备忘录标题")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("请输入标题", text: $memoTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // 语音识别区域
                VStack(spacing: 16) {
                    // 实时转换的文字显示
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("语音转文字")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if speechManager.isRecording {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                        .scaleEffect(speechManager.isRecording ? 1.0 : 0.5)
                                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: speechManager.isRecording)
                                    
                                    Text("正在录音...")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        ScrollView {
                            Text(speechManager.recognizedText.isEmpty ? "点击下方按钮开始语音输入..." : speechManager.recognizedText)
                                .font(.body)
                                .foregroundColor(speechManager.recognizedText.isEmpty ? .secondary : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(speechManager.isRecording ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                )
                        }
                        .frame(minHeight: 120, maxHeight: 200)
                    }
                    
                    // 录音控制按钮
                    HStack(spacing: 16) {
                        // 开始/停止录音按钮
                        Button(action: {
                            if speechManager.isRecording {
                                speechManager.stopRecording()
                            } else {
                                if !speechManager.hasPermission {
                                    speechManager.requestPermissions()
                                } else {
                                    speechManager.startRecording()
                                }
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: speechManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.title2)
                                Text(speechManager.isRecording ? "停止录音" : "开始录音")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(speechManager.isRecording ? Color.red : Color.blue)
                            )
                        }
                        .disabled(!speechManager.hasPermission && speechManager.errorMessage.isEmpty)
                        
                        // 添加到备忘录按钮
                        Button(action: {
                            addToMemo()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("添加到备忘录")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.green)
                            )
                        }
                        .disabled(speechManager.recognizedText.isEmpty)
                    }
                    
                    // 清除按钮
                    Button(action: {
                        speechManager.clearText()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash.circle.fill")
                                .font(.title2)
                            Text("清除文字")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.orange)
                        )
                    }
                    .disabled(speechManager.recognizedText.isEmpty)
                }
                
                // 备忘录内容编辑
                VStack(alignment: .leading, spacing: 8) {
                    Text("备忘录内容")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ScrollView {
                        TextEditor(text: $memoContent)
                            .font(.body)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .frame(minHeight: 100, maxHeight: 150)
                }
                
                // 错误信息显示
                if !speechManager.errorMessage.isEmpty {
                    Text(speechManager.errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("语音备忘录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveMemo()
                    }
                    .disabled(memoTitle.isEmpty && memoContent.isEmpty)
                }
            }
        }
        .onAppear {
            speechManager.requestPermissions()
        }
        .onDisappear {
            speechManager.stopRecording()
        }
        .alert("保存结果", isPresented: $showingSaveAlert) {
            Button("确定") { }
        } message: {
            Text(saveAlertMessage)
        }
    }
    
    // 添加语音识别的文字到备忘录内容
    private func addToMemo() {
        if !speechManager.recognizedText.isEmpty {
            if !memoContent.isEmpty {
                memoContent += "\n\n"
            }
            memoContent += speechManager.recognizedText
            speechManager.clearText()
        }
    }
    
    // 保存备忘录
    private func saveMemo() {
        let newMemo = TaskItem(context: viewContext)
        newMemo.title = memoTitle.isEmpty ? "语音备忘录" : memoTitle
        newMemo.taskDescription = memoContent
        newMemo.category = "备忘录"
        newMemo.createdDate = Date()
        newMemo.dueDate = Date()
        newMemo.isCompleted = false
        newMemo.lastModified = Date()
        newMemo.needsSync = true
        MySQLSyncManager.shared.markTaskForSync(newMemo)
        
        do {
            try viewContext.save()
            saveAlertMessage = "备忘录保存成功！"
            showingSaveAlert = true
            
            // 延迟关闭视图
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            saveAlertMessage = "保存失败：\(error.localizedDescription)"
            showingSaveAlert = true
        }
    }
}

#Preview {
    VoiceMemoView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
