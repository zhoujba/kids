import Foundation
import CoreData

// MARK: - Notification Names
extension Notification.Name {
    static let taskDataUpdated = Notification.Name("taskDataUpdated")
}

// WebSocket消息类型
struct WSMessage: Codable {
    let type: String
    let data: AnyCodable?
}

// 用于处理任意类型的数据
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([TaskData].self) {
            value = array
        } else if let taskData = try? container.decode(TaskData.self) {
            value = taskData
        } else {
            // 如果直接解析TaskData失败，尝试先解析为字典再转换
            do {
                let jsonData = try container.decode(Data.self)
                let taskData = try JSONDecoder().decode(TaskData.self, from: jsonData)
                value = taskData
            } catch {
                print("⚠️ AnyCodable解析失败: \(error)")
                value = "unknown"
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let string = value as? String {
            try container.encode(string)
        } else if let array = value as? [TaskData] {
            try container.encode(array)
        } else if let taskData = value as? TaskData {
            try container.encode(taskData)
        }
    }
}

struct TaskData: Codable {
    let id: Int?  // 允许为空，因为新创建的任务可能没有ID
    let userId: String
    let title: String
    let description: String?
    let dueDate: String?
    let isCompleted: Bool
    let category: String?
    let priority: Int?
    let deviceId: String
    let recordId: String?
    let createdAt: String?  // 允许为空
    let updatedAt: String?  // 允许为空
    let workProgress: Double?  // 工作进度 (0-100)
    let timeSpent: Double?     // 时间投入 (小时)
    let progressNotes: String? // 进度说明

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case dueDate = "due_date"
        case isCompleted = "is_completed"
        case category
        case priority
        case deviceId = "device_id"
        case recordId = "record_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case workProgress = "work_progress"
        case timeSpent = "time_spent"
        case progressNotes = "progress_notes"
    }
}

@MainActor
class WebSocketManager: NSObject, ObservableObject {
    static let shared = WebSocketManager()

    @Published var isConnected = false
    @Published var connectionStatus = "未连接"
    @Published var lastUpdateTime = Date() // 用于触发UI刷新

    // Core Data 引用
    private var persistenceController: PersistenceController {
        return PersistenceController.shared
    }
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let baseURL = "ws://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/ws"
    
    private override init() {
        super.init()
        // 自动连接WebSocket
        connect()
    }
    
    // MARK: - 连接管理
    
    func connect() {
        guard let url = URL(string: baseURL) else {
            print("❌ WebSocket URL无效")
            return
        }
        
        let urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession.webSocketTask(with: url)
        
        webSocketTask?.resume()
        
        connectionStatus = "连接中..."
        print("🔄 WebSocket连接中...")
        
        // 开始接收消息
        receiveMessage()
        
        // 发送ping来测试连接
        sendPing()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        connectionStatus = "已断开"
        print("🔌 WebSocket已断开")
    }
    
    // MARK: - 消息处理
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                Task { @MainActor in
                    await self?.handleMessage(message)
                    self?.receiveMessage() // 继续接收下一条消息
                }
                
            case .failure(let error):
                Task { @MainActor in
                    print("❌ WebSocket接收消息失败: \(error)")
                    self?.isConnected = false
                    self?.connectionStatus = "连接失败"
                    
                    // 尝试重连
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self?.connect()
                    }
                }
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) async {
        switch message {
        case .string(let text):
            print("📨 收到WebSocket消息: \(text)")
            await processTextMessage(text)
            
        case .data(let data):
            print("📨 收到WebSocket数据: \(data)")
            
        @unknown default:
            print("❓ 未知WebSocket消息类型")
        }
    }
    
    private func processTextMessage(_ text: String) async {
        guard text.data(using: .utf8) != nil else { return }
        
        do {
            // 直接解析消息类型，不解析data字段
            if let jsonData = text.data(using: .utf8) {
                let fullMessage = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
                guard let messageType = fullMessage?["type"] as? String else {
                    print("❌ 无法获取消息类型")
                    return
                }

                print("📨 处理消息类型: \(messageType)")

                switch messageType {
            case "tasks_sync":
                print("🔍 处理tasks_sync消息")
                // fullMessage已经在上面解析了
                if let dataArray = fullMessage?["data"] as? [[String: Any]] {
                            print("🔍 获取到data数组，任务数量: \(dataArray.count)")

                            // 手动构建TaskData数组
                            var taskDataArray: [TaskData] = []
                            for dataDict in dataArray {
                                let taskData = TaskData(
                                    id: dataDict["id"] as? Int,
                                    userId: dataDict["user_id"] as? String ?? "",
                                    title: dataDict["title"] as? String ?? "",
                                    description: dataDict["description"] as? String,
                                    dueDate: dataDict["due_date"] as? String,
                                    isCompleted: dataDict["is_completed"] as? Bool ?? false,
                                    category: dataDict["category"] as? String,
                                    priority: dataDict["priority"] as? Int,
                                    deviceId: dataDict["device_id"] as? String ?? "",
                                    recordId: dataDict["record_id"] as? String,
                                    createdAt: dataDict["created_at"] as? String,
                                    updatedAt: dataDict["updated_at"] as? String,
                                    workProgress: dataDict["work_progress"] as? Double ?? 0,
                                    timeSpent: dataDict["time_spent"] as? Double ?? 0,
                                    progressNotes: dataDict["progress_notes"] as? String
                                )
                                taskDataArray.append(taskData)
                            }

                    print("✅ 手动构建TaskData数组成功，任务数量: \(taskDataArray.count)")
                    await syncTasksFromWebSocket(taskDataArray)
                } else {
                    print("❌ 无法获取data数组")
                }

            case "task_created":
                print("🔍 处理task_created消息")
                // fullMessage已经在上面解析了
                if let dataDict = fullMessage?["data"] as? [String: Any] {
                            print("🔍 获取到data字典: \(dataDict.keys)")

                            // 手动构建TaskData对象
                            let taskData = TaskData(
                                id: dataDict["id"] as? Int,
                                userId: dataDict["user_id"] as? String ?? "",
                                title: dataDict["title"] as? String ?? "",
                                description: dataDict["description"] as? String,
                                dueDate: dataDict["due_date"] as? String,
                                isCompleted: dataDict["is_completed"] as? Bool ?? false,
                                category: dataDict["category"] as? String,
                                priority: dataDict["priority"] as? Int,
                                deviceId: dataDict["device_id"] as? String ?? "",
                                recordId: dataDict["record_id"] as? String,
                                createdAt: dataDict["created_at"] as? String,
                                updatedAt: dataDict["updated_at"] as? String,
                                workProgress: dataDict["work_progress"] as? Double ?? 0,
                                timeSpent: dataDict["time_spent"] as? Double ?? 0,
                                progressNotes: dataDict["progress_notes"] as? String
                            )

                    print("✅ 手动构建TaskData成功: \(taskData.title), category: \(taskData.category ?? "nil"), priority: \(taskData.priority ?? 0)")
                    await handleTaskCreated(taskData)
                } else {
                    print("❌ 无法获取data字典")
                }

            case "task_updated":
                print("🔍 处理task_updated消息")
                // fullMessage已经在上面解析了
                if let dataDict = fullMessage?["data"] as? [String: Any] {
                            let taskData = TaskData(
                                id: dataDict["id"] as? Int,
                                userId: dataDict["user_id"] as? String ?? "",
                                title: dataDict["title"] as? String ?? "",
                                description: dataDict["description"] as? String,
                                dueDate: dataDict["due_date"] as? String,
                                isCompleted: dataDict["is_completed"] as? Bool ?? false,
                                category: dataDict["category"] as? String,
                                priority: dataDict["priority"] as? Int,
                                deviceId: dataDict["device_id"] as? String ?? "",
                                recordId: dataDict["record_id"] as? String,
                                createdAt: dataDict["created_at"] as? String,
                                updatedAt: dataDict["updated_at"] as? String,
                                workProgress: dataDict["work_progress"] as? Double ?? 0,
                                timeSpent: dataDict["time_spent"] as? Double ?? 0,
                                progressNotes: dataDict["progress_notes"] as? String
                            )

                    print("✅ 手动构建TaskData成功: \(taskData.title), category: \(taskData.category ?? "nil"), priority: \(taskData.priority ?? 0)")
                    await handleTaskUpdated(taskData)
                } else {
                    print("❌ 无法获取data字典")
                }

            case "task_deleted":
                print("🔍 处理task_deleted消息")
                // fullMessage已经在上面解析了
                if let dataDict = fullMessage?["data"] as? [String: Any] {
                            let taskData = TaskData(
                                id: dataDict["id"] as? Int,
                                userId: dataDict["user_id"] as? String ?? "",
                                title: dataDict["title"] as? String ?? "",
                                description: dataDict["description"] as? String,
                                dueDate: dataDict["due_date"] as? String,
                                isCompleted: dataDict["is_completed"] as? Bool ?? false,
                                category: dataDict["category"] as? String,
                                priority: dataDict["priority"] as? Int,
                                deviceId: dataDict["device_id"] as? String ?? "",
                                recordId: dataDict["record_id"] as? String,
                                createdAt: dataDict["created_at"] as? String,
                                updatedAt: dataDict["updated_at"] as? String,
                                workProgress: dataDict["work_progress"] as? Double ?? 0,
                                timeSpent: dataDict["time_spent"] as? Double ?? 0,
                                progressNotes: dataDict["progress_notes"] as? String
                            )

                    print("✅ 手动构建TaskData成功: \(taskData.title), category: \(taskData.category ?? "nil"), priority: \(taskData.priority ?? 0)")
                    await handleTaskDeleted(taskData)
                } else {
                    print("❌ 无法获取data字典")
                }

            case "pong":
                isConnected = true
                connectionStatus = "已连接"
                print("✅ WebSocket连接正常")

            default:
                print("❓ 未知消息类型: \(messageType)")
            }
            } else {
                print("❌ 无法解析JSON消息")
            }
            
        } catch {
            print("❌ 解析WebSocket消息失败: \(error)")
        }
    }
    
    // MARK: - 任务同步处理

    private func syncTasksFromWebSocket(_ taskDataArray: [TaskData]) async {
        let context = persistenceController.container.viewContext

        print("🔄 通过WebSocket初始化同步 \(taskDataArray.count) 个任务")

        for taskData in taskDataArray {
            // 检查本地是否已存在该任务
            let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()

            // 优先使用recordId匹配，其次使用title+deviceId
            var predicates: [NSPredicate] = []
            if let recordId = taskData.recordId, !recordId.isEmpty {
                predicates.append(NSPredicate(format: "recordID == %@", recordId))
            } else {
                predicates.append(NSPredicate(format: "title == %@ AND deviceId == %@",
                                            taskData.title, taskData.deviceId))
            }

            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.fetchLimit = 1

            do {
                let existingTasks = try context.fetch(request)

                if let existingTask = existingTasks.first {
                    // 更新现有任务
                    var hasChanges = false

                    if existingTask.title != taskData.title {
                        existingTask.title = taskData.title
                        hasChanges = true
                    }

                    if existingTask.taskDescription != taskData.description {
                        existingTask.taskDescription = taskData.description
                        hasChanges = true
                    }

                    if existingTask.isCompleted != taskData.isCompleted {
                        existingTask.isCompleted = taskData.isCompleted
                        hasChanges = true
                    }

                    // 解析日期
                    if let dueDateString = taskData.dueDate, !dueDateString.isEmpty {
                        let dueDate = parseDate(from: dueDateString)
                        if existingTask.dueDate != dueDate {
                            existingTask.dueDate = dueDate
                            hasChanges = true
                        }
                    }

                    if hasChanges {
                        existingTask.needsSync = false // 来自WebSocket的不需要再同步
                        existingTask.lastModified = Date()
                        print("✏️ 更新现有任务: \(taskData.title)")
                    }
                } else {
                    // 创建新任务
                    let newTask = TaskItem(context: context)
                    newTask.title = taskData.title
                    newTask.taskDescription = taskData.description
                    newTask.isCompleted = taskData.isCompleted
                    newTask.deviceId = taskData.deviceId
                    newTask.recordID = taskData.recordId ?? UUID().uuidString
                    newTask.needsSync = false // 来自WebSocket的不需要再同步
                    newTask.createdDate = Date()
                    newTask.lastModified = Date()

                    // 解析日期
                    if let dueDateString = taskData.dueDate, !dueDateString.isEmpty {
                        newTask.dueDate = parseDate(from: dueDateString)
                    }

                    print("➕ 创建新任务: \(taskData.title)")
                }
            } catch {
                print("❌ WebSocket同步任务失败: \(error)")
            }
        }

        // 保存所有更改
        do {
            try context.save()
            print("✅ WebSocket初始化同步完成")
        } catch {
            print("❌ 保存WebSocket同步数据失败: \(error)")
        }
    }
    
    private func handleTaskCreated(_ taskData: TaskData) async {
        print("➕ 收到新任务创建通知: \(taskData.title)")
        // 在本地创建任务
        await createLocalTask(from: taskData)
    }

    private func handleTaskUpdated(_ taskData: TaskData) async {
        print("✏️ 收到任务更新通知: \(taskData.title)")
        // 更新本地任务
        await updateLocalTask(from: taskData)
    }

    private func handleTaskDeleted(_ taskData: TaskData) async {
        print("🗑️ 收到任务删除通知: \(taskData.title)")
        // 删除本地任务
        await deleteLocalTask(from: taskData)
    }
    
    // MARK: - 本地任务操作
    
    private func createLocalTask(from taskData: TaskData) async {
        await MainActor.run {
            let context = persistenceController.container.viewContext

            // 检查是否已存在（避免重复创建）
            let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()

            // 优先使用recordId匹配，其次使用title+deviceId
            var predicates: [NSPredicate] = []
            if let recordId = taskData.recordId, !recordId.isEmpty {
                predicates.append(NSPredicate(format: "recordID == %@", recordId))
            } else {
                predicates.append(NSPredicate(format: "title == %@ AND deviceId == %@",
                                            taskData.title, taskData.deviceId))
            }

            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.fetchLimit = 1

            do {
                let existingTasks = try context.fetch(request)
                if existingTasks.isEmpty {
                    let newTask = TaskItem(context: context)
                    newTask.title = taskData.title
                    newTask.taskDescription = taskData.description
                    newTask.isCompleted = taskData.isCompleted
                    newTask.category = taskData.category ?? "学习"
                    newTask.priority = Int16(taskData.priority ?? 1)
                    newTask.deviceId = taskData.deviceId
                    newTask.recordID = taskData.recordId ?? UUID().uuidString
                    newTask.needsSync = false // 来自WebSocket的不需要再同步
                    newTask.createdDate = Date()
                    newTask.lastModified = Date()

                    // 设置工作进度字段
                    newTask.workProgress = taskData.workProgress ?? 0
                    newTask.timeSpent = taskData.timeSpent ?? 0
                    newTask.progressNotes = taskData.progressNotes
                    newTask.lastProgressUpdate = Date()

                    // 解析日期
                    if let dueDateString = taskData.dueDate, !dueDateString.isEmpty {
                        newTask.dueDate = parseDate(from: dueDateString)
                    }

                    try context.save()
                    print("✅ 通过WebSocket创建本地任务: \(taskData.title)")

                    // 触发UI刷新
                    self.lastUpdateTime = Date()

                    // 发送通知
                    NotificationCenter.default.post(name: .taskDataUpdated, object: nil)
                } else {
                    print("ℹ️ 任务已存在，跳过创建: \(taskData.title)")
                }
            } catch {
                print("❌ WebSocket创建本地任务失败: \(error)")
            }
        }
    }
    
    private func updateLocalTask(from taskData: TaskData) async {
        await MainActor.run {
            let context = persistenceController.container.viewContext

            let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()

            // 优先使用recordId匹配，其次使用title+deviceId
            var predicates: [NSPredicate] = []
            if let recordId = taskData.recordId, !recordId.isEmpty {
                predicates.append(NSPredicate(format: "recordID == %@", recordId))
            } else {
                predicates.append(NSPredicate(format: "title == %@ AND deviceId == %@",
                                            taskData.title, taskData.deviceId))
            }

            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.fetchLimit = 1

            do {
                let tasks = try context.fetch(request)
                if let task = tasks.first {
                    var hasChanges = false

                    if task.title != taskData.title {
                        task.title = taskData.title
                        hasChanges = true
                    }

                    if task.taskDescription != taskData.description {
                        task.taskDescription = taskData.description
                        hasChanges = true
                    }

                    if task.isCompleted != taskData.isCompleted {
                        task.isCompleted = taskData.isCompleted
                        hasChanges = true
                    }

                    if task.category != taskData.category {
                        task.category = taskData.category ?? "学习"
                        hasChanges = true
                    }

                    if task.priority != Int16(taskData.priority ?? 1) {
                        task.priority = Int16(taskData.priority ?? 1)
                        hasChanges = true
                    }

                    // 更新工作进度字段
                    if let workProgress = taskData.workProgress, task.workProgress != workProgress {
                        task.workProgress = workProgress
                        task.lastProgressUpdate = Date()
                        hasChanges = true
                    }

                    if let timeSpent = taskData.timeSpent, task.timeSpent != timeSpent {
                        task.timeSpent = timeSpent
                        task.lastProgressUpdate = Date()
                        hasChanges = true
                    }

                    if task.progressNotes != taskData.progressNotes {
                        task.progressNotes = taskData.progressNotes
                        task.lastProgressUpdate = Date()
                        hasChanges = true
                    }

                    // 解析日期
                    if let dueDateString = taskData.dueDate, !dueDateString.isEmpty {
                        let dueDate = parseDate(from: dueDateString)
                        if task.dueDate != dueDate {
                            task.dueDate = dueDate
                            hasChanges = true
                        }
                    }

                    if hasChanges {
                        task.needsSync = false // 来自WebSocket的不需要再同步
                        task.lastModified = Date()

                        try context.save()
                        print("✅ 通过WebSocket更新本地任务: \(taskData.title)")

                        // 触发UI刷新
                        self.lastUpdateTime = Date()

                        // 发送通知
                        NotificationCenter.default.post(name: .taskDataUpdated, object: nil)
                    } else {
                        print("ℹ️ 任务无变化，跳过更新: \(taskData.title)")
                    }
                } else {
                    print("⚠️ 未找到要更新的任务: \(taskData.title)")
                }
            } catch {
                print("❌ WebSocket更新本地任务失败: \(error)")
            }
        }
    }
    
    private func deleteLocalTask(from taskData: TaskData) async {
        await MainActor.run {
            let context = persistenceController.container.viewContext

            let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()

            // 优先使用recordId匹配，其次使用title+deviceId
            var predicates: [NSPredicate] = []
            if let recordId = taskData.recordId, !recordId.isEmpty {
                predicates.append(NSPredicate(format: "recordID == %@", recordId))
            } else {
                predicates.append(NSPredicate(format: "title == %@ AND deviceId == %@",
                                            taskData.title, taskData.deviceId))
            }

            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.fetchLimit = 1

            do {
                let tasks = try context.fetch(request)
                if let task = tasks.first {
                    context.delete(task)
                    try context.save()
                    print("✅ 通过WebSocket删除本地任务: \(taskData.title)")

                    // 触发UI刷新
                    self.lastUpdateTime = Date()

                    // 发送通知
                    NotificationCenter.default.post(name: .taskDataUpdated, object: nil)
                } else {
                    print("⚠️ 未找到要删除的任务: \(taskData.title)")
                }
            } catch {
                print("❌ WebSocket删除本地任务失败: \(error)")
            }
        }
    }
    
    // MARK: - 发送消息
    
    private func sendPing() {
        let pingMessage = WSMessage(type: "ping", data: nil)
        sendMessage(pingMessage)
    }

    // 公共方法供UI调用
    func testConnection() {
        let pingMessage = WSMessage(type: "ping", data: nil)
        sendMessage(pingMessage)
    }

    // 清除所有本地任务数据
    func clearAllLocalTasks() {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()

        do {
            let tasks = try context.fetch(fetchRequest)
            for task in tasks {
                context.delete(task)
            }
            try context.save()
            print("✅ 已清除所有本地任务数据")
        } catch {
            print("❌ 清除本地任务数据失败: \(error)")
        }
    }
    
    private func sendMessage(_ message: WSMessage) {
        guard let webSocketTask = webSocketTask else {
            print("❌ WebSocket未连接，无法发送消息")
            return
        }

        do {
            let data = try JSONEncoder().encode(message)
            let messageString = String(data: data, encoding: .utf8) ?? ""
            print("📤 发送WebSocket消息: \(messageString)")

            webSocketTask.send(.string(messageString)) { error in
                if let error = error {
                    print("❌ 发送WebSocket消息失败: \(error)")
                } else {
                    print("✅ WebSocket消息发送成功")
                }
            }
        } catch {
            print("❌ 编码WebSocket消息失败: \(error)")
        }
    }
    
    // MARK: - 任务操作接口

    func createTask(_ task: TaskItem) async {
        // 直接通过WebSocket发送创建任务消息
        await sendCreateTaskMessage(task)
        print("📤 通过WebSocket发送创建任务: \(task.title ?? "")")
    }

    func updateTask(_ task: TaskItem) async {
        // 直接通过WebSocket发送更新任务消息
        await sendUpdateTaskMessage(task)
        print("📤 通过WebSocket发送更新任务: \(task.title ?? "")")
    }

    func deleteTask(_ task: TaskItem) async {
        // 直接通过WebSocket发送删除任务消息
        await sendDeleteTaskMessage(task)
        print("📤 通过WebSocket发送删除任务: \(task.title ?? "")")
    }

    // MARK: - WebSocket消息发送

    private func sendCreateTaskMessage(_ task: TaskItem) async {
        let taskData = TaskData(
            id: 0, // 新任务ID为0，服务器会分配
            userId: "default_user",
            title: task.title ?? "",
            description: task.taskDescription ?? "",
            dueDate: ISO8601DateFormatter().string(from: task.dueDate ?? Date()),
            isCompleted: task.isCompleted,
            category: task.category ?? "学习",
            priority: Int(task.priority),
            deviceId: task.deviceId ?? "",
            recordId: task.recordID ?? "",
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            workProgress: task.workProgress,
            timeSpent: task.timeSpent,
            progressNotes: task.progressNotes
        )

        let message = WSMessage(type: "create_task", data: AnyCodable(taskData))
        sendMessage(message)
    }

    private func sendUpdateTaskMessage(_ task: TaskItem) async {
        // 格式化日期
        let formatter = ISO8601DateFormatter()
        let dueDateString = task.dueDate != nil ? formatter.string(from: task.dueDate!) : ""
        let createdAtString = task.createdDate != nil ? formatter.string(from: task.createdDate!) : ""
        let updatedAtString = formatter.string(from: Date()) // 更新时间设为当前时间

        let taskData = TaskData(
            id: 0, // 更新时主要通过recordId匹配
            userId: "default_user",
            title: task.title ?? "",
            description: task.taskDescription ?? "",
            dueDate: dueDateString,
            isCompleted: task.isCompleted,
            category: task.category ?? "学习",
            priority: Int(task.priority),
            deviceId: task.deviceId ?? "",
            recordId: task.recordID ?? "",
            createdAt: createdAtString,
            updatedAt: updatedAtString,
            workProgress: task.workProgress,
            timeSpent: task.timeSpent,
            progressNotes: task.progressNotes
        )

        print("✏️ 准备更新任务，recordId: \(task.recordID ?? "无"), title: \(task.title ?? "")")
        let message = WSMessage(type: "update_task", data: AnyCodable(taskData))
        sendMessage(message)
    }

    private func sendDeleteTaskMessage(_ task: TaskItem) async {
        // 格式化日期
        let formatter = ISO8601DateFormatter()
        let dueDateString = task.dueDate != nil ? formatter.string(from: task.dueDate!) : ""
        let createdAtString = task.createdDate != nil ? formatter.string(from: task.createdDate!) : ""
        let updatedAtString = task.lastModified != nil ? formatter.string(from: task.lastModified!) : ""

        let taskData = TaskData(
            id: 0, // 删除时主要通过recordId匹配
            userId: "default_user",
            title: task.title ?? "",
            description: task.taskDescription ?? "",
            dueDate: dueDateString,
            isCompleted: task.isCompleted,
            category: task.category ?? "学习",
            priority: Int(task.priority),
            deviceId: task.deviceId ?? "",
            recordId: task.recordID ?? "",
            createdAt: createdAtString,
            updatedAt: updatedAtString,
            workProgress: task.workProgress,
            timeSpent: task.timeSpent,
            progressNotes: task.progressNotes
        )

        print("🗑️ 准备删除任务，recordId: \(task.recordID ?? "无"), title: \(task.title ?? "")")
        let message = WSMessage(type: "delete_task", data: AnyCodable(taskData))
        sendMessage(message)
    }

    // MARK: - 日期解析辅助函数
    private func parseDate(from dateString: String) -> Date? {
        print("🗓️ 解析日期字符串: \(dateString)")

        // 尝试标准ISO8601格式
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            print("✅ ISO8601格式解析成功: \(date)")
            return date
        }

        // 尝试datetime-local格式 (YYYY-MM-DDTHH:MM)
        if dateString.count == 16 && dateString.contains("T") {
            let extendedDateString = dateString + ":00.000Z"
            if let date = iso8601Formatter.date(from: extendedDateString) {
                print("✅ datetime-local格式解析成功: \(date)")
                return date
            }
        }

        // 尝试其他常见格式
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm"
        ]

        for formatString in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = formatString
            formatter.timeZone = TimeZone.current
            if let date = formatter.date(from: dateString) {
                print("✅ 自定义格式解析成功: \(formatString) -> \(date)")
                return date
            }
        }

        print("❌ 日期解析失败: \(dateString)")
        return nil
    }


}
