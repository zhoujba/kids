import SwiftUI

struct WeeklyReportView: View {
    @Environment(\.dismiss) private var dismiss
    let overview: WorkWeeklyOverview
    @State private var showingShareSheet = false
    @State private var showingCopySuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 报告标题
                    Text("📈 \(overview.formattedWeekRange) 周报")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // 本周工作内容
                    thisWeekTasksSection
                    
                    // 本周工作总结
                    thisWeekSummarySection
                    
                    // 下周计划
                    nextWeekPlanSection
                    
                    // 统计概览
                    weeklyStatisticsSection
                }
                .padding()
            }
            .navigationTitle("📈 周报")
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
                            copyWeeklyReportText()
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
                ShareSheet(activityItems: [generateWeeklyReportText()])
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
    
    // MARK: - 本周工作内容
    private var thisWeekTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📋 本周工作内容")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            if overview.allTasks.isEmpty {
                Text("本周暂无任务")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(overview.allTasks.enumerated()), id: \.offset) { index, task in
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
    
    // MARK: - 本周工作总结
    private var thisWeekSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📝 本周工作总结")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
            
            if overview.allTasks.isEmpty {
                Text("本周暂无工作总结")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                // 按类型分组显示总结
                ForEach(Array(overview.tasksByCategory.keys.sorted()), id: \.self) { category in
                    let tasks = overview.tasksByCategory[category] ?? []
                    let completed = tasks.filter { $0.isCompleted }
                    let ongoing = tasks.filter { !$0.isCompleted }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(categoryIcon(for: category)) \(category)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            
                            Spacer()
                            
                            Text("\(completed.count)/\(tasks.count) 完成")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // 已完成任务
                        if !completed.isEmpty {
                            Text("✅ 已完成：")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.leading, 20)
                            
                            ForEach(completed, id: \.objectID) { task in
                                HStack {
                                    Text("• \(task.title ?? "未命名任务")")
                                        .font(.caption)
                                    
                                    Spacer()
                                    
                                    if task.timeSpent > 0 {
                                        Text(task.formattedTimeSpent)
                                            .font(.caption)
                                            .foregroundColor(.purple)
                                    }
                                }
                                .padding(.leading, 30)
                            }
                        }
                        
                        // 进行中任务
                        if !ongoing.isEmpty {
                            Text("🔄 进行中：")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.leading, 20)
                            
                            ForEach(ongoing, id: \.objectID) { task in
                                HStack {
                                    Text("• \(task.title ?? "未命名任务")")
                                        .font(.caption)
                                    
                                    Spacer()
                                    
                                    Text(task.formattedWorkProgress)
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                .padding(.leading, 30)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    
                    if category != overview.tasksByCategory.keys.sorted().last {
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
    
    // MARK: - 下周计划
    private var nextWeekPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎯 下周计划")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.purple)
            
            let ongoingTasks = overview.allTasks.filter { !$0.isCompleted }

            if ongoingTasks.isEmpty {
                Text("暂无下周计划")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                Text("继续推进以下任务：")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(Array(ongoingTasks.enumerated()), id: \.offset) { index, task in
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
                                
                                Text("当前进度：\(task.formattedWorkProgress)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
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
    
    // MARK: - 统计概览
    private var weeklyStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 本周统计")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                StatCard(title: "总任务", value: "\(overview.allTasks.count)", color: .blue)
                StatCard(title: "已完成", value: "\(overview.completedCount)", color: .green)
                StatCard(title: "完成率", value: "\(String(format: "%.0f", overview.completionRate))%", color: .orange)
            }
            
            HStack(spacing: 12) {
                StatCard(title: "总时长", value: "\(String(format: "%.1f", overview.totalTimeSpent))h", color: .purple)
                StatCard(title: "平均进度", value: "\(String(format: "%.0f", overview.averageProgress))%", color: .indigo)
                StatCard(title: "进行中", value: "\(overview.ongoingCount)", color: .orange)
            }
            
            if !overview.tasksByCategory.isEmpty {
                Divider()
                
                Text("分类统计")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(Array(overview.tasksByCategory.keys.sorted()), id: \.self) { category in
                    let tasks = overview.tasksByCategory[category] ?? []
                    let completed = tasks.filter { $0.isCompleted }.count
                    let totalTime = tasks.reduce(0) { $0 + $1.timeSpent }
                    
                    HStack {
                        Text("\(categoryIcon(for: category)) \(category)")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(completed)/\(tasks.count)")
                                .fontWeight(.medium)
                            if totalTime > 0 {
                                Text("\(String(format: "%.1f", totalTime))h")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
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
    
    private func generateWeeklyReportText() -> String {
        var text = """
        📈 \(overview.formattedWeekRange) 周报
        
        📋 本周工作内容：
        """
        
        for (index, task) in overview.allTasks.enumerated() {
            text += "\n\(index + 1). \(task.title ?? "未命名任务")"
        }
        
        text += "\n\n📝 本周工作总结："
        
        for category in overview.tasksByCategory.keys.sorted() {
            let tasks = overview.tasksByCategory[category] ?? []
            let completed = tasks.filter { $0.isCompleted }
            let ongoing = tasks.filter { !$0.isCompleted }
            
            text += "\n\n\(categoryIcon(for: category)) \(category) (\(completed.count)/\(tasks.count) 完成)："
            
            if !completed.isEmpty {
                text += "\n✅ 已完成："
                for task in completed {
                    text += "\n  • \(task.title ?? "未命名任务")"
                }
            }
            
            if !ongoing.isEmpty {
                text += "\n🔄 进行中："
                for task in ongoing {
                    text += "\n  • \(task.title ?? "未命名任务") (\(task.formattedWorkProgress))"
                }
            }
        }
        
        text += "\n\n🎯 下周计划："
        let ongoingTasks = overview.allTasks.filter { !$0.isCompleted }
        for (index, task) in ongoingTasks.enumerated() {
            text += "\n\(index + 1). \(task.title ?? "未命名任务")"
        }
        
        text += "\n\n📊 本周统计："
        text += "\n• 总任务：\(overview.allTasks.count)项"
        text += "\n• 已完成：\(overview.completedCount)项"
        text += "\n• 完成率：\(String(format: "%.1f", overview.completionRate))%"
        text += "\n• 总时长：\(String(format: "%.1f", overview.totalTimeSpent))小时"
        text += "\n• 平均进度：\(String(format: "%.1f", overview.averageProgress))%"
        
        return text
    }

    private func copyWeeklyReportText() {
        let reportText = generateWeeklyReportText()
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

#Preview {
    @Previewable @State var overview: WorkWeeklyOverview = {
        let context = PersistenceController.preview.container.viewContext

        let task1 = TaskItem(context: context)
        task1.title = "完成项目报告"
        task1.category = "工作"
        task1.isCompleted = true
        task1.timeSpent = 8.0

        let task2 = TaskItem(context: context)
        task2.title = "学习Swift"
        task2.category = "学习"
        task2.isCompleted = false
        task2.workProgress = 60.0
        task2.timeSpent = 4.0

        let tasksByCategory = [
            "工作": [task1],
            "学习": [task2]
        ]

        return WorkWeeklyOverview(
            weekStart: Date(),
            weekEnd: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            allTasks: [task1, task2],
            tasksByCategory: tasksByCategory,
            totalTimeSpent: 12.0,
            averageProgress: 80.0,
            completedCount: 1,
            ongoingCount: 1
        )
    }()

    WeeklyReportView(overview: overview)
}
