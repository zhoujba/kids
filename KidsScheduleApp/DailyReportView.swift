import SwiftUI

struct DailyReportView: View {
    @Environment(\.dismiss) private var dismiss
    let report: WorkDailyReport
    @State private var showingShareSheet = false
    @State private var showingCopySuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 报告标题
                    Text("📊 \(report.formattedDate) 活动日报")
                        .font(.title)
                        .fontWeight(.bold)

                    // 今日工作内容
                    todayTasksSection

                    // 今日工作总结
                    todayTasksSummarySection

                    // 下一步计划
                    nextStepsSection

                    // 统计概览
                    statisticsOverviewSection
                }
                .padding()
            }
            .navigationTitle("📊 日报")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button("复制") {
                            copyReportText()
                        }
                        .foregroundColor(.blue)

                        Button("分享") {
                            showingShareSheet = true
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [generateReportText()])
            }
            .overlay(
                // 复制成功提示
                Group {
                    if showingCopySuccess {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("✅ 已复制到剪贴板")
                                    .font(.caption)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                Spacer()
                            }
                            .padding(.bottom, 100)
                        }
                        .transition(.opacity)
                    }
                }
            )
        }
    }

    // MARK: - 今日工作内容
    private var todayTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📋 今日工作内容")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)

            if report.allTasks.isEmpty {
                Text("今日暂无任务")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(report.allTasks.enumerated()), id: \.offset) { index, task in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .fontWeight(.medium)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title ?? "未命名任务")
                                .fontWeight(.medium)

                            HStack {
                                Text("\(categoryIcon(for: task.category ?? "其他")) \(task.category ?? "其他")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                if task.isCompleted {
                                    Text("✅ 已完成")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                } else {
                                    Text("🔄 \(task.formattedWorkProgress)")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - 今日工作总结
    private var todayTasksSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📝 今日工作总结")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.green)

            if report.allTasks.isEmpty {
                Text("今日暂无工作总结")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(report.allTasks.enumerated()), id: \.offset) { index, task in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .fontWeight(.medium)
                                .foregroundColor(.green)

                            Text(task.title ?? "未命名任务")
                                .fontWeight(.medium)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            if let notes = task.progressNotes, !notes.isEmpty {
                                Text("详情：\(notes)")
                                    .font(.body)
                                    .padding(.leading, 20)
                            } else {
                                Text("详情：暂无详细说明")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 20)
                            }

                            HStack {
                                Text("进度：\(task.formattedWorkProgress)")
                                    .font(.caption)
                                    .foregroundColor(.blue)

                                if task.timeSpent > 0 {
                                    Text("时间：\(task.formattedTimeSpent)")
                                        .font(.caption)
                                        .foregroundColor(.purple)
                                }

                                Spacer()
                            }
                            .padding(.leading, 20)
                        }
                    }
                    .padding(.vertical, 6)

                    if index < report.allTasks.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private func categoryIcon(for category: String) -> String {
        switch category {
        case "工作":
            return "💼"
        case "学习":
            return "📚"
        case "运动":
            return "🏃"
        case "娱乐":
            return "🎮"
        case "生活":
            return "🏠"
        case "其他":
            return "📝"
        default:
            return "📋"
        }
    }

    // MARK: - 下一步计划
    private var nextStepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎯 下一步计划")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.purple)

            let incompleteTasks = report.ongoingTasks
            let futureTasks = getFutureTasks()
            let allNextTasks = incompleteTasks + futureTasks

            if allNextTasks.isEmpty {
                Text("暂无下一步计划")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(allNextTasks.prefix(5).enumerated()), id: \.offset) { index, task in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .fontWeight(.medium)
                            .foregroundColor(.purple)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title ?? "未命名任务")
                                .fontWeight(.medium)

                            HStack {
                                Text("\(categoryIcon(for: task.category ?? "其他")) \(task.category ?? "其他")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                if incompleteTasks.contains(task) {
                                    Text("🔄 继续推进")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                } else {
                                    Text("📅 计划中")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                if allNextTasks.count > 5 {
                    Text("... 还有 \(allNextTasks.count - 5) 项任务")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - 统计概览
    private var statisticsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 统计概览")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.gray)

            HStack(spacing: 12) {
                StatCard(title: "总任务", value: "\(report.allTasks.count)", color: .blue)
                StatCard(title: "已完成", value: "\(report.completedTasks.count)", color: .green)
                StatCard(title: "完成率", value: "\(String(format: "%.0f", report.completionRate))%", color: .orange)
            }

            if !report.tasksByCategory.isEmpty {
                Divider()

                Text("分类统计")
                    .font(.subheadline)
                    .fontWeight(.medium)

                ForEach(Array(report.tasksByCategory.keys.sorted()), id: \.self) { category in
                    let tasks = report.tasksByCategory[category] ?? []
                    let completed = tasks.filter { $0.isCompleted }.count

                    HStack {
                        Text("\(categoryIcon(for: category)) \(category)")
                        Spacer()
                        Text("\(completed)/\(tasks.count)")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - 辅助方法
    private func getFutureTasks() -> [TaskItem] {
        // 这里应该从WorkManager获取未来的任务
        // 暂时返回空数组，后续可以扩展
        return []
    }

    private func generateReportText() -> String {
        var text = """
        📊 \(report.formattedDate) 活动日报

        📋 今日工作内容：
        """

        for (index, task) in report.allTasks.enumerated() {
            text += "\n\(index + 1). \(task.title ?? "未命名任务")"
        }

        text += "\n\n📝 今日工作总结："

        for (index, task) in report.allTasks.enumerated() {
            text += "\n\(index + 1). \(task.title ?? "未命名任务")"
            if let notes = task.progressNotes, !notes.isEmpty {
                text += "\n   详情：\(notes)"
            } else {
                text += "\n   详情：暂无详细说明"
            }
            text += "\n   进度：\(task.formattedWorkProgress)"
            if task.timeSpent > 0 {
                text += " | 时间：\(task.formattedTimeSpent)"
            }
        }

        text += "\n\n🎯 下一步计划："
        let nextTasks = report.ongoingTasks
        for (index, task) in nextTasks.enumerated() {
            text += "\n\(index + 1). \(task.title ?? "未命名任务")"
        }

        text += "\n\n📊 统计概览："
        text += "\n• 总任务：\(report.allTasks.count)项"
        text += "\n• 已完成：\(report.completedTasks.count)项"
        text += "\n• 完成率：\(String(format: "%.1f", report.completionRate))%"

        return text
    }

    private func copyReportText() {
        let reportText = generateReportText()
        UIPasteboard.general.string = reportText

        // 显示复制成功提示
        withAnimation(.easeInOut(duration: 0.3)) {
            showingCopySuccess = true
        }

        // 2秒后隐藏提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingCopySuccess = false
            }
        }
    }
}

// MARK: - 分享功能
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    let task1 = TaskItem(context: context)
    task1.title = "完成项目报告"
    task1.category = "工作"
    task1.isCompleted = true
    
    let task2 = TaskItem(context: context)
    task2.title = "学习Swift"
    task2.category = "学习"
    task2.isCompleted = false
    
    let tasksByCategory = [
        "工作": [task1],
        "学习": [task2]
    ]
    
    let report = WorkDailyReport(
        date: Date(),
        allTasks: [task1, task2],
        tasksByCategory: tasksByCategory,
        totalTimeSpent: 4.0,
        completedTasks: [task1],
        ongoingTasks: [task2],
        progressUpdates: 2
    )
    
    return DailyReportView(report: report)
}
