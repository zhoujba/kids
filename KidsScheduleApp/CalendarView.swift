import SwiftUI
import CoreData

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskItem.dueDate, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<TaskItem>
    
    @State private var selectedDate = Date()
    @State private var showingAddTask = false
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 月份导航
                monthNavigationView
                
                // 日历网格
                calendarGridView
                
                Divider()
                    .padding(.vertical, 8)
                
                // 选中日期的任务列表
                selectedDateTasksView
            }
            .navigationTitle("日程安排")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTask = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(presetDate: selectedDate)
            }
            .onReceive(NotificationCenter.default.publisher(for: .taskDropped)) { notification in
                handleTaskDrop(notification)
            }
        }
    }
    
    // MARK: - Month Navigation
    private var monthNavigationView: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text(dateFormatter.string(from: currentMonth))
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Calendar Grid
    private var calendarGridView: some View {
        VStack(spacing: 0) {
            // 星期标题
            weekdayHeaderView
            
            // 日期网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 1) {
                ForEach(daysInMonth, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDate(date, inSameDayAs: Date()),
                        tasks: tasksForDate(date),
                        onDateSelected: { selectedDate = date }
                    )
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Weekday Header
    private var weekdayHeaderView: some View {
        HStack {
            ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { weekday in
                Text(weekday)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Selected Date Tasks
    private var selectedDateTasksView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("选中日期：\(selectedDate, formatter: selectedDateFormatter)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                let selectedTasks = tasksForDate(selectedDate)
                let completedCount = selectedTasks.filter { $0.isCompleted }.count
                let totalCount = selectedTasks.count
                
                Text("\(completedCount)/\(totalCount) 完成")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(tasksForDate(selectedDate)) { task in
                        DraggableTaskRowView(task: task)
                            .id(task.objectID) // 确保每个任务有唯一标识
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Helper Methods
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysToSubtract = (firstWeekday - 1) % 7
        
        guard let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstOfMonth) else {
            return []
        }
        
        var dates: [Date] = []
        for i in 0..<42 { // 6 weeks * 7 days
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    private func tasksForDate(_ date: Date) -> [TaskItem] {
        return tasks.filter { task in
            guard let taskDate = task.dueDate else { return false }
            return calendar.isDate(taskDate, inSameDayAs: date)
        }
    }
    
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func updateTaskDate(_ task: TaskItem, to date: Date) {
        // 保持原有的时间，只更改日期
        if let originalDate = task.dueDate {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: originalDate)
            let newDate = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                      minute: timeComponents.minute ?? 0,
                                      second: 0,
                                      of: date) ?? date
            task.dueDate = newDate
        } else {
            task.dueDate = date
        }
        
        try? viewContext.save()
    }
    
    private var selectedDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 EEEE"
        return formatter
    }

    private func handleTaskDrop(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let taskIDString = userInfo["taskID"] as? String,
              let targetDate = userInfo["targetDate"] as? Date,
              let taskURL = URL(string: taskIDString),
              let objectID = viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: taskURL) else {
            return
        }

        do {
            let task = try viewContext.existingObject(with: objectID) as? TaskItem
            updateTaskDate(task!, to: targetDate)

            // 拖拽成功的触觉反馈
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
        } catch {
            print("Failed to fetch task: \(error)")

            // 拖拽失败的触觉反馈
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
        }
    }
}
