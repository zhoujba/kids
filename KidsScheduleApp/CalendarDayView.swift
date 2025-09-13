import SwiftUI
import CoreData

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let tasks: [TaskItem]
    let onDateSelected: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 2) {
            // 日期数字
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .medium))
                .foregroundColor(dayTextColor)
            
            // 任务指示器
            taskIndicatorView
        }
        .frame(width: 45, height: 55)
        .background(dayBackgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onDateSelected()
        }
        .dropDestination(for: TaskTransferData.self) { droppedData, location in
            if let data = droppedData.first {
                // 添加视觉反馈
                withAnimation(.easeInOut(duration: 0.2)) {
                    // 这里可以添加一些视觉反馈
                }

                NotificationCenter.default.post(
                    name: .taskDropped,
                    object: nil,
                    userInfo: ["taskID": data.objectID, "targetDate": date]
                )
                return true
            }
            return false
        } isTargeted: { isTargeted in
            // 当拖拽悬停在日期上时的视觉反馈
            // 这里可以添加悬停效果
        }
    }
    
    // MARK: - Task Indicator View
    private var taskIndicatorView: some View {
        VStack(spacing: 1) {
            if tasks.isEmpty {
                // 无任务时显示空白
                Spacer()
                    .frame(height: 12)
            } else if tasks.count <= 3 {
                // 少于等于3个任务时显示圆点
                ForEach(Array(tasks.prefix(3).enumerated()), id: \.offset) { index, task in
                    Circle()
                        .fill(task.isCompleted ? Color.green : Color.orange)
                        .frame(width: 4, height: 4)
                }
                
                // 填充空白以保持高度一致
                ForEach(0..<(3 - min(tasks.count, 3)), id: \.self) { _ in
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            } else {
                // 超过3个任务时显示统计数字
                let completedCount = tasks.filter { $0.isCompleted }.count
                let totalCount = tasks.count
                
                Text("\(completedCount)/\(totalCount)")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        Capsule()
                            .fill(completedCount == totalCount ? Color.green : Color.orange)
                    )
            }
        }
        .frame(height: 12)
    }
    
    // MARK: - Computed Properties
    private var dayTextColor: Color {
        if isCurrentMonth {
            if isToday {
                return .white
            } else if isSelected {
                return .blue
            } else {
                return .primary
            }
        } else {
            return .secondary.opacity(0.5)
        }
    }
    
    private var dayBackgroundColor: Color {
        if isToday {
            return .blue
        } else if isSelected {
            return .blue.opacity(0.1)
        } else {
            return .clear
        }
    }
    
    private var isCurrentMonth: Bool {
        let today = Date()
        return calendar.isDate(date, equalTo: today, toGranularity: .month)
    }
}

// MARK: - Draggable Task Row View
struct DraggableTaskRowView: View {
    @ObservedObject var task: TaskItem
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingEditTask = false
    
    var body: some View {
        HStack(spacing: 8) {
            // 拖拽手柄
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.gray)
                        .frame(width: 20, height: 2)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .draggable(TaskTransferData(
                objectID: task.objectID.uriRepresentation().absoluteString,
                title: task.title ?? "未知事项"
            )) {
                // 拖拽预览
                HStack(spacing: 8) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isCompleted ? .green : .gray)

                    Text(task.title ?? "未知事项")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                )
            }

            // 完成状态按钮
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    task.isCompleted.toggle()
                    task.lastModified = Date()
                    task.needsSync = true
                    MySQLSyncManager.shared.markTaskForSync(task)
                    try? viewContext.save()
                }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle()) // 防止按钮样式干扰

            // 任务内容
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "未知事项")
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)

                if let description = task.taskDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    if let category = task.category, !category.isEmpty {
                        Text(category)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
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
                HStack(spacing: 4) {
                    Image(systemName: "pencil")
                        .font(.caption)
                    Text("修改")
                        .font(.caption)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .sheet(isPresented: $showingEditTask) {
            AddTaskView(taskToEdit: task)
        }
    }
}

// MARK: - Task Transfer Data
struct TaskTransferData: Codable, Transferable {
    let objectID: String
    let title: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let taskDropped = Notification.Name("taskDropped")
}


