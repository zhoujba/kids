import Foundation
import UIKit

class MySQLManager: ObservableObject {
    static let shared = MySQLManager()

    // API服务器配置
    // 临时使用本地PHP API测试
    private let baseURL = "http://localhost:8080/api"
    private let healthURL = "http://localhost:8080/health"

    // 设备和用户标识
    let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    let userId = "default_user" // 可以后续改为用户登录系统

    @Published var isConnected = false
    @Published var connectionError: String?

    private var healthCheckTimer: Timer?

    private init() {
        startHealthCheck()
    }

    // MARK: - 连接管理

    private func startHealthCheck() {
        // 立即检查一次
        checkConnection()

        // 每30秒检查一次连接状态
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.checkConnection()
        }
    }

    private func checkConnection() {
        Task {
            let connected = await performHealthCheck()
            await MainActor.run {
                self.isConnected = connected
                if connected {
                    self.connectionError = nil
                    print("MySQL连接成功")
                } else {
                    self.connectionError = "API服务器无法访问"
                    print("MySQL连接失败")
                }
            }
        }
    }

    private func performHealthCheck() async -> Bool {
        guard let url = URL(string: healthURL) else {
            print("MySQL健康检查: 无效的URL")
            return false
        }

        do {
            print("MySQL健康检查: 正在连接 \(healthURL)")
            let (data, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                print("MySQL健康检查: HTTP状态码 \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("MySQL健康检查: 响应内容 \(responseString)")
                }
                return httpResponse.statusCode == 200
            }
            print("MySQL健康检查: 非HTTP响应")
            return false
        } catch {
            print("MySQL健康检查失败: \(error.localizedDescription)")
            return false
        }

        // 原始代码（暂时注释）
        /*
        guard let url = URL(string: healthURL) else {
            print("MySQL健康检查: 无效的URL")
            return false
        }

        do {
            print("MySQL健康检查: 正在连接 \(healthURL)")
            let (data, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                print("MySQL健康检查: HTTP状态码 \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("MySQL健康检查: 响应内容 \(responseString)")
                }
                return httpResponse.statusCode == 200
            }
            print("MySQL健康检查: 非HTTP响应")
            return false
        } catch {
            print("MySQL健康检查失败: \(error.localizedDescription)")
            return false
        }
        */
    }
    
    // MARK: - 数据同步方法
    
    func syncTask(_ task: TaskItem) async -> Bool {
        guard isConnected else {
            print("MySQL未连接，无法同步任务")
            return false
        }
        
        // 生成简单的UUID作为MySQL ID，避免Core Data复杂ID格式
        let mysqlId = UUID().uuidString

        let taskData = MySQLTaskData(
            id: mysqlId,
            userId: userId,
            title: task.title ?? "",
            description: task.taskDescription,
            dueDate: task.dueDate,
            isCompleted: task.isCompleted,
            deviceId: deviceId
        )
        
        return await uploadTask(taskData)
    }
    
    func syncPomodoroSession(_ session: PomodoroSession) async -> Bool {
        guard isConnected else {
            print("MySQL未连接，无法同步番茄工作法会话")
            return false
        }
        
        // 生成简单的UUID作为MySQL ID，避免Core Data复杂ID格式
        let mysqlId = UUID().uuidString

        let sessionData = MySQLPomodoroSessionData(
            id: mysqlId,
            userId: userId,
            taskId: nil, // PomodoroSession doesn't have task relationship in current model
            duration: Int(session.totalDuration),
            startTime: session.startTime,
            endTime: session.endTime,
            isCompleted: session.isActive == false,
            deviceId: deviceId
        )
        
        return await uploadPomodoroSession(sessionData)
    }
    
    // MARK: - HTTP API 方法
    
    private func uploadTask(_ task: MySQLTaskData) async -> Bool {
        let url = URL(string: "\(baseURL)/tasks")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONEncoder().encode(task)
            request.httpBody = jsonData

            // 打印发送的JSON数据用于调试
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("发送任务数据: \(jsonString)")
            }

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                let success = httpResponse.statusCode == 200 || httpResponse.statusCode == 201
                if success {
                    print("任务同步成功: \(task.title)")
                } else {
                    print("任务同步失败: HTTP \(httpResponse.statusCode)")
                    // 打印服务器返回的错误信息
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("服务器错误响应: \(responseString)")
                    }
                }
                return success
            }
        } catch {
            print("任务同步错误: \(error)")
        }

        return false

    }
    
    private func uploadPomodoroSession(_ session: MySQLPomodoroSessionData) async -> Bool {
        let url = URL(string: "\(baseURL)/pomodoro-sessions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(session)
            request.httpBody = jsonData
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let success = httpResponse.statusCode == 200 || httpResponse.statusCode == 201
                if success {
                    print("番茄工作法会话同步成功")
                } else {
                    print("番茄工作法会话同步失败: HTTP \(httpResponse.statusCode)")
                }
                return success
            }
        } catch {
            print("番茄工作法会话同步错误: \(error)")
        }
        
        return false
    }
    
    func downloadTasks() async -> [MySQLTaskData] {
        let url = URL(string: "\(baseURL)/tasks?userId=\(userId)")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let tasks = try JSONDecoder().decode([MySQLTaskData].self, from: data)
                print("下载了 \(tasks.count) 个任务")
                return tasks
            }
        } catch {
            print("下载任务错误: \(error)")
        }
        
        return []
    }
    
    func downloadPomodoroSessions() async -> [MySQLPomodoroSessionData] {
        let url = URL(string: "\(baseURL)/pomodoro-sessions?userId=\(userId)")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let sessions = try JSONDecoder().decode([MySQLPomodoroSessionData].self, from: data)
                print("下载了 \(sessions.count) 个番茄工作法会话")
                return sessions
            }
        } catch {
            print("下载番茄工作法会话错误: \(error)")
        }
        
        return []
    }
}

// MARK: - 数据模型

struct MySQLTaskData: Codable {
    let id: String
    let userId: String
    let title: String
    let description: String?
    let dueDate: Date?
    let isCompleted: Bool
    let deviceId: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case dueDate = "due_date"
        case isCompleted = "is_completed"
        case deviceId = "device_id"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(deviceId, forKey: .deviceId)

        // 格式化日期为ISO 8601字符串
        if let dueDate = dueDate {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateString = formatter.string(from: dueDate)
            try container.encode(dateString, forKey: .dueDate)
        } else {
            try container.encodeNil(forKey: .dueDate)
        }
    }
}

struct MySQLPomodoroSessionData: Codable {
    let id: String
    let userId: String
    let taskId: String?
    let duration: Int
    let startTime: Date?
    let endTime: Date?
    let isCompleted: Bool
    let deviceId: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case taskId = "task_id"
        case duration
        case startTime = "start_time"
        case endTime = "end_time"
        case isCompleted = "is_completed"
        case deviceId = "device_id"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(taskId, forKey: .taskId)
        try container.encode(duration, forKey: .duration)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(deviceId, forKey: .deviceId)

        // 格式化日期为ISO 8601字符串
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let startTime = startTime {
            let dateString = formatter.string(from: startTime)
            try container.encode(dateString, forKey: .startTime)
        } else {
            try container.encodeNil(forKey: .startTime)
        }

        if let endTime = endTime {
            let dateString = formatter.string(from: endTime)
            try container.encode(dateString, forKey: .endTime)
        } else {
            try container.encodeNil(forKey: .endTime)
        }
    }
}
