import SwiftUI
import UserNotifications
import UIKit

struct AddTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    // 如果传入了task，则为编辑模式；否则为添加模式
    let taskToEdit: TaskItem?
    let presetDate: Date?

    @State private var title = ""
    @State private var description = ""
    @State private var category = "工作"
    @State private var dueDate = Date().addingTimeInterval(3600) // 默认1小时后
    @State private var priority = 1
    @State private var enableNotification = true

    // 初始化方法
    init(taskToEdit: TaskItem? = nil, presetDate: Date? = nil) {
        self.taskToEdit = taskToEdit
        self.presetDate = presetDate
    }
    
    let categories = ["工作", "学习", "运动", "娱乐", "生活", "其他"]
    let priorities = [
        (1, "低"),
        (2, "中"),
        (3, "高")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    HStack {
                        TextField("事项标题", text: $title)
                        VoiceInputButton(text: $title)
                    }

                    HStack {
                        TextField("详细描述", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                        VStack {
                            VoiceInputButton(text: $description)
                            Spacer()
                        }
                    }
                }

                Section("分类和优先级") {
                    Picker("分类", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }

                    Picker("优先级", selection: $priority) {
                        ForEach(priorities, id: \.0) { priority in
                            Text(priority.1).tag(priority.0)
                        }
                    }
                }

                Section("时间设置") {
                    DatePicker("截止时间", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])

                    Toggle("启用提醒", isOn: $enableNotification)
                }

                if enableNotification {
                    Section("提醒设置") {
                        Text("将在截止时间前15分钟提醒您")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(isEditMode ? "编辑事项" : "添加事项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                loadTaskData()
            }
        }
    }

    // 是否为编辑模式
    private var isEditMode: Bool {
        taskToEdit != nil
    }

    // 加载任务数据（编辑模式时）或设置预设日期
    private func loadTaskData() {
        if let task = taskToEdit {
            // 编辑模式：加载现有任务数据
            title = task.title ?? ""
            description = task.taskDescription ?? ""
            category = task.category ?? "学习"
            dueDate = task.dueDate ?? Date().addingTimeInterval(3600)
            priority = Int(task.priority)
            enableNotification = task.notificationID != nil
        } else if let preset = presetDate {
            // 新建模式但有预设日期：设置为预设日期的当前时间
            let calendar = Calendar.current
            let now = Date()
            let timeComponents = calendar.dateComponents([.hour, .minute], from: now)
            dueDate = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                  minute: timeComponents.minute ?? 0,
                                  second: 0,
                                  of: preset) ?? preset
        }
    }
    
    private func saveTask() {
        let task: TaskItem

        if let existingTask = taskToEdit {
            // 编辑模式：更新现有任务
            task = existingTask

            // 如果之前有通知，先删除
            if let notificationID = task.notificationID {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
            }
        } else {
            // 添加模式：创建新任务
            task = TaskItem(context: viewContext)
            task.createdDate = Date()
            task.isCompleted = false
            task.recordID = UUID().uuidString // 设置唯一标识符
            task.deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        }

        // 更新任务数据
        task.title = title
        task.taskDescription = description.isEmpty ? nil : description
        task.category = category
        task.dueDate = dueDate
        task.priority = Int16(priority)
        task.lastModified = Date()
        task.needsSync = false // 不再需要MySQL同步，只通过WebSocket

        // 处理通知
        if enableNotification {
            scheduleNotification(for: task)
        } else {
            task.notificationID = nil
        }

        do {
            try viewContext.save()

            // 通过WebSocket实时同步
            Task {
                if taskToEdit != nil {
                    // 更新任务
                    await WebSocketManager.shared.updateTask(task)
                } else {
                    // 创建新任务
                    await WebSocketManager.shared.createTask(task)
                }
            }

            dismiss()
        } catch {
            let nsError = error as NSError
            print("保存失败: \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func scheduleNotification(for task: TaskItem) {
        let content = UNMutableNotificationContent()
        content.title = "事项提醒"
        content.body = "\(task.title ?? "未知事项") 将在15分钟后到期"
        content.sound = .default
        content.badge = 1
        
        // 在截止时间前15分钟提醒
        let reminderDate = task.dueDate?.addingTimeInterval(-15 * 60) ?? Date()
        
        // 只有当提醒时间在未来时才设置通知
        if reminderDate > Date() {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let notificationID = UUID().uuidString
            task.notificationID = notificationID
            
            let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("通知设置失败: \(error)")
                } else {
                    print("通知设置成功")
                }
            }
        }
    }
}

#Preview {
    AddTaskView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
