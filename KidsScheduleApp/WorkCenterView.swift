import SwiftUI

struct WorkCenterView: View {
    @StateObject private var workManager = WorkManager.shared
    @State private var showingProgressUpdate = false
    @State private var selectedTask: TaskItem?
    @State private var showingDailyReport = false
    @State private var showingAnalytics = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    todayWorkSection
                    weeklyOverviewSection
                    nextWeekPlanSection
                }
                .padding()
            }
            .navigationTitle("📋 活动中心")
            .onAppear {
                workManager.refreshWorkData()
            }
            .sheet(isPresented: $showingProgressUpdate) {
                if let task = selectedTask {
                    WorkProgressUpdateView(task: task)
                }
            }
            .sheet(isPresented: $showingDailyReport) {
                if let report = workManager.lastDailyReport {
                    DailyReportView(report: report)
                }
            }
            .sheet(isPresented: $showingAnalytics) {
                WorkAnalyticsView()
            }
        }
    }

    // MARK: - 今日活动汇报
    private var todayWorkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("📊 今日活动汇报")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                HStack(spacing: 8) {
                    Button("生成日报") {
                        let _ = workManager.generateDailyReport()
                        showingDailyReport = true
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)

                    Button("数据分析") {
                        showingAnalytics = true
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(8)
                }
            }

            // 统计卡片
            HStack(spacing: 12) {
                let ongoingCount = workManager.todayWorkTasks.filter { !$0.isCompleted }.count
                let completedCount = workManager.todayWorkTasks.filter { $0.isCompleted }.count
                let totalTime = workManager.todayWorkTasks.reduce(0.0) { $0 + $1.timeSpent }

                StatCard(title: "进行中", value: "\(ongoingCount)", color: .orange)
                StatCard(title: "已完成", value: "\(completedCount)", color: .green)
                StatCard(title: "总时长", value: String(format: "%.1fh", totalTime), color: .blue)
            }

            // 今日任务列表
            if workManager.todayWorkTasks.isEmpty {
                Text("今日暂无任务")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(workManager.todayWorkTasks, id: \.objectID) { task in
                    WorkTaskCard(task: task) {
                        selectedTask = task
                        showingProgressUpdate = true
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - 本周活动概览
    private var weeklyOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.purple)
                Text("📈 本周活动概览")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if let overview = workManager.weeklyOverview {
                    Text(overview.formattedWeekRange)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let overview = workManager.weeklyOverview {
                // 周度统计
                HStack(spacing: 12) {
                    StatCard(title: "总任务", value: "\(overview.allTasks.count)", color: .blue)
                    StatCard(title: "已完成", value: "\(overview.completedCount)", color: .green)
                    StatCard(title: "平均进度", value: "\(Int(overview.averageProgress))%", color: .purple)
                }

                // 本周工作列表（简化显示）
                let weekTasks = Array(workManager.thisWeekWorkTasks.prefix(3))
                ForEach(weekTasks, id: \.objectID) { task in
                    WorkTaskCard(task: task, isCompact: true) {
                        selectedTask = task
                        showingProgressUpdate = true
                    }
                }

                let remainingCount = workManager.thisWeekWorkTasks.count - 3
                if remainingCount > 0 {
                    Text("还有 \(remainingCount) 个工作任务...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            } else {
                Text("正在加载本周工作数据...")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - 下周活动规划
    private var nextWeekPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .foregroundColor(.green)
                Text("📅 下周活动规划")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("添加计划") {
                    // TODO: 实现添加下周活动计划功能
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                .cornerRadius(8)
            }

            if workManager.nextWeekWorkTasks.isEmpty {
                VStack(spacing: 8) {
                    Text("💡 下周活动规划")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("暂无下周活动计划，建议提前规划各类活动安排")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            } else {
                ForEach(workManager.nextWeekWorkTasks, id: \.objectID) { task in
                    WorkTaskCard(task: task, isCompact: true) {
                        selectedTask = task
                        showingProgressUpdate = true
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 统计卡片
struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - 工作任务卡片
struct WorkTaskCard: View {
    let task: TaskItem
    var isCompact: Bool = false
    let onProgressUpdate: () -> Void

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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // 工作标识
                Image(systemName: "briefcase.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text(task.title ?? "未知任务")
                    .font(isCompact ? .subheadline : .body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
                
                if task.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Button("更新") {
                        onProgressUpdate()
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                }
            }
            
            if !isCompact {
                // 进度条
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("进度: \(Int(task.workProgress))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        if task.timeSpent > 0 {
                            Text("⏱️ \(formatTimeSpent(task.timeSpent))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    ProgressView(value: task.workProgress, total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: task.isCompleted ? .green : .blue))
                        .scaleEffect(x: 1, y: 0.8)
                }
                
                if let lastUpdate = task.lastProgressUpdate {
                    Text("最后更新: \(formatLastUpdate(lastUpdate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                // 紧凑模式只显示进度百分比
                HStack {
                    Text("\(Int(task.workProgress))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if task.timeSpent > 0 {
                        Text("• \(formatTimeSpent(task.timeSpent))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(task.isCompleted ? Color.green.opacity(0.05) : Color(.systemGray6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(task.isCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    WorkCenterView()
}
