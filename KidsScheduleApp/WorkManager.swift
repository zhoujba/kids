import SwiftUI
import CoreData
import UserNotifications

// MARK: - 日常活动数据模型
struct WorkDailyReport {
    let date: Date
    let allTasks: [TaskItem]  // 包含所有类型的任务
    let tasksByCategory: [String: [TaskItem]]  // 按类型分组的任务
    let totalTimeSpent: Double
    let completedTasks: [TaskItem]
    let ongoingTasks: [TaskItem]
    let progressUpdates: Int

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }

    var completionRate: Double {
        guard !allTasks.isEmpty else { return 0 }
        return Double(completedTasks.count) / Double(allTasks.count) * 100
    }

    // 获取特定类型的任务数量
    func taskCount(for category: String) -> Int {
        return tasksByCategory[category]?.count ?? 0
    }

    // 获取特定类型的完成率
    func completionRate(for category: String) -> Double {
        guard let tasks = tasksByCategory[category], !tasks.isEmpty else { return 0 }
        let completed = tasks.filter { $0.isCompleted }.count
        return Double(completed) / Double(tasks.count) * 100
    }
}

struct WorkWeeklyOverview {
    let weekStart: Date
    let weekEnd: Date
    let allTasks: [TaskItem]  // 包含所有类型的任务
    let tasksByCategory: [String: [TaskItem]]  // 按类型分组的任务
    let totalTimeSpent: Double
    let averageProgress: Double
    let completedCount: Int
    let ongoingCount: Int

    var formattedWeekRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
    }

    var completionRate: Double {
        guard !allTasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(allTasks.count) * 100
    }

    var averageTimePerTask: Double {
        guard !allTasks.isEmpty else { return 0 }
        return totalTimeSpent / Double(allTasks.count)
    }

    // 获取特定类型的任务统计
    func categoryStats(for category: String) -> (count: Int, completed: Int, timeSpent: Double) {
        guard let tasks = tasksByCategory[category] else { return (0, 0, 0) }
        let completed = tasks.filter { $0.isCompleted }.count
        let timeSpent = tasks.reduce(0) { $0 + $1.timeSpent }
        return (tasks.count, completed, timeSpent)
    }

    var productivityScore: Double {
        // 综合评分：完成率 * 0.6 + 平均进度 * 0.4
        return completionRate * 0.6 + averageProgress * 0.4
    }
}

// MARK: - 工作分析数据
struct WorkAnalytics {
    let weeklyTrend: [WeeklyData]
    let categoryBreakdown: [CategoryData]
    let productivityInsights: [String]
    let recommendations: [String]
}

struct WeeklyData {
    let weekStart: Date
    let tasksCompleted: Int
    let totalHours: Double
    let averageProgress: Double
}

struct CategoryData {
    let category: String
    let taskCount: Int
    let timeSpent: Double
    let completionRate: Double
}

// MARK: - 工作管理器
class WorkManager: ObservableObject {
    static let shared = WorkManager()

    // MARK: - 任务类型定义
    static let taskCategories = ["工作", "学习", "运动", "娱乐", "生活", "其他"]

    @Published var todayWorkTasks: [TaskItem] = []
    @Published var thisWeekWorkTasks: [TaskItem] = []
    @Published var nextWeekWorkTasks: [TaskItem] = []
    @Published var lastDailyReport: WorkDailyReport?
    @Published var weeklyOverview: WorkWeeklyOverview?
    @Published var workAnalytics: WorkAnalytics?
    
    private var context: NSManagedObjectContext {
        return PersistenceController.shared.container.viewContext
    }
    private var dailyReportTimer: Timer?
    
    private init() {
        setupDailyReportTimer()
        refreshWorkData()
    }
    
    // MARK: - 数据刷新
    func refreshWorkData() {
        DispatchQueue.main.async {
            self.loadTodayWorkTasks()
            self.loadThisWeekWorkTasks()
            self.loadNextWeekWorkTasks()
            self.generateWeeklyOverview()
            self.generateWorkAnalytics()
        }
    }
    
    private func loadTodayWorkTasks() {
        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        // 加载今日所有类型的任务
        request.predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@", today as NSDate, tomorrow as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskItem.dueDate, ascending: true)]

        do {
            todayWorkTasks = try context.fetch(request)
            print("📊 加载今日所有任务: \(todayWorkTasks.count)个")

            // 按类型统计
            let categoryStats = Dictionary(grouping: todayWorkTasks) { $0.category ?? "其他" }
            for (category, tasks) in categoryStats {
                print("   - \(category): \(tasks.count)个任务")
            }
        } catch {
            print("❌ 加载今日任务失败: \(error)")
            todayWorkTasks = []
        }
    }
    
    private func loadThisWeekWorkTasks() {
        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let weekEnd = calendar.dateInterval(of: .weekOfYear, for: today)?.end ?? today

        // 加载本周所有类型的任务
        request.predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@", weekStart as NSDate, weekEnd as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskItem.dueDate, ascending: true)]

        do {
            thisWeekWorkTasks = try context.fetch(request)
            print("📈 加载本周所有任务: \(thisWeekWorkTasks.count)个")
        } catch {
            print("❌ 加载本周任务失败: \(error)")
            thisWeekWorkTasks = []
        }
    }
    
    private func loadNextWeekWorkTasks() {
        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        let calendar = Calendar.current
        let today = Date()
        let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: today)!
        let nextWeekStartOfWeek = calendar.dateInterval(of: .weekOfYear, for: nextWeekStart)?.start ?? nextWeekStart
        let nextWeekEnd = calendar.dateInterval(of: .weekOfYear, for: nextWeekStart)?.end ?? nextWeekStart

        // 加载下周所有类型的任务
        request.predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@", nextWeekStartOfWeek as NSDate, nextWeekEnd as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskItem.dueDate, ascending: true)]

        do {
            nextWeekWorkTasks = try context.fetch(request)
            print("📋 加载下周所有任务: \(nextWeekWorkTasks.count)个")
        } catch {
            print("❌ 加载下周任务失败: \(error)")
            nextWeekWorkTasks = []
        }
    }
    
    // MARK: - 进度管理
    func updateTaskProgress(task: TaskItem, progress: Double, timeSpent: Double, notes: String) {
        task.workProgress = progress
        task.timeSpent = task.timeSpent + timeSpent
        task.progressNotes = notes
        task.lastProgressUpdate = Date()
        task.lastModified = Date()
        
        do {
            try context.save()
            print("✅ 更新工作进度: \(task.title ?? "未知任务") - \(Int(progress))%")
            
            // 刷新数据
            refreshWorkData()
            
            // 发送WebSocket更新
            Task {
                await WebSocketManager.shared.sendTaskUpdate(task)
            }
        } catch {
            print("❌ 保存工作进度失败: \(error)")
        }
    }
    
    // MARK: - 报告生成
    func generateDailyReport(for date: Date = Date()) -> WorkDailyReport {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        // 获取当日所有类型的任务
        request.predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@", startOfDay as NSDate, endOfDay as NSDate)

        do {
            let allTasks = try context.fetch(request)
            let completedTasks = allTasks.filter { $0.isCompleted }
            let ongoingTasks = allTasks.filter { !$0.isCompleted }
            let totalTimeSpent = allTasks.reduce(0) { $0 + $1.safeTimeSpent }
            let progressUpdates = allTasks.filter { $0.lastProgressUpdate != nil }.count

            // 按类型分组任务
            let tasksByCategory = Dictionary(grouping: allTasks) { $0.category ?? "其他" }

            let report = WorkDailyReport(
                date: date,
                allTasks: allTasks,
                tasksByCategory: tasksByCategory,
                totalTimeSpent: totalTimeSpent,
                completedTasks: completedTasks,
                ongoingTasks: ongoingTasks,
                progressUpdates: progressUpdates
            )
            
            lastDailyReport = report
            print("📊 生成日报: \(allTasks.count)个任务, 完成\(completedTasks.count)个")

            // 按类型统计
            for (category, tasks) in tasksByCategory {
                let completed = tasks.filter { $0.isCompleted }.count
                print("   - \(category): \(tasks.count)个任务, 完成\(completed)个")
            }

            return report
        } catch {
            print("❌ 生成日报失败: \(error)")
            return WorkDailyReport(date: date, allTasks: [], tasksByCategory: [:], totalTimeSpent: 0, completedTasks: [], ongoingTasks: [], progressUpdates: 0)
        }
    }
    
    private func generateWeeklyOverview() {
        let calendar = Calendar.current
        let today = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else { return }

        let totalTimeSpent = thisWeekWorkTasks.reduce(0) { $0 + $1.timeSpent }
        let averageProgress = thisWeekWorkTasks.isEmpty ? 0 : thisWeekWorkTasks.reduce(0) { $0 + $1.workProgress } / Double(thisWeekWorkTasks.count)
        let completedCount = thisWeekWorkTasks.filter { $0.isCompleted }.count
        let ongoingCount = thisWeekWorkTasks.filter { !$0.isCompleted }.count

        // 按类型分组任务
        let tasksByCategory = Dictionary(grouping: thisWeekWorkTasks) { $0.category ?? "其他" }

        weeklyOverview = WorkWeeklyOverview(
            weekStart: weekInterval.start,
            weekEnd: weekInterval.end,
            allTasks: thisWeekWorkTasks,
            tasksByCategory: tasksByCategory,
            totalTimeSpent: totalTimeSpent,
            averageProgress: averageProgress,
            completedCount: completedCount,
            ongoingCount: ongoingCount
        )

        print("📈 生成周度概览: \(thisWeekWorkTasks.count)个任务, 平均进度\(String(format: "%.1f", averageProgress))%")
    }

    // MARK: - 工作分析
    private func generateWorkAnalytics() {
        let weeklyTrend = generateWeeklyTrend()
        let categoryBreakdown = generateCategoryBreakdown()
        let insights = generateProductivityInsights()
        let recommendations = generateRecommendations()

        workAnalytics = WorkAnalytics(
            weeklyTrend: weeklyTrend,
            categoryBreakdown: categoryBreakdown,
            productivityInsights: insights,
            recommendations: recommendations
        )

        print("📊 生成工作分析数据: \(weeklyTrend.count)周趋势, \(categoryBreakdown.count)个分类")
    }

    private func generateWeeklyTrend() -> [WeeklyData] {
        let calendar = Calendar.current
        let today = Date()
        var weeklyData: [WeeklyData] = []

        // 生成过去4周的数据
        for weekOffset in 0..<4 {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today),
                  let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else { continue }

            let weekTasks = getWorkTasksForWeek(weekInterval)
            let completedTasks = weekTasks.filter { $0.isCompleted }.count
            let totalHours = weekTasks.reduce(0) { $0 + $1.timeSpent }
            let avgProgress = weekTasks.isEmpty ? 0 : weekTasks.reduce(0) { $0 + $1.workProgress } / Double(weekTasks.count)

            weeklyData.append(WeeklyData(
                weekStart: weekInterval.start,
                tasksCompleted: completedTasks,
                totalHours: totalHours,
                averageProgress: avgProgress
            ))
        }

        return weeklyData.reversed() // 按时间顺序排列
    }

    private func generateCategoryBreakdown() -> [CategoryData] {
        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        let calendar = Calendar.current
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()

        request.predicate = NSPredicate(format: "dueDate >= %@", oneMonthAgo as NSDate)

        do {
            let allTasks = try context.fetch(request)
            let groupedTasks = Dictionary(grouping: allTasks) { $0.category ?? "未分类" }

            return groupedTasks.map { category, tasks in
                // 统计该类型的所有任务，不再只限制工作类型
                let completedCount = tasks.filter { $0.isCompleted }.count
                let totalTime = tasks.reduce(0) { $0 + $1.timeSpent }
                let completionRate = tasks.isEmpty ? 0 : Double(completedCount) / Double(tasks.count) * 100

                return CategoryData(
                    category: category,
                    taskCount: tasks.count,
                    timeSpent: totalTime,
                    completionRate: completionRate
                )
            }.filter { $0.taskCount > 0 }
        } catch {
            print("❌ 获取分类数据失败: \(error)")
            return []
        }
    }

    private func generateProductivityInsights() -> [String] {
        var insights: [String] = []

        guard let overview = weeklyOverview else { return insights }

        // 完成率分析
        if overview.completionRate >= 80 {
            insights.append("🎉 本周完成率达到\(String(format: "%.1f", overview.completionRate))%，表现优秀！")
        } else if overview.completionRate >= 60 {
            insights.append("👍 本周完成率\(String(format: "%.1f", overview.completionRate))%，还有提升空间")
        } else {
            insights.append("⚠️ 本周完成率\(String(format: "%.1f", overview.completionRate))%，需要关注任务管理")
        }

        // 时间投入分析
        if overview.totalTimeSpent >= 40 {
            insights.append("💪 本周工作时间\(String(format: "%.1f", overview.totalTimeSpent))小时，投入充足")
        } else if overview.totalTimeSpent >= 20 {
            insights.append("⏰ 本周工作时间\(String(format: "%.1f", overview.totalTimeSpent))小时，可适当增加")
        } else {
            insights.append("📈 本周工作时间\(String(format: "%.1f", overview.totalTimeSpent))小时，建议增加投入")
        }

        // 平均进度分析
        if overview.averageProgress >= 80 {
            insights.append("🚀 任务平均进度\(String(format: "%.1f", overview.averageProgress))%，执行力强")
        } else if overview.averageProgress >= 50 {
            insights.append("📊 任务平均进度\(String(format: "%.1f", overview.averageProgress))%，稳步推进")
        } else {
            insights.append("🎯 任务平均进度\(String(format: "%.1f", overview.averageProgress))%，需要加快节奏")
        }

        return insights
    }

    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []

        guard let overview = weeklyOverview else { return recommendations }

        // 基于完成率的建议
        if overview.completionRate < 60 {
            recommendations.append("建议将大任务分解为小任务，提高完成率")
            recommendations.append("设置每日工作目标，保持稳定的工作节奏")
        }

        // 基于时间投入的建议
        if overview.averageTimePerTask < 2 {
            recommendations.append("任务时间投入较少，可以考虑增加深度工作时间")
        } else if overview.averageTimePerTask > 8 {
            recommendations.append("单个任务时间过长，建议拆分为更小的子任务")
        }

        // 基于进度的建议
        if overview.averageProgress < 50 {
            recommendations.append("定期更新任务进度，保持工作可视化")
            recommendations.append("使用番茄工作法，提高专注度和执行效率")
        }

        // 通用建议
        recommendations.append("每日18:00查看工作汇报，及时调整工作计划")
        recommendations.append("利用工作中心功能，统一管理所有工作任务")

        return recommendations
    }

    private func getWorkTasksForWeek(_ weekInterval: DateInterval) -> [TaskItem] {
        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        // 获取该周所有类型的任务
        request.predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@",
                                      weekInterval.start as NSDate,
                                      weekInterval.end as NSDate)

        do {
            return try context.fetch(request)
        } catch {
            print("❌ 获取周度任务失败: \(error)")
            return []
        }
    }

    // MARK: - 自动汇报
    private func setupDailyReportTimer() {
        // 计算下一个18:00的时间
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 18
        components.minute = 0
        components.second = 0
        
        var targetDate = calendar.date(from: components) ?? now
        
        // 如果今天的18:00已经过了，设置为明天的18:00
        if targetDate <= now {
            targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate) ?? now
        }
        
        let timeInterval = targetDate.timeIntervalSince(now)
        print("⏰ 设置每日18:00汇报，下次触发时间: \(targetDate)")
        
        dailyReportTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
            self.triggerDailyReport()
            self.setupDailyReportTimer() // 重新设置明天的定时器
        }
    }
    
    private func triggerDailyReport() {
        print("🕕 18:00 自动生成每日工作报告")
        let report = generateDailyReport()
        
        // 发送本地通知
        sendDailyReportNotification(report: report)
    }
    
    private func sendDailyReportNotification(report: WorkDailyReport) {
        let content = UNMutableNotificationContent()
        content.title = "📊 每日工作汇报"
        content.body = """
        今日活动总结:
        • 涉及任务: \(report.allTasks.count)项
        • 已完成: \(report.completedTasks.count)项
        • 进行中: \(report.ongoingTasks.count)项
        • 时间投入: \(String(format: "%.1f", report.totalTimeSpent))小时
        • 完成率: \(String(format: "%.1f", report.completionRate))%
        """
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "daily_work_report_\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 发送每日报告通知失败: \(error)")
            } else {
                print("✅ 每日工作报告通知已发送")
            }
        }
    }
    
    deinit {
        dailyReportTimer?.invalidate()
    }
}


