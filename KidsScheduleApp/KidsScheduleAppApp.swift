import SwiftUI
import CoreData
import UserNotifications

@main
struct KidsScheduleAppApp: App {
    let persistenceController = PersistenceController.shared
    let mysqlSyncManager = MySQLSyncManager.shared

    init() {
        // 请求通知权限
        requestNotificationPermission()

        // 配置MySQL同步
        setupMySQLSync()
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

    private func setupMySQLSync() {
        // 配置MySQL同步管理器
        mysqlSyncManager.configure(with: persistenceController.container.viewContext)

        // 启动MySQL同步
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.mysqlSyncManager.startSync()
        }

        print("MySQL同步已启动")
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
        sampleTask.title = "数学课"
        sampleTask.taskDescription = "今天下午3点有数学课"
        sampleTask.dueDate = Date().addingTimeInterval(3600) // 1小时后
        sampleTask.category = "学习"
        sampleTask.isCompleted = false
        sampleTask.createdDate = Date()
        
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
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
