import SwiftUI

struct DailyReportView: View {
    @Environment(\.dismiss) private var dismiss
    let report: WorkDailyReport
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 报告标题
                    reportHeader
                    
                    // 工作统计
                    workStatistics
                    
                    // 已完成工作
                    if !report.completedTasks.isEmpty {
                        completedTasksSection
                    }
                    
                    // 进行中工作
                    if !report.ongoingTasks.isEmpty {
                        ongoingTasksSection
                    }
                    
                    // 时间分析
                    timeAnalysisSection
                    
                    // 工作总结
                    workSummarySection
                }
                .padding()
            }
            .navigationTitle("每日工作报告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("分享") {
                        showingShareSheet = true
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [generateReportText()])
            }
        }
    }
    
    // MARK: - 报告标题
    private var reportHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text(report.formattedDate)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            Text("工作日报")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - 工作统计
    private var workStatistics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 工作统计")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatisticCard(
                    title: "涉及工作",
                    value: "\(report.workTasks.count)",
                    subtitle: "项任务",
                    color: .blue,
                    icon: "list.bullet"
                )
                
                StatisticCard(
                    title: "已完成",
                    value: "\(report.completedTasks.count)",
                    subtitle: "项任务",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                StatisticCard(
                    title: "完成率",
                    value: "\(String(format: "%.1f", report.completionRate))",
                    subtitle: "%",
                    color: report.completionRate >= 80 ? .green : (report.completionRate >= 60 ? .orange : .red),
                    icon: "percent"
                )
                
                StatisticCard(
                    title: "时间投入",
                    value: "\(String(format: "%.1f", report.totalTimeSpent))",
                    subtitle: "小时",
                    color: .purple,
                    icon: "clock.fill"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - 已完成工作
    private var completedTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("✅ 已完成工作 (\(report.completedTasks.count)项)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
            
            ForEach(report.completedTasks, id: \.objectID) { task in
                TaskReportCard(task: task, isCompleted: true)
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - 进行中工作
    private var ongoingTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔄 进行中工作 (\(report.ongoingTasks.count)项)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
            
            ForEach(report.ongoingTasks, id: \.objectID) { task in
                TaskReportCard(task: task, isCompleted: false)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - 时间分析
    private var timeAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⏱️ 时间分析")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    Text("总工作时长")
                    Spacer()
                    Text("\(String(format: "%.1f", report.totalTimeSpent))小时")
                        .fontWeight(.medium)
                }
                
                if !report.workTasks.isEmpty {
                    HStack {
                        Text("平均每项任务")
                        Spacer()
                        Text("\(String(format: "%.1f", report.totalTimeSpent / Double(report.workTasks.count)))小时")
                            .fontWeight(.medium)
                    }
                }
                
                HStack {
                    Text("工作效率")
                    Spacer()
                    Text(getEfficiencyText())
                        .fontWeight(.medium)
                        .foregroundColor(getEfficiencyColor())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - 工作总结
    private var workSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📝 工作总结")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                if report.completedTasks.count > 0 {
                    Text("✅ 今日成功完成 \(report.completedTasks.count) 项工作任务")
                        .foregroundColor(.green)
                }
                
                if report.ongoingTasks.count > 0 {
                    Text("🔄 还有 \(report.ongoingTasks.count) 项工作正在进行中")
                        .foregroundColor(.orange)
                }
                
                if report.totalTimeSpent > 0 {
                    Text("⏱️ 总计投入 \(String(format: "%.1f", report.totalTimeSpent)) 小时工作时间")
                        .foregroundColor(.blue)
                }
                
                if report.progressUpdates > 0 {
                    Text("📈 更新了 \(report.progressUpdates) 项工作进度")
                        .foregroundColor(.purple)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - 辅助方法
    private func getEfficiencyText() -> String {
        let completionRate = report.completionRate
        if completionRate >= 90 {
            return "优秀"
        } else if completionRate >= 70 {
            return "良好"
        } else if completionRate >= 50 {
            return "一般"
        } else {
            return "需改进"
        }
    }
    
    private func getEfficiencyColor() -> Color {
        let completionRate = report.completionRate
        if completionRate >= 90 {
            return .green
        } else if completionRate >= 70 {
            return .blue
        } else if completionRate >= 50 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func generateReportText() -> String {
        var text = """
        📊 \(report.formattedDate) 工作日报
        
        📈 工作统计：
        • 涉及工作：\(report.workTasks.count)项
        • 已完成：\(report.completedTasks.count)项
        • 完成率：\(String(format: "%.1f", report.completionRate))%
        • 时间投入：\(String(format: "%.1f", report.totalTimeSpent))小时
        
        """
        
        if !report.completedTasks.isEmpty {
            text += "✅ 已完成工作：\n"
            for task in report.completedTasks {
                text += "• \(task.title ?? "未知任务")\n"
            }
            text += "\n"
        }
        
        if !report.ongoingTasks.isEmpty {
            text += "🔄 进行中工作：\n"
            for task in report.ongoingTasks {
                text += "• \(task.title ?? "未知任务") (\(task.progressPercentage)%)\n"
            }
        }
        
        return text
    }
}

// MARK: - 统计卡片
struct StatisticCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 任务报告卡片
struct TaskReportCard: View {
    let task: TaskItem
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundColor(isCompleted ? .green : .orange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "未知任务")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    if !isCompleted {
                        Text("进度: \(task.progressPercentage)%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if task.timeSpent > 0 {
                        Text("⏱️ \(task.formattedTimeSpent)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
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
    task1.timeSpent = 4.5
    task1.workProgress = 100
    
    let task2 = TaskItem(context: context)
    task2.title = "客户需求分析"
    task2.category = "工作"
    task2.isCompleted = false
    task2.timeSpent = 2.0
    task2.workProgress = 65
    
    let report = WorkDailyReport(
        date: Date(),
        workTasks: [task1, task2],
        totalTimeSpent: 6.5,
        completedTasks: [task1],
        ongoingTasks: [task2],
        progressUpdates: 2
    )
    
    return DailyReportView(report: report)
}
