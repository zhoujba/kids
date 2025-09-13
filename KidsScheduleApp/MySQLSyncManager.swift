import Foundation
import CoreData
import SwiftUI

enum MySQLSyncStatus: Equatable {
    case idle
    case syncing
    case success
    case failed(String)

    static func == (lhs: MySQLSyncStatus, rhs: MySQLSyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.syncing, .syncing), (.success, .success):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }

    var description: String {
        switch self {
        case .idle:
            return "空闲"
        case .syncing:
            return "同步中"
        case .success:
            return "同步成功"
        case .failed(let error):
            return "同步失败: \(error)"
        }
    }
}

@MainActor
class MySQLSyncManager: ObservableObject {
    static let shared = MySQLSyncManager()
    
    @Published var syncStatus: MySQLSyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var isAutoSyncEnabled = true
    
    private let mysqlManager = MySQLManager.shared
    private var syncTimer: Timer?
    
    private init() {
        // 延迟启动自动同步，等待configure调用
    }

    // MARK: - 配置方法

    func configure(with context: NSManagedObjectContext) {
        // 这里可以保存context引用，但目前我们使用PersistenceController.shared
        // 所以暂时不需要额外操作
    }

    func startSync() {
        startAutoSync()
    }
    
    // MARK: - 自动同步
    
    private func startAutoSync() {
        guard isAutoSyncEnabled else { return }
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performSync()
            }
        }
    }
    
    func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    // MARK: - 手动同步

    func manualSync() {
        Task {
            await performSync()
        }
    }

    func performSync() async {
        guard syncStatus != .syncing else { return }
        
        syncStatus = .syncing
        
        do {
            // 上传本地更改
            try await uploadLocalChanges()
            
            // 下载远程更改
            try await downloadRemoteChanges()
            
            syncStatus = .success
            lastSyncDate = Date()
            print("MySQL同步完成")
            
        } catch {
            syncStatus = .failed(error.localizedDescription)
            print("MySQL同步失败: \(error)")
        }
    }
    
    // MARK: - 上传本地更改
    
    private func uploadLocalChanges() async throws {
        let context = PersistenceController.shared.container.viewContext
        
        // 上传需要同步的任务
        try await uploadTasks(context: context)
        
        // 上传需要同步的番茄工作法会话
        try await uploadPomodoroSessions(context: context)
    }
    
    private func uploadTasks(context: NSManagedObjectContext) async throws {
        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == YES")
        
        let tasks = try context.fetch(request)
        var successCount = 0
        var failedTasks: [String] = []
        
        for task in tasks {
            let taskId = task.objectID.uriRepresentation().absoluteString
            
            let success = await mysqlManager.syncTask(task)
            
            if success {
                // 在主线程标记为已同步
                task.needsSync = false
                successCount += 1
                print("任务同步成功: \(task.title ?? "")")
            } else {
                failedTasks.append(taskId)
                print("任务同步失败: \(task.title ?? "")")
            }
        }
        
        if !failedTasks.isEmpty {
            let errorMessage = "部分任务同步失败: \(failedTasks.count)/\(tasks.count)"
            throw NSError(domain: "MySQLSyncError", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        print("所有任务同步成功: \(successCount)/\(tasks.count)")
        
        // 保存Core Data更改
        try context.save()
    }
    
    private func uploadPomodoroSessions(context: NSManagedObjectContext) async throws {
        let request: NSFetchRequest<PomodoroSession> = PomodoroSession.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == YES")
        
        let sessions = try context.fetch(request)
        var successCount = 0
        var failedSessions: [String] = []
        
        for session in sessions {
            let sessionId = session.objectID.uriRepresentation().absoluteString
            
            let success = await mysqlManager.syncPomodoroSession(session)
            
            if success {
                // 在主线程标记为已同步
                session.needsSync = false
                successCount += 1
                print("番茄工作法会话同步成功")
            } else {
                failedSessions.append(sessionId)
                print("番茄工作法会话同步失败")
            }
        }
        
        if !failedSessions.isEmpty {
            let errorMessage = "部分番茄工作法会话同步失败: \(failedSessions.count)/\(sessions.count)"
            throw NSError(domain: "MySQLSyncError", code: 2, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        print("所有番茄工作法会话同步成功: \(successCount)/\(sessions.count)")
        
        // 保存Core Data更改
        try context.save()
    }
    
    // MARK: - 下载远程更改
    
    private func downloadRemoteChanges() async throws {
        // 下载任务
        let remoteTasks = await mysqlManager.downloadTasks()
        try await updateLocalTasks(remoteTasks)
        
        // 下载番茄工作法会话
        let remoteSessions = await mysqlManager.downloadPomodoroSessions()
        try await updateLocalPomodoroSessions(remoteSessions)
    }
    
    private func updateLocalTasks(_ remoteTasks: [MySQLTaskData]) async throws {
        let context = PersistenceController.shared.container.viewContext
        
        for remoteTask in remoteTasks {
            // 检查本地是否已存在该任务
            let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
            request.predicate = NSPredicate(format: "title == %@ AND dueDate == %@", 
                                          remoteTask.title, 
                                          remoteTask.dueDate as CVarArg? ?? NSNull())
            request.fetchLimit = 1
            
            let existingTasks = try context.fetch(request)
            
            if existingTasks.isEmpty {
                // 创建新任务
                let newTask = TaskItem(context: context)
                newTask.title = remoteTask.title
                newTask.taskDescription = remoteTask.description
                newTask.dueDate = remoteTask.dueDate
                newTask.isCompleted = remoteTask.isCompleted
                newTask.needsSync = false // 从服务器下载的不需要再同步
                
                print("创建新任务: \(remoteTask.title)")
            } else {
                // 更新现有任务（如果远程版本更新）
                let existingTask = existingTasks[0]
                if existingTask.isCompleted != remoteTask.isCompleted {
                    existingTask.isCompleted = remoteTask.isCompleted
                    existingTask.needsSync = false
                    print("更新任务状态: \(remoteTask.title)")
                }
            }
        }
        
        try context.save()
    }
    
    private func updateLocalPomodoroSessions(_ remoteSessions: [MySQLPomodoroSessionData]) async throws {
        let context = PersistenceController.shared.container.viewContext
        
        for remoteSession in remoteSessions {
            // 检查本地是否已存在该会话
            let request: NSFetchRequest<PomodoroSession> = PomodoroSession.fetchRequest()
            request.predicate = NSPredicate(format: "startTime == %@ AND duration == %d", 
                                          remoteSession.startTime as CVarArg? ?? NSNull(),
                                          remoteSession.duration)
            request.fetchLimit = 1
            
            let existingSessions = try context.fetch(request)
            
            if existingSessions.isEmpty {
                // 创建新会话
                let newSession = PomodoroSession(context: context)
                newSession.totalDuration = Int32(remoteSession.duration)
                newSession.startTime = remoteSession.startTime
                newSession.endTime = remoteSession.endTime
                newSession.isActive = !remoteSession.isCompleted
                newSession.needsSync = false // 从服务器下载的不需要再同步
                
                // 如果有关联任务，尝试找到对应的本地任务
                if let taskId = remoteSession.taskId {
                    // 这里可以根据需要实现任务关联逻辑
                }
                
                print("创建新番茄工作法会话")
            }
        }
        
        try context.save()
    }
    
    // MARK: - 公共方法
    
    func markTaskForSync(_ task: TaskItem) {
        task.needsSync = true
        try? PersistenceController.shared.container.viewContext.save()
    }
    
    func markPomodoroSessionForSync(_ session: PomodoroSession) {
        session.needsSync = true
        try? PersistenceController.shared.container.viewContext.save()
    }
}
