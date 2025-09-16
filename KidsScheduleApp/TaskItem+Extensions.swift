import Foundation
import CoreData

// MARK: - TaskItem 安全访问扩展
extension TaskItem {
    
    // MARK: - 工作进度安全访问
    var safeWorkProgress: Double {
        get {
            return self.workProgress
        }
    }
    
    func setSafeWorkProgress(_ value: Double) {
        self.workProgress = value
        self.lastProgressUpdate = Date()
    }
    
    // MARK: - 时间投入安全访问
    var safeTimeSpent: Double {
        get {
            return self.timeSpent
        }
    }
    
    func setSafeTimeSpent(_ value: Double) {
        self.timeSpent = value
        self.lastProgressUpdate = Date()
    }
    
    // MARK: - 进度备注安全访问
    var safeProgressNotes: String? {
        get {
            return self.progressNotes
        }
    }
    
    func setSafeProgressNotes(_ value: String?) {
        self.progressNotes = value
        self.lastProgressUpdate = Date()
    }
    
    // MARK: - 工作进度格式化
    var formattedWorkProgress: String {
        return String(format: "%.0f%%", safeWorkProgress)
    }

    var progressPercentage: Int {
        return Int(safeWorkProgress)
    }
    
    var formattedTimeSpent: String {
        let hours = Int(safeTimeSpent)
        let minutes = Int((safeTimeSpent - Double(hours)) * 60)
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    // MARK: - 工作状态判断
    var isWorkTask: Bool {
        return self.category == "工作"
    }
    
    var workProgressLevel: WorkProgressLevel {
        let progress = safeWorkProgress
        switch progress {
        case 0:
            return .notStarted
        case 0.1..<50:
            return .inProgress
        case 50..<90:
            return .nearCompletion
        case 90..<100:
            return .almostDone
        case 100:
            return .completed
        default:
            return .inProgress
        }
    }
    
    // MARK: - 今日工作判断
    var isToday: Bool {
        guard let dueDate = self.dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
    
    var isThisWeek: Bool {
        guard let dueDate = self.dueDate else { return false }
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
        return dueDate >= startOfWeek && dueDate <= endOfWeek
    }
    
    // MARK: - 工作汇报数据
    var workReportData: WorkReportData {
        return WorkReportData(
            title: self.title ?? "未命名任务",
            progress: safeWorkProgress,
            timeSpent: safeTimeSpent,
            notes: safeProgressNotes,
            isCompleted: self.isCompleted,
            dueDate: self.dueDate
        )
    }
}

// MARK: - 工作进度级别枚举
enum WorkProgressLevel {
    case notStarted
    case inProgress
    case nearCompletion
    case almostDone
    case completed
    
    var description: String {
        switch self {
        case .notStarted:
            return "未开始"
        case .inProgress:
            return "进行中"
        case .nearCompletion:
            return "接近完成"
        case .almostDone:
            return "即将完成"
        case .completed:
            return "已完成"
        }
    }
    
    var color: String {
        switch self {
        case .notStarted:
            return "gray"
        case .inProgress:
            return "blue"
        case .nearCompletion:
            return "orange"
        case .almostDone:
            return "yellow"
        case .completed:
            return "green"
        }
    }
}

// MARK: - 工作汇报数据结构
struct WorkReportData {
    let title: String
    let progress: Double
    let timeSpent: Double
    let notes: String?
    let isCompleted: Bool
    let dueDate: Date?
    
    var formattedProgress: String {
        return String(format: "%.0f%%", progress)
    }
    
    var formattedTimeSpent: String {
        let hours = Int(timeSpent)
        let minutes = Int((timeSpent - Double(hours)) * 60)
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}
