import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // WebSocket实时同步状态栏
            WebSocketStatusBar()
                .padding(.horizontal)
                .padding(.top, 8)

            TabView(selection: $selectedTab) {
                CalendarView()
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("日历")
                    }
                    .tag(0)

                TaskListView()
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("列表")
                    }
                    .tag(1)

                PomodoroView()
                    .tabItem {
                        Image(systemName: "timer")
                        Text("番茄工作法")
                    }
                    .tag(2)

                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("设置")
                    }
                    .tag(3)
            }
            .accentColor(.blue)
        }
    }
}

// MARK: - Task List View
struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskItem.dueDate, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<TaskItem>

    @StateObject private var webSocketManager = WebSocketManager.shared
    @State private var showingAddTask = false
    @State private var showingVoiceMemo = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tasks) { task in
                    TaskRowView(task: task)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("删除", role: .destructive) {
                                deleteTask(task)
                            }
                        }
                }
                .onDelete(perform: deleteTasks)
            }
            .navigationTitle("儿子的事项")
            .onChange(of: webSocketManager.lastUpdateTime) { _ in
                // WebSocket数据更新时，强制刷新视图
                print("🔄 WebSocket数据更新，刷新任务列表")
            }
            .onReceive(NotificationCenter.default.publisher(for: .taskDataUpdated)) { _ in
                // 接收到任务数据更新通知时刷新
                print("📢 收到任务数据更新通知，刷新UI")
                // 强制刷新FetchRequest
                viewContext.refreshAllObjects()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingVoiceMemo = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "mic.circle.fill")
                            Text("语音备忘录")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTask = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
            .sheet(isPresented: $showingVoiceMemo) {
                VoiceMemoView()
            }
        }
    }
    
    private func deleteTask(_ task: TaskItem) {
        // 异步处理单个任务删除操作
        Task {
            // 先通过WebSocket API删除服务器上的任务
            await WebSocketManager.shared.deleteTask(task)

            // WebSocket消息发送完成后，在主线程删除本地任务
            await MainActor.run {
                withAnimation {
                    // 从本地删除
                    viewContext.delete(task)

                    do {
                        try viewContext.save()
                        print("✅ 本地任务删除成功: \(task.title ?? "未知任务")")

                    } catch {
                        let nsError = error as NSError
                        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                    }
                }
            }
        }
    }

    private func deleteTasks(offsets: IndexSet) {
        let tasksToDelete = offsets.map { tasks[$0] }

        // 异步处理删除操作
        Task {
            // 先通过WebSocket API删除服务器上的任务
            for task in tasksToDelete {
                await WebSocketManager.shared.deleteTask(task)
            }

            // WebSocket消息发送完成后，在主线程删除本地任务
            await MainActor.run {
                withAnimation {
                    // 从本地删除
                    tasksToDelete.forEach(viewContext.delete)

                    do {
                        try viewContext.save()
                        print("✅ 本地任务删除成功")

                    } catch {
                        let nsError = error as NSError
                        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                    }
                }
            }
        }
    }
}

// MARK: - Task Row View
struct TaskRowView: View {
    @ObservedObject var task: TaskItem
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingEditTask = false

    var body: some View {
        HStack {
            Button(action: {
                task.isCompleted.toggle()
                task.lastModified = Date()
                task.needsSync = false // 不再需要MySQL同步
                try? viewContext.save()

                // 立即通过WebSocket同步
                Task {
                    await WebSocketManager.shared.updateTask(task)
                }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "未知事项")
                    .font(.headline)
                    .strikethrough(task.isCompleted)

                if let description = task.taskDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    if let category = task.category, !category.isEmpty {
                        Text(category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }

                    Spacer()

                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .time)
                            .font(.caption)
                            .foregroundColor(dueDate < Date() ? .red : .secondary)
                    }
                }
            }

            Spacer()

            // 操作按钮组 - 简洁的图标按钮
            HStack(spacing: 12) {
                // 编辑按钮
                Button(action: {
                    showingEditTask = true
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())

                // iPad删除按钮 - 在iPad上显示删除按钮，因为左滑手势在Mac上可能不好用
                if UIDevice.current.userInterfaceIdiom == .pad {
                    Button(action: {
                        deleteTask()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingEditTask) {
            AddTaskView(taskToEdit: task)
        }
    }

    private func deleteTask() {
        // 异步处理任务删除操作
        Task {
            // 先通过WebSocket API删除服务器上的任务
            await WebSocketManager.shared.deleteTask(task)

            // WebSocket消息发送完成后，在主线程删除本地任务
            await MainActor.run {
                withAnimation {
                    // 从本地删除
                    viewContext.delete(task)

                    do {
                        try viewContext.save()
                        print("✅ 任务删除成功: \(task.title ?? "未知任务")")

                    } catch {
                        let nsError = error as NSError
                        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                    }
                }
            }
        }
    }
}



#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
