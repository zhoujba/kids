import SwiftUI

struct WorkProgressUpdateView: View {
    @Environment(\.dismiss) private var dismiss
    let task: TaskItem
    
    @State private var progress: Double
    @State private var timeSpent: Double = 0
    @State private var progressNotes: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(task: TaskItem) {
        self.task = task
        self._progress = State(initialValue: task.workProgress)
        self._progressNotes = State(initialValue: task.progressNotes ?? "")
    }

    private func formatTimeSpent(_ timeSpent: Double) -> String {
        let hours = Int(timeSpent)
        let minutes = Int((timeSpent - Double(hours)) * 60)
        return hours > 0 ? "\(hours)小时\(minutes)分钟" : "\(minutes)分钟"
    }

    private func formatLastUpdate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("工作进度更新")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(task.title ?? "未知任务")
                    .font(.headline)

                Text("当前进度: \(Int(task.workProgress))%")
                    .font(.subheadline)

                Button("关闭") {
                    dismiss()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                Spacer()
            }
            .padding()
            .navigationTitle("进度更新")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveProgress() {
        // 简化的保存逻辑
        task.workProgress = progress
        task.progressNotes = progressNotes
        task.lastProgressUpdate = Date()

        do {
            try task.managedObjectContext?.save()
            alertMessage = "进度更新成功！"
        } catch {
            alertMessage = "保存失败: \(error.localizedDescription)"
        }
        showingAlert = true
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let sampleTask = TaskItem(context: context)
    sampleTask.title = "完成项目报告"
    sampleTask.taskDescription = "整理本周工作进展，准备下周计划"
    sampleTask.category = "工作"
    sampleTask.workProgress = 65
    sampleTask.timeSpent = 8.5
    sampleTask.progressNotes = "已完成需求分析和设计方案"
    sampleTask.lastProgressUpdate = Date()
    
    return WorkProgressUpdateView(task: sampleTask)
}
