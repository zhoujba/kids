import SwiftUI
import UserNotifications

struct PomodoroView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var pomodoroTimer = PomodoroTimer()

    init() {
        // 将viewContext传递给PomodoroTimer
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 当前状态显示
                VStack(spacing: 10) {
                    Text(pomodoroTimer.currentPhase == .work ? "工作时间" : "休息时间")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(pomodoroTimer.currentPhase == .work ? .blue : .green)
                    
                    Text("第 \(pomodoroTimer.completedCycles + 1) 个番茄")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 圆形进度条和时间显示
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 250, height: 250)
                    
                    Circle()
                        .trim(from: 0, to: pomodoroTimer.progress)
                        .stroke(
                            pomodoroTimer.currentPhase == .work ? Color.blue : Color.green,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: pomodoroTimer.progress)
                    
                    VStack {
                        Text(pomodoroTimer.timeString)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(pomodoroTimer.currentPhase == .work ? .blue : .green)
                        
                        Text(pomodoroTimer.currentPhase == .work ? "专注工作" : "放松休息")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 控制按钮
                HStack(spacing: 20) {
                    Button(action: {
                        if pomodoroTimer.isRunning {
                            pomodoroTimer.pause()
                        } else {
                            pomodoroTimer.start()
                        }
                    }) {
                        Image(systemName: pomodoroTimer.isRunning ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(pomodoroTimer.currentPhase == .work ? Color.blue : Color.green)
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        pomodoroTimer.reset()
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                }
                
                // 统计信息
                VStack(spacing: 10) {
                    Text("今日完成: \(pomodoroTimer.completedCycles) 个番茄")
                        .font(.headline)
                    
                    HStack(spacing: 40) {
                        VStack {
                            Text("工作时长")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(pomodoroTimer.workDuration / 60) 分钟")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        
                        VStack {
                            Text("休息时长")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(pomodoroTimer.breakDuration / 60) 分钟")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("番茄工作法")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("设置") {
                        // 可以添加设置页面
                    }
                }
            }
        }
    }
}

// MARK: - Pomodoro Timer Class
class PomodoroTimer: ObservableObject {
    @Published var timeRemaining: Int = 25 * 60 // 25分钟工作时间
    @Published var isRunning = false
    @Published var currentPhase: PomodoroPhase = .work
    @Published var completedCycles = 0
    @Published var progress: Double = 1.0

    let workDuration = 25 * 60 // 25分钟
    let breakDuration = 5 * 60 // 5分钟
    let longBreakDuration = 15 * 60 // 15分钟

    private var timer: Timer?
    private var totalTime: Int = 25 * 60
    private var sessionStartTime: Date?
    
    enum PomodoroPhase {
        case work
        case shortBreak
        case longBreak
    }
    
    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func start() {
        isRunning = true
        if sessionStartTime == nil {
            sessionStartTime = Date()
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.tick()
        }
    }
    
    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func reset() {
        pause()
        currentPhase = .work
        timeRemaining = workDuration
        totalTime = workDuration
        progress = 1.0
        sessionStartTime = nil
    }
    
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
            progress = Double(timeRemaining) / Double(totalTime)
        } else {
            // 时间到了，切换阶段
            completePhase()
        }
    }
    
    private func completePhase() {
        // 发送通知
        sendNotification()

        // 保存完成的工作会话
        if currentPhase == .work {
            saveCompletedSession()
        }

        switch currentPhase {
        case .work:
            completedCycles += 1
            // 每4个番茄后是长休息
            if completedCycles % 4 == 0 {
                currentPhase = .longBreak
                timeRemaining = longBreakDuration
                totalTime = longBreakDuration
            } else {
                currentPhase = .shortBreak
                timeRemaining = breakDuration
                totalTime = breakDuration
            }
        case .shortBreak, .longBreak:
            currentPhase = .work
            timeRemaining = workDuration
            totalTime = workDuration
        }

        progress = 1.0
        sessionStartTime = nil // 重置开始时间，为下一个会话做准备

        // 自动开始下一阶段（可选）
        // start()
        pause() // 暂停，让用户手动开始
    }
    
    private func sendNotification() {
        let content = UNMutableNotificationContent()
        
        switch currentPhase {
        case .work:
            content.title = "工作时间结束！"
            content.body = "是时候休息一下了 🎉"
        case .shortBreak:
            content.title = "休息时间结束！"
            content.body = "准备开始下一个番茄工作时间 💪"
        case .longBreak:
            content.title = "长休息时间结束！"
            content.body = "休息得不错，继续加油工作吧！ 🚀"
        }
        
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知发送失败: \(error)")
            }
        }
    }

    private func saveCompletedSession() {
        guard let startTime = sessionStartTime else { return }

        let context = PersistenceController.shared.container.viewContext
        let session = PomodoroSession(context: context)

        session.startTime = startTime
        session.endTime = Date()
        session.totalDuration = Int32(workDuration)
        session.completedCycles = Int16(completedCycles)
        session.isActive = false
        session.createdDate = Date()
        session.needsSync = false // 禁用MySQL同步，使用WebSocket实时同步

        do {
            try context.save()
            print("番茄工作法会话已保存")

            // 注释掉MySQL同步，改用WebSocket实时同步
            // Task {
            //     await MySQLSyncManager.shared.performSync()
            // }
        } catch {
            print("保存番茄工作法会话失败: \(error)")
        }
    }
}

#Preview {
    PomodoroView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
