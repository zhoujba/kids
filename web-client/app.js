class TaskManager {
    constructor() {
        this.ws = null;
        this.tasks = [];
        this.isConnected = false;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 5;
        this.reconnectDelay = 3000;
        
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.connectWebSocket();
        this.setDefaultDueDate();
    }

    setupEventListeners() {
        // 表单提交
        document.getElementById('taskForm').addEventListener('submit', (e) => {
            e.preventDefault();
            this.createTask();
        });

        // 页面关闭时断开连接
        window.addEventListener('beforeunload', () => {
            if (this.ws) {
                this.ws.close();
            }
        });
    }

    connectWebSocket() {
        const wsUrl = 'ws://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/ws';
        
        try {
            this.ws = new WebSocket(wsUrl);
            this.updateConnectionStatus('connecting', '连接中...');

            this.ws.onopen = () => {
                console.log('✅ WebSocket连接成功');
                this.isConnected = true;
                this.reconnectAttempts = 0;
                this.updateConnectionStatus('connected', '已连接');
                
                // 发送ping保持连接
                this.sendPing();
                this.startHeartbeat();
            };

            this.ws.onmessage = (event) => {
                try {
                    const message = JSON.parse(event.data);
                    this.handleMessage(message);
                } catch (error) {
                    console.error('❌ 解析消息失败:', error);
                }
            };

            this.ws.onclose = (event) => {
                console.log('🔌 WebSocket连接关闭:', event.code, event.reason);
                this.isConnected = false;
                this.updateConnectionStatus('disconnected', '连接断开');
                
                // 尝试重连
                if (this.reconnectAttempts < this.maxReconnectAttempts) {
                    this.reconnectAttempts++;
                    console.log(`🔄 尝试重连 (${this.reconnectAttempts}/${this.maxReconnectAttempts})`);
                    setTimeout(() => this.connectWebSocket(), this.reconnectDelay);
                }
            };

            this.ws.onerror = (error) => {
                console.error('❌ WebSocket错误:', error);
                this.updateConnectionStatus('disconnected', '连接错误');
            };

        } catch (error) {
            console.error('❌ WebSocket连接失败:', error);
            this.updateConnectionStatus('disconnected', '连接失败');
        }
    }

    handleMessage(message) {
        console.log('📨 收到消息:', message);

        switch (message.type) {
            case 'tasks_sync':
                this.handleTasksSync(message.data);
                break;
            case 'task_created':
                this.handleTaskCreated(message.data);
                break;
            case 'task_updated':
                this.handleTaskUpdated(message.data);
                break;
            case 'task_deleted':
                this.handleTaskDeleted(message.data);
                break;
            case 'pong':
                console.log('💓 收到心跳响应');
                break;
            default:
                console.log('❓ 未知消息类型:', message.type);
        }
    }

    handleTasksSync(tasks) {
        console.log('🔄 同步任务列表，任务数量:', tasks.length);
        this.tasks = tasks;
        this.renderTasks();
        this.updateStats();
    }

    handleTaskCreated(task) {
        console.log('➕ 新任务创建:', task.title);
        this.tasks.push(task);
        this.renderTasks();
        this.updateStats();
        this.showNotification('新任务已添加: ' + task.title, 'success');
    }

    handleTaskUpdated(task) {
        console.log('✏️ 任务更新:', task.title);
        const index = this.tasks.findIndex(t => t.record_id === task.record_id || t.id === task.id);
        if (index !== -1) {
            this.tasks[index] = task;
            this.renderTasks();
            this.updateStats();
            this.showNotification('任务已更新: ' + task.title, 'info');
        }
    }

    handleTaskDeleted(task) {
        console.log('🗑️ 任务删除:', task.title);
        this.tasks = this.tasks.filter(t => t.record_id !== task.record_id && t.id !== task.id);
        this.renderTasks();
        this.updateStats();
        this.showNotification('任务已删除: ' + task.title, 'warning');
    }

    sendMessage(message) {
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
            this.ws.send(JSON.stringify(message));
            console.log('📤 发送消息:', message);
        } else {
            console.error('❌ WebSocket未连接，无法发送消息');
            this.showNotification('连接断开，请稍后重试', 'error');
        }
    }

    sendPing() {
        this.sendMessage({ type: 'ping' });
    }

    startHeartbeat() {
        setInterval(() => {
            if (this.isConnected) {
                this.sendPing();
            }
        }, 30000); // 每30秒发送一次心跳
    }

    createTask() {
        const title = document.getElementById('taskTitle').value.trim();
        const description = document.getElementById('taskDescription').value.trim();
        const category = document.getElementById('taskCategory').value;
        const priority = parseInt(document.getElementById('taskPriority').value);
        const dueDate = document.getElementById('taskDueDate').value;

        if (!title) {
            this.showNotification('请输入任务标题', 'error');
            return;
        }

        const task = {
            user_id: 'default_user',
            title: title,
            description: description,
            category: category,
            priority: priority,
            due_date: dueDate || new Date().toISOString(),
            is_completed: false,
            device_id: this.generateDeviceId(),
            record_id: this.generateRecordId(),
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
        };

        this.sendMessage({
            type: 'create_task',
            data: task
        });

        // 清空表单
        document.getElementById('taskForm').reset();
        this.setDefaultDueDate();
        
        this.showNotification('任务创建请求已发送', 'success');
    }

    toggleTask(taskId, recordId) {
        const task = this.tasks.find(t => t.id === taskId || t.record_id === recordId);
        if (!task) return;

        const updatedTask = {
            ...task,
            is_completed: !task.is_completed,
            updated_at: new Date().toISOString()
        };

        this.sendMessage({
            type: 'update_task',
            data: updatedTask
        });
    }

    deleteTask(taskId, recordId) {
        const task = this.tasks.find(t => t.id === taskId || t.record_id === recordId);
        if (!task) return;

        if (confirm('确定要删除这个任务吗？')) {
            this.sendMessage({
                type: 'delete_task',
                data: task
            });
        }
    }

    renderTasks() {
        const container = document.getElementById('taskContainer');
        
        if (this.tasks.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-clipboard-list"></i>
                    <h3>暂无任务</h3>
                    <p>在右侧添加第一个任务吧！</p>
                </div>
            `;
            return;
        }

        // 按优先级和创建时间排序
        const sortedTasks = [...this.tasks].sort((a, b) => {
            if (a.is_completed !== b.is_completed) {
                return a.is_completed ? 1 : -1; // 未完成的在前
            }
            if (a.priority !== b.priority) {
                return a.priority - b.priority; // 优先级高的在前
            }
            return new Date(b.created_at) - new Date(a.created_at); // 新创建的在前
        });

        container.innerHTML = sortedTasks.map(task => this.renderTaskItem(task)).join('');
    }

    renderTaskItem(task) {
        const categoryEmoji = {
            '学习': '📚',
            '运动': '🏃',
            '娱乐': '🎮',
            '其他': '📝'
        };

        const priorityText = {
            1: '高',
            2: '中',
            3: '低'
        };

        const dueDate = task.due_date ? new Date(task.due_date).toLocaleString('zh-CN') : '';

        return `
            <div class="task-item ${task.is_completed ? 'completed' : ''} priority-${task.priority}">
                <div class="task-header">
                    <div class="task-checkbox ${task.is_completed ? 'checked' : ''}" 
                         onclick="taskManager.toggleTask('${task.id}', '${task.record_id}')">
                    </div>
                    <div class="task-title ${task.is_completed ? 'completed' : ''}">${task.title}</div>
                    <div class="task-actions">
                        <button class="btn btn-delete" onclick="taskManager.deleteTask('${task.id}', '${task.record_id}')">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </div>
                ${task.description ? `<div class="task-description">${task.description}</div>` : ''}
                <div class="task-meta">
                    <span class="category-tag">${categoryEmoji[task.category] || '📝'} ${task.category}</span>
                    <span class="priority-badge priority-${task.priority}">优先级: ${priorityText[task.priority]}</span>
                    ${dueDate ? `<span><i class="fas fa-clock"></i> ${dueDate}</span>` : ''}
                </div>
            </div>
        `;
    }

    updateStats() {
        const total = this.tasks.length;
        const completed = this.tasks.filter(t => t.is_completed).length;
        const pending = total - completed;

        document.getElementById('totalTasks').textContent = total;
        document.getElementById('completedTasks').textContent = completed;
        document.getElementById('pendingTasks').textContent = pending;
    }

    updateConnectionStatus(status, text) {
        const dot = document.getElementById('statusDot');
        const statusText = document.getElementById('statusText');
        
        dot.className = `status-dot ${status}`;
        statusText.textContent = text;
    }

    showNotification(message, type = 'info') {
        // 简单的通知实现
        const notification = document.createElement('div');
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: ${type === 'success' ? '#2ed573' : type === 'error' ? '#ff4757' : type === 'warning' ? '#ffa502' : '#3498db'};
            color: white;
            padding: 15px 20px;
            border-radius: 10px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.2);
            z-index: 1000;
            animation: slideIn 0.3s ease;
        `;
        notification.textContent = message;
        
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.style.animation = 'slideOut 0.3s ease';
            setTimeout(() => notification.remove(), 300);
        }, 3000);
    }

    setDefaultDueDate() {
        const now = new Date();
        now.setHours(now.getHours() + 1); // 默认1小时后
        document.getElementById('taskDueDate').value = now.toISOString().slice(0, 16);
    }

    generateDeviceId() {
        return 'web-' + Math.random().toString(36).substr(2, 9);
    }

    generateRecordId() {
        return 'record-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
    }
}

// 添加CSS动画
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from { transform: translateX(100%); opacity: 0; }
        to { transform: translateX(0); opacity: 1; }
    }
    
    @keyframes slideOut {
        from { transform: translateX(0); opacity: 1; }
        to { transform: translateX(100%); opacity: 0; }
    }
`;
document.head.appendChild(style);

// 初始化任务管理器
const taskManager = new TaskManager();

// 全局错误处理
window.addEventListener('error', (event) => {
    console.error('❌ 全局错误:', event.error);
});

console.log('🚀 儿童任务管理Web版已启动');
console.log('📱 与iOS应用实时同步');
console.log('🌐 WebSocket服务器: ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082');
