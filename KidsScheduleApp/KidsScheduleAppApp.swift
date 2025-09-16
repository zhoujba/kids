import SwiftUI
import CoreData
import UserNotifications
import UIKit

@main
struct KidsScheduleAppApp: App {
    let persistenceController = PersistenceController.shared
    let webSocketManager = WebSocketManager.shared

    init() {
        // 请求通知权限
        requestNotificationPermission()

        // 配置WebSocket实时同步
        setupWebSocketSync()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("通知权限已获得")
            } else {
                print("通知权限被拒绝")
            }
        }
    }

    private func setupWebSocketSync() {
        // WebSocket会在初始化时自动连接
        // 这里只需要确保应用启动后WebSocket正常工作
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if !self.webSocketManager.isConnected {
                self.webSocketManager.connect()
            }
        }

        print("WebSocket实时同步已启动")
    }
}

// MARK: - Core Data Stack
class PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // 创建示例数据
        let sampleTask = TaskItem(context: viewContext)
        sampleTask.title = "完成项目报告"
        sampleTask.taskDescription = "整理本周工作进展，准备下周计划"
        sampleTask.dueDate = Date().addingTimeInterval(3600) // 1小时后
        sampleTask.category = "工作"
        sampleTask.isCompleted = false
        sampleTask.createdDate = Date()
        sampleTask.deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        sampleTask.recordID = UUID().uuidString
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DataModel")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        // 配置自动迁移
        container.persistentStoreDescriptions.forEach { storeDescription in
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.shouldInferMappingModelAutomatically = true
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("❌ Core Data加载失败: \(error), \(error.userInfo)")
                // 在开发阶段，如果遇到迁移问题，可以删除并重新创建数据库
                #if DEBUG
                print("🔄 尝试删除并重新创建数据库...")
                if let url = storeDescription.url {
                    try? FileManager.default.removeItem(at: url)
                    // 重新加载
                    self.container.loadPersistentStores { _, error in
                        if let error = error {
                            fatalError("重新创建数据库失败: \(error)")
                        }
                        print("✅ 数据库重新创建成功")
                    }
                }
                #else
                fatalError("Unresolved error \(error), \(error.userInfo)")
                #endif
            } else {
                print("✅ Core Data加载成功")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
