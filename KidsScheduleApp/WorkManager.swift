import SwiftUI
import CoreData
import UserNotifications

// MARK: - 工作数据模型
struct WorkDailyReport {
    let date: Date
    let workTasks: [TaskItem]
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
        guard !workTasks.isEmpty else { return 0 }
        return Double(completedTasks.count) / Double(workTasks.count) * 100
    }
}

struct WorkWeeklyOverview {
    let weekStart: Date
    let weekEnd: Date
    let allWorkTasks: [TaskItem]
    let totalTimeSpent: Double
    let averageProgress: Double
    let completedCount: Int
    let ongoingCount: Int
    
    var formattedWeekRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
    }
}

// MARK: - 工作管理器
class WorkManager: ObservableObject {
    static let shared = WorkManager()
    
    @Published var todayWorkTasks: [TaskItem] = []
    @Published var thisWeekWorkTasks: [TaskItem] = []
    @Published var nextWeekWorkTasks: [TaskItem] = []
    @Published var lastDailyReport: WorkDailyReport?
    @Published var weeklyOverview: WorkWeeklyOverview?
    
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
        }
    }
    
    private func loadTodayWorkTasks() {
        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "category == %@", "工作"),
            NSPredicate(format: "dueDate >= %@ AND dueDate < %@", today as NSDate, tomorrow as NSDate)
        ])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskItem.dueDate, ascending: true)]
        
        do {
            todayWorkTasks = try context.fetch(request)
            print("📊 加载今日工作任务: \(todayWorkTasks.count)个")
        } catch {
            print("❌ 加载今日工作任务失败: \(error)")
            todayWorkTasks = []
        }
    }
    
    private func loadThisWeekWorkTasks() {
        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let weekEnd = calendar.dateInterval(of: .weekOfYear, for: today)?.end ?? today
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "category == %@", "工作"),
            NSPredicate(format: "dueDate >= %@ AND dueDate < %@", weekStart as NSDate, weekEnd as NSDate)
        ])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskItem.dueDate, ascending: true)]
        
        do {
            thisWeekWorkTasks = try context.fetch(request)
            print("📈 加载本周工作任务: \(thisWeekWorkTasks.count)个")
        } catch {
            print("❌ 加载本周工作任务失败: \(error)")
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
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "category == %@", "工作"),
            NSPredicate(format: "dueDate >= %@ AND dueDate < %@", nextWeekStartOfWeek as NSDate, nextWeekEnd as NSDate)
        ])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskItem.dueDate, ascending: true)]
        
        do {
            nextWeekWorkTasks = try context.fetch(request)
            print("📋 加载下周工作任务: \(nextWeekWorkTasks.count)个")
        } catch {
            print("❌ 加载下周工作任务失败: \(error)")
            nextWeekWorkTasks = []
        }
    }
    
    // MARK: - 进度管理
    func updateTaskProgress(task: TaskItem, progress: Double, timeSpent: Double, notes: String) {
        task.setSafeWorkProgress(progress)
        task.setSafeTimeSpent(task.safeTimeSpent + timeSpent)
        task.setSafeProgressNotes(notes)
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
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "category == %@", "工作"),
            NSPredicate(format: "dueDate >= %@ AND dueDate < %@", startOfDay as NSDate, endOfDay as NSDate)
        ])
        
        do {
            let workTasks = try context.fetch(request)
            let completedTasks = workTasks.filter { $0.isCompleted }
            let ongoingTasks = workTasks.filter { !$0.isCompleted }
            let totalTimeSpent = workTasks.reduce(0) { $0 + $1.safeTimeSpent }
            let progressUpdates = workTasks.filter { $0.lastProgressUpdate != nil }.count
            
            let report = WorkDailyReport(
                date: date,
                workTasks: workTasks,
                totalTimeSpent: totalTimeSpent,
                completedTasks: completedTasks,
                ongoingTasks: ongoingTasks,
                progressUpdates: progressUpdates
            )
            
            lastDailyReport = report
            print("📊 生成每日工作报告: \(workTasks.count)个任务, \(String(format: "%.1f", totalTimeSpent))小时")
            return report
        } catch {
            print("❌ 生成每日报告失败: \(error)")
            return WorkDailyReport(date: date, workTasks: [], totalTimeSpent: 0, completedTasks: [], ongoingTasks: [], progressUpdates: 0)
        }
    }
    
    private func generateWeeklyOverview() {
        let calendar = Calendar.current
        let today = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else { return }
        
        let totalTimeSpent = thisWeekWorkTasks.reduce(0) { $0 + $1.safeTimeSpent }
        let averageProgress = thisWeekWorkTasks.isEmpty ? 0 : thisWeekWorkTasks.reduce(0) { $0 + $1.safeWorkProgress } / Double(thisWeekWorkTasks.count)
        let completedCount = thisWeekWorkTasks.filter { $0.isCompleted }.count
        let ongoingCount = thisWeekWorkTasks.filter { !$0.isCompleted }.count
        
        weeklyOverview = WorkWeeklyOverview(
            weekStart: weekInterval.start,
            weekEnd: weekInterval.end,
            allWorkTasks: thisWeekWorkTasks,
            totalTimeSpent: totalTimeSpent,
            averageProgress: averageProgress,
            completedCount: completedCount,
            ongoingCount: ongoingCount
        )
        
        print("📈 生成周度概览: \(thisWeekWorkTasks.count)个任务, 平均进度\(String(format: "%.1f", averageProgress))%")
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
        今日工作总结:
        • 涉及工作: \(report.workTasks.count)项
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


