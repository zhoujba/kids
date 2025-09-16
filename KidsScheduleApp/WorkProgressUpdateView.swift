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

    private var hasChanges: Bool {
        return progress != task.workProgress ||
               timeSpent > 0 ||
               progressNotes != (task.progressNotes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                taskInfoSection
                progressUpdateSection
                timeTrackingSection
                progressNotesSection
                if task.lastProgressUpdate != nil {
                    historySection
                }
            }
            .navigationTitle("更新工作进度")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveProgress()
                    }
                    .fontWeight(.semibold)
                    .disabled(!hasChanges)
                }
            }
            .alert("保存结果", isPresented: $showingAlert) {
                Button("确定") {
                    if alertMessage.contains("成功") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - UI Sections
    private var taskInfoSection: some View {
        Section("任务信息") {
            HStack {
                Image(systemName: "briefcase.fill")
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title ?? "未知任务")
                        .font(.headline)
                    if let description = task.taskDescription, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
            }

            HStack {
                Text("当前进度")
                Spacer()
                Text("\(Int(task.workProgress))%")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("累计时间")
                Spacer()
                Text(formatTimeSpent(task.timeSpent))
                    .foregroundColor(.secondary)
            }

            if let lastUpdate = task.lastProgressUpdate {
                HStack {
                    Text("最后更新")
                    Spacer()
                    Text(formatLastUpdate(lastUpdate))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var progressUpdateSection: some View {
        Section("进度更新") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("新进度: \(Int(progress))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    if progress >= 100 {
                        Text("✅ 已完成")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(6)
                    }
                }

                Slider(value: $progress, in: 0...100, step: 5)
                    .accentColor(.blue)

                ProgressView(value: progress, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: progress >= 100 ? .green : .blue))
                    .scaleEffect(x: 1, y: 1.2)
            }
        }
    }

    private var timeTrackingSection: some View {
        Section("本次时间投入") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("工作时长: \(String(format: "%.1f", timeSpent))小时")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }

                Slider(value: $timeSpent, in: 0...12, step: 0.5)
                    .accentColor(.orange)

                HStack(spacing: 8) {
                    ForEach([0.5, 1.0, 2.0, 4.0, 8.0], id: \.self) { hours in
                        Button("\(String(format: "%.1f", hours))h") {
                            timeSpent = hours
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(timeSpent == hours ? Color.orange : Color.orange.opacity(0.1))
                        .foregroundColor(timeSpent == hours ? .white : .orange)
                        .cornerRadius(6)
                    }
                }
            }
        }
    }

    private var progressNotesSection: some View {
        Section("进度说明") {
            TextField("描述本次工作内容和进展...", text: $progressNotes, axis: .vertical)
                .lineLimit(3...6)

            if !progressNotes.isEmpty {
                Text("\(progressNotes.count)/200")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var historySection: some View {
        Section("历史记录") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("上次更新")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    if let lastUpdate = task.lastProgressUpdate {
                        Text(formatLastUpdate(lastUpdate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("未更新")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let notes = task.progressNotes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
    }

    private func saveProgress() {
        // 验证输入
        guard progress >= 0 && progress <= 100 else {
            alertMessage = "进度必须在0-100%之间"
            showingAlert = true
            return
        }

        guard timeSpent >= 0 else {
            alertMessage = "时间投入不能为负数"
            showingAlert = true
            return
        }

        // 如果进度达到100%，自动标记为完成
        if progress >= 100 {
            task.isCompleted = true
        }

        // 更新进度
        WorkManager.shared.updateTaskProgress(
            task: task,
            progress: progress,
            timeSpent: timeSpent,
            notes: progressNotes.isEmpty ? "进度更新" : progressNotes
        )

        alertMessage = "工作进度更新成功！"
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
