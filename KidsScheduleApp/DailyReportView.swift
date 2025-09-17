import SwiftUI

struct DailyReportView: View {
    @Environment(\.dismiss) private var dismiss
    let report: WorkDailyReport
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("📊 \(report.formattedDate) 活动日报")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📈 活动统计")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Text("总任务数")
                            Spacer()
                            Text("\(report.allTasks.count)")
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("已完成")
                            Spacer()
                            Text("\(report.completedTasks.count)")
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("完成率")
                            Spacer()
                            Text("\(String(format: "%.1f", report.completionRate))%")
                                .fontWeight(.medium)
                        }
                        
                        if !report.tasksByCategory.isEmpty {
                            Divider()
                            
                            Text("📋 分类统计")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(Array(report.tasksByCategory.keys.sorted()), id: \.self) { category in
                                let tasks = report.tasksByCategory[category] ?? []
                                let completed = tasks.filter { $0.isCompleted }.count
                                
                                HStack {
                                    Text("\(categoryIcon(for: category)) \(category)")
                                    Spacer()
                                    Text("\(completed)/\(tasks.count)")
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
            }
        }
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
