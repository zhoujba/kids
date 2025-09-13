import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // MySQL同步状态栏
            MySQLSyncStatusView()
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
    
    @State private var showingAddTask = false
    @State private var showingVoiceMemo = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tasks) { task in
                    TaskRowView(task: task)
                }
                .onDelete(perform: deleteTasks)
            }
            .navigationTitle("儿子的事项")
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
    
    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            offsets.map { tasks[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
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
                task.needsSync = true
                MySQLSyncManager.shared.markTaskForSync(task)
                try? viewContext.save()
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

            // 编辑按钮
            Button(action: {
                showingEditTask = true
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingEditTask) {
            AddTaskView(taskToEdit: task)
        }
    }
}



#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
