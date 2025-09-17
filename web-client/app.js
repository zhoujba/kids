class TaskManager {
    constructor() {
        this.ws = null;
        this.tasks = [];
        this.filteredTasks = [];
        this.isConnected = false;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 5;
        this.reconnectDelay = 3000;
        this.currentFilter = 'all';
        this.currentSort = 'created_desc';
        this.searchQuery = '';
        this.currentView = 'list';

        this.init();
    }

    init() {
        this.setupEventListeners();
        this.connectWebSocket();
        this.setDefaultDueDate();
        this.setupFilters();
        this.setupSearch();
        this.setupSort();
        this.setupViewSwitcher();
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

        // ESC键关闭模态框
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.hideAddTaskModal();
                hideReportModal();
            }
        });

        // 点击模态框外部关闭
        document.getElementById('addTaskModal').addEventListener('click', (e) => {
            if (e.target.id === 'addTaskModal') {
                this.hideAddTaskModal();
            }
        });

        // 点击报告模态框外部关闭
        // 延迟设置，确保DOM已加载
        setTimeout(() => {
            const reportModal = document.getElementById('reportModal');
            if (reportModal) {
                reportModal.addEventListener('click', (e) => {
                    if (e.target.id === 'reportModal') {
                        hideReportModal();
                    }
                });
            }
        }, 100);
    }

    setupFilters() {
        const filterBtns = document.querySelectorAll('.filter-btn');
        filterBtns.forEach(btn => {
            btn.addEventListener('click', () => {
                // 移除所有active类
                filterBtns.forEach(b => b.classList.remove('active'));
                // 添加active类到当前按钮
                btn.classList.add('active');
                // 设置当前筛选器
                this.currentFilter = btn.dataset.filter;
                // 应用筛选
                this.applyFilters();
            });
        });
    }

    setupSearch() {
        const searchInput = document.getElementById('searchInput');
        searchInput.addEventListener('input', (e) => {
            this.searchQuery = e.target.value.toLowerCase();
            this.applyFilters();
        });
    }

    setupSort() {
        const sortSelect = document.getElementById('sortSelect');
        sortSelect.addEventListener('change', (e) => {
            this.currentSort = e.target.value;
            this.applyFilters();
        });
    }

    setupViewSwitcher() {
        const viewBtns = document.querySelectorAll('.view-btn');
        viewBtns.forEach(btn => {
            btn.addEventListener('click', () => {
                // 移除所有active类
                viewBtns.forEach(b => b.classList.remove('active'));
                // 添加active类到当前按钮
                btn.classList.add('active');
                // 切换视图
                this.switchView(btn.dataset.view);
            });
        });
    }

    switchView(view) {
        this.currentView = view;
        const listView = document.getElementById('listView');
        const boardView = document.getElementById('boardView');

        if (view === 'list') {
            listView.style.display = 'block';
            boardView.style.display = 'none';
            this.renderTasks();
        } else if (view === 'board') {
            listView.style.display = 'none';
            boardView.style.display = 'block';
            this.renderKanbanBoard();
        }
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
        this.applyFilters();
        this.updateStats();
    }

    handleTaskCreated(task) {
        console.log('➕ 新任务创建:', task.title);
        this.tasks.push(task);
        this.applyFilters();
        this.updateStats();
        this.showNotification('新任务已添加: ' + task.title, 'success');
    }

    handleTaskUpdated(task) {
        console.log('✏️ 任务更新:', task.title);
        const index = this.tasks.findIndex(t => t.record_id === task.record_id || t.id === task.id);
        if (index !== -1) {
            this.tasks[index] = task;
            this.applyFilters();
            this.updateStats();
            this.showNotification('任务已更新: ' + task.title, 'info');
        }
    }

    handleTaskDeleted(task) {
        console.log('🗑️ 任务删除:', task.title);
        this.tasks = this.tasks.filter(t => t.record_id !== task.record_id && t.id !== task.id);
        this.applyFilters();
        this.updateStats();
        this.showNotification('任务已删除: ' + task.title, 'warning');
    }

    applyFilters() {
        let filtered = [...this.tasks];

        // 应用搜索
        if (this.searchQuery) {
            filtered = filtered.filter(task =>
                task.title.toLowerCase().includes(this.searchQuery) ||
                (task.description && task.description.toLowerCase().includes(this.searchQuery)) ||
                task.category.toLowerCase().includes(this.searchQuery)
            );
        }

        // 应用筛选器
        if (this.currentFilter !== 'all') {
            if (this.currentFilter === 'pending') {
                filtered = filtered.filter(task => !task.is_completed);
            } else if (this.currentFilter === 'completed') {
                filtered = filtered.filter(task => task.is_completed);
            } else {
                filtered = filtered.filter(task => task.category === this.currentFilter);
            }
        }

        // 应用排序
        filtered.sort((a, b) => {
            switch (this.currentSort) {
                case 'created_desc':
                    return new Date(b.created_at) - new Date(a.created_at);
                case 'created_asc':
                    return new Date(a.created_at) - new Date(b.created_at);
                case 'priority_asc':
                    if (a.is_completed !== b.is_completed) {
                        return a.is_completed ? 1 : -1;
                    }
                    return a.priority - b.priority;
                case 'priority_desc':
                    if (a.is_completed !== b.is_completed) {
                        return a.is_completed ? 1 : -1;
                    }
                    return b.priority - a.priority;
                case 'due_date':
                    if (!a.due_date && !b.due_date) return 0;
                    if (!a.due_date) return 1;
                    if (!b.due_date) return -1;
                    return new Date(a.due_date) - new Date(b.due_date);
                case 'title':
                    return a.title.localeCompare(b.title);
                default:
                    return 0;
            }
        });

        this.filteredTasks = filtered;

        if (this.currentView === 'list') {
            this.renderTasks();
        } else {
            this.renderKanbanBoard();
        }
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
        const form = document.getElementById('taskForm');
        const editingId = form.dataset.editingId;

        const title = document.getElementById('taskTitle').value.trim();
        const description = document.getElementById('taskDescription').value.trim();
        const category = document.getElementById('taskCategory').value;
        const priority = parseInt(document.getElementById('taskPriority').value);
        const dueDate = document.getElementById('taskDueDate').value;

        if (!title) {
            this.showNotification('请输入任务标题', 'error');
            return;
        }

        // 确保日期格式正确
        let formattedDueDate;
        if (dueDate) {
            // 如果是datetime-local格式 (YYYY-MM-DDTHH:MM)，转换为完整ISO格式
            if (dueDate.length === 16 && dueDate.includes('T')) {
                formattedDueDate = new Date(dueDate).toISOString();
            } else {
                formattedDueDate = dueDate;
            }
        } else {
            formattedDueDate = new Date().toISOString();
        }

        if (editingId) {
            // 编辑现有任务
            this.updateTask(editingId, {
                title,
                description,
                category,
                priority,
                due_date: formattedDueDate
            });
        } else {
            // 创建新任务
            const task = {
                user_id: 'default_user',
                title: title,
                description: description,
                category: category,
                priority: priority,
                due_date: formattedDueDate,
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

            this.showNotification('任务创建请求已发送', 'success');
        }

        // 清空表单并关闭模态框
        this.resetForm();
        this.hideAddTaskModal();
    }

    updateTask(taskId, updates) {
        const task = this.tasks.find(t => t.id === taskId || t.record_id === taskId);
        if (!task) return;

        const updatedTask = {
            ...task,
            ...updates,
            updated_at: new Date().toISOString()
        };

        this.sendMessage({
            type: 'update_task',
            data: updatedTask
        });

        this.showNotification('任务更新请求已发送', 'success');
    }

    resetForm() {
        const form = document.getElementById('taskForm');
        form.reset();
        delete form.dataset.editingId;
        this.setDefaultDueDate();

        // 重置按钮文本
        const submitBtn = form.querySelector('button[type="submit"]');
        submitBtn.innerHTML = '<i class="fas fa-plus"></i> 添加任务';

        // 重置模态框标题
        document.querySelector('.modal-title').textContent = '添加新任务';
    }

    showAddTaskModal() {
        this.resetForm(); // 确保表单是干净的
        document.getElementById('addTaskModal').classList.add('show');
        document.body.style.overflow = 'hidden';
        // 聚焦到标题输入框
        setTimeout(() => {
            document.getElementById('taskTitle').focus();
        }, 100);
    }

    hideAddTaskModal() {
        document.getElementById('addTaskModal').classList.remove('show');
        document.body.style.overflow = '';
        this.resetForm(); // 清空表单和重置状态
    }

    editTask(taskId, recordId) {
        const task = this.tasks.find(t => t.id === taskId || t.record_id === recordId);
        if (!task) return;

        // 填充表单
        document.getElementById('taskTitle').value = task.title;
        document.getElementById('taskDescription').value = task.description || '';
        document.getElementById('taskCategory').value = task.category;
        document.getElementById('taskPriority').value = task.priority;
        if (task.due_date) {
            const date = new Date(task.due_date);
            document.getElementById('taskDueDate').value = date.toISOString().slice(0, 16);
        }

        // 设置编辑模式
        const form = document.getElementById('taskForm');
        form.dataset.editingId = task.id || task.record_id;

        // 更改按钮文本和模态框标题
        const submitBtn = form.querySelector('button[type="submit"]');
        submitBtn.innerHTML = '<i class="fas fa-save"></i> 更新任务';
        document.querySelector('.modal-title').textContent = '编辑任务';

        // 显示模态框
        document.getElementById('addTaskModal').classList.add('show');
        document.body.style.overflow = 'hidden';

        // 聚焦到标题输入框
        setTimeout(() => {
            document.getElementById('taskTitle').focus();
        }, 100);
    }

    markAllCompleted() {
        const pendingTasks = this.tasks.filter(t => !t.is_completed);
        if (pendingTasks.length === 0) {
            this.showNotification('没有待完成的任务', 'info');
            return;
        }

        if (confirm(`确定要将 ${pendingTasks.length} 个待完成任务标记为已完成吗？`)) {
            pendingTasks.forEach(task => {
                this.toggleTask(task.id, task.record_id);
            });
        }
    }

    clearCompleted() {
        const completedTasks = this.tasks.filter(t => t.is_completed);
        if (completedTasks.length === 0) {
            this.showNotification('没有已完成的任务', 'info');
            return;
        }

        if (confirm(`确定要删除 ${completedTasks.length} 个已完成的任务吗？`)) {
            completedTasks.forEach(task => {
                this.deleteTask(task.id, task.record_id);
            });
        }
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

        if (this.filteredTasks.length === 0) {
            const emptyMessage = this.tasks.length === 0
                ? '暂无任务<br>点击右下角的 + 按钮添加第一个任务吧！'
                : '没有找到匹配的任务<br>尝试调整搜索条件或筛选器';

            container.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-clipboard-list"></i>
                    <h3>暂无任务</h3>
                    <p>${emptyMessage}</p>
                </div>
            `;
            return;
        }

        container.innerHTML = this.filteredTasks.map(task => this.renderTaskItem(task)).join('');
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

        const dueDate = task.due_date ? new Date(task.due_date) : null;
        const now = new Date();
        const isOverdue = dueDate && dueDate < now && !task.is_completed;
        const dueDateStr = dueDate ? dueDate.toLocaleString('zh-CN', {
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        }) : '';

        return `
            <div class="task-item ${task.is_completed ? 'completed' : ''} priority-${task.priority}">
                <div class="task-header">
                    <div class="task-checkbox ${task.is_completed ? 'checked' : ''}"
                         onclick="taskManager.toggleTask('${task.id}', '${task.record_id}')">
                    </div>
                    <div class="task-content">
                        <div class="task-title ${task.is_completed ? 'completed' : ''}">${this.escapeHtml(task.title)}</div>
                        ${task.description ? `<div class="task-description">${this.escapeHtml(task.description)}</div>` : ''}
                        <div class="task-meta">
                            <div class="meta-item">
                                <span class="category-tag">${categoryEmoji[task.category] || '📝'} ${task.category}</span>
                            </div>
                            <div class="meta-item">
                                <span class="priority-badge priority-${task.priority}">${priorityText[task.priority]}</span>
                            </div>
                            ${dueDateStr ? `
                                <div class="meta-item">
                                    <i class="fas fa-clock"></i>
                                    <span class="due-date ${isOverdue ? 'overdue' : ''}">${dueDateStr}</span>
                                </div>
                            ` : ''}
                            ${isOverdue ? `
                                <div class="meta-item">
                                    <i class="fas fa-exclamation-triangle" style="color: var(--error-color);"></i>
                                    <span style="color: var(--error-color); font-weight: 600;">已逾期</span>
                                </div>
                            ` : ''}
                        </div>
                    </div>
                    <div class="task-actions">
                        <button class="btn btn-edit" onclick="taskManager.editTask('${task.id}', '${task.record_id}')" title="编辑">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-delete" onclick="taskManager.deleteTask('${task.id}', '${task.record_id}')" title="删除">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </div>
            </div>
        `;
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    renderKanbanBoard() {
        const now = new Date();
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);
        const nextWeek = new Date(today);
        nextWeek.setDate(nextWeek.getDate() + 7);

        // 分类任务
        const categories = {
            overdue: [],
            today: [],
            tomorrow: [],
            thisWeek: [],
            future: []
        };

        this.filteredTasks.forEach(task => {
            if (!task.due_date) {
                categories.future.push(task);
                return;
            }

            const dueDate = new Date(task.due_date);
            const dueDateOnly = new Date(dueDate.getFullYear(), dueDate.getMonth(), dueDate.getDate());

            if (dueDateOnly < today && !task.is_completed) {
                categories.overdue.push(task);
            } else if (dueDateOnly.getTime() === today.getTime()) {
                categories.today.push(task);
            } else if (dueDateOnly.getTime() === tomorrow.getTime()) {
                categories.tomorrow.push(task);
            } else if (dueDateOnly < nextWeek) {
                categories.thisWeek.push(task);
            } else {
                categories.future.push(task);
            }
        });

        // 渲染各个列
        this.renderKanbanColumn('overdueTasks', categories.overdue, 'overdueCount');
        this.renderKanbanColumn('todayTasks', categories.today, 'todayCount');
        this.renderKanbanColumn('tomorrowTasks', categories.tomorrow, 'tomorrowCount');
        this.renderKanbanColumn('thisWeekTasks', categories.thisWeek, 'thisWeekCount');
        this.renderKanbanColumn('futureTasks', categories.future, 'futureCount');
    }

    renderKanbanColumn(containerId, tasks, countId) {
        const container = document.getElementById(containerId);
        const countElement = document.getElementById(countId);

        countElement.textContent = tasks.length;

        if (tasks.length === 0) {
            container.innerHTML = `
                <div class="empty-column">
                    <i class="fas fa-check-circle" style="color: var(--text-tertiary); font-size: 2rem; margin-bottom: 8px;"></i>
                    <p style="color: var(--text-tertiary); font-size: 0.9rem;">暂无任务</p>
                </div>
            `;
            return;
        }

        container.innerHTML = tasks.map(task => this.renderKanbanTask(task)).join('');
    }

    renderKanbanTask(task) {
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

        const dueDate = task.due_date ? new Date(task.due_date) : null;
        const dueDateStr = dueDate ? dueDate.toLocaleString('zh-CN', {
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        }) : '';

        return `
            <div class="kanban-task ${task.is_completed ? 'completed' : ''}" onclick="taskManager.toggleTask('${task.id}', '${task.record_id}')">
                <div class="kanban-task-header">
                    <div class="task-checkbox ${task.is_completed ? 'checked' : ''}" onclick="event.stopPropagation(); taskManager.toggleTask('${task.id}', '${task.record_id}')">
                    </div>
                    <div class="kanban-task-title ${task.is_completed ? 'completed' : ''}">${this.escapeHtml(task.title)}</div>
                </div>
                ${task.description ? `<div class="kanban-task-description">${this.escapeHtml(task.description)}</div>` : ''}
                <div class="kanban-task-meta">
                    <span class="category-tag">${categoryEmoji[task.category] || '📝'} ${task.category}</span>
                    <span class="priority-badge priority-${task.priority}">${priorityText[task.priority]}</span>
                    ${dueDateStr ? `<span class="due-date"><i class="fas fa-clock"></i> ${dueDateStr}</span>` : ''}
                </div>
                <div class="kanban-task-actions" onclick="event.stopPropagation();">
                    <button class="btn btn-edit" onclick="taskManager.editTask('${task.id}', '${task.record_id}')" title="编辑">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn btn-delete" onclick="taskManager.deleteTask('${task.id}', '${task.record_id}')" title="删除">
                        <i class="fas fa-trash"></i>
                    </button>
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

// 全局函数，供HTML调用
function showAddTaskModal() {
    taskManager.showAddTaskModal();
}

function hideAddTaskModal() {
    taskManager.hideAddTaskModal();
}

function markAllCompleted() {
    taskManager.markAllCompleted();
}

function clearCompleted() {
    taskManager.clearCompleted();
}

// 测试函数
function testReportFunction() {
    console.log('🧪 测试函数被调用');
    alert('测试函数工作正常！');
}

// 报告功能
function generateDailyReport() {
    console.log('🔍 生成日报被调用');
    console.log('📊 当前任务数量:', taskManager.tasks.length);

    const today = new Date();
    const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    const todayEnd = new Date(todayStart.getTime() + 24 * 60 * 60 * 1000);

    console.log('📅 今日时间范围:', todayStart, '到', todayEnd);

    const todayTasks = taskManager.tasks.filter(task => {
        const taskDate = new Date(task.dueDate);
        return taskDate >= todayStart && taskDate < todayEnd;
    });

    console.log('📋 今日任务数量:', todayTasks.length);

    const completedTasks = todayTasks.filter(task => task.isCompleted);
    const ongoingTasks = todayTasks.filter(task => !task.isCompleted);

    // 获取未来任务
    const futureTasks = taskManager.tasks.filter(task => {
        const taskDate = new Date(task.dueDate);
        return taskDate >= todayEnd && !task.isCompleted;
    }).slice(0, 8);

    const reportContent = generateDailyReportHTML(todayTasks, completedTasks, ongoingTasks, futureTasks, today);
    console.log('📄 报告内容生成完成');
    showReportModal('📊 ' + formatDate(today) + ' 活动日报', reportContent);
}

function generateWeeklyReport() {
    console.log('🔍 生成周报被调用');
    console.log('📊 当前任务数量:', taskManager.tasks.length);

    const today = new Date();
    const weekStart = getWeekStart(today);
    const weekEnd = new Date(weekStart.getTime() + 7 * 24 * 60 * 60 * 1000);

    console.log('📅 本周时间范围:', weekStart, '到', weekEnd);

    const weekTasks = taskManager.tasks.filter(task => {
        const taskDate = new Date(task.dueDate);
        return taskDate >= weekStart && taskDate < weekEnd;
    });

    const completedTasks = weekTasks.filter(task => task.isCompleted);
    const ongoingTasks = weekTasks.filter(task => !task.isCompleted);

    // 按类型分组
    const tasksByCategory = {};
    weekTasks.forEach(task => {
        const category = task.category || '其他';
        if (!tasksByCategory[category]) {
            tasksByCategory[category] = [];
        }
        tasksByCategory[category].push(task);
    });

    const reportContent = generateWeeklyReportHTML(weekTasks, tasksByCategory, weekStart, weekEnd);
    showReportModal('📈 ' + formatWeekRange(weekStart, weekEnd) + ' 周报', reportContent);
}

function showReportModal(title, content) {
    console.log('📱 显示报告模态框:', title);

    const titleElement = document.getElementById('reportTitle');
    const contentElement = document.getElementById('reportContent');
    const modalElement = document.getElementById('reportModal');

    if (!titleElement || !contentElement || !modalElement) {
        console.error('❌ 找不到报告模态框元素');
        alert('报告模态框元素未找到，请检查页面是否正确加载');
        return;
    }

    titleElement.textContent = title;
    contentElement.innerHTML = content;
    modalElement.style.display = 'flex';

    console.log('✅ 报告模态框显示成功');

    // 存储当前报告内容用于复制
    try {
        window.currentReportText = generateReportText(content);
        console.log('📋 报告文本生成成功');
    } catch (error) {
        console.error('❌ 生成报告文本失败:', error);
    }
}

function hideReportModal() {
    document.getElementById('reportModal').style.display = 'none';
}

function copyReportText() {
    if (window.currentReportText) {
        navigator.clipboard.writeText(window.currentReportText).then(() => {
            // 显示复制成功提示
            const copyBtn = document.querySelector('#reportModal .btn-primary');
            const originalText = copyBtn.innerHTML;
            copyBtn.innerHTML = '<i class="fas fa-check"></i> 已复制';
            copyBtn.style.background = 'var(--success-color)';

            setTimeout(() => {
                copyBtn.innerHTML = originalText;
                copyBtn.style.background = '';
            }, 2000);
        }).catch(err => {
            console.error('复制失败:', err);
            alert('复制失败，请手动复制内容');
        });
    }
}

// 报告生成辅助函数
function generateDailyReportHTML(todayTasks, completedTasks, ongoingTasks, futureTasks, date) {
    const categoryIcons = {
        '工作': '💼',
        '学习': '📚',
        '运动': '🏃',
        '娱乐': '🎮',
        '生活': '🏠',
        '其他': '📝'
    };

    let html = `
        <div class="report-content">
            <div class="report-section">
                <div class="report-section-title">
                    <i class="fas fa-list"></i>
                    今日工作内容
                </div>
                <ul class="report-list">
    `;

    if (todayTasks.length === 0) {
        html += '<li>今日暂无任务</li>';
    } else {
        todayTasks.forEach((task, index) => {
            const icon = categoryIcons[task.category] || '📋';
            const status = task.isCompleted ? '✅ 已完成' : '🔄 进行中';
            html += `
                <li>
                    <span class="report-task-title">${index + 1}. ${task.title}</span>
                    <span class="report-task-meta">${icon} ${task.category} | ${status}</span>
                </li>
            `;
        });
    }

    html += `
                </ul>
            </div>

            <div class="report-section">
                <div class="report-section-title">
                    <i class="fas fa-edit"></i>
                    今日工作总结
                </div>
    `;

    if (todayTasks.length === 0) {
        html += '<p>今日暂无工作总结</p>';
    } else {
        todayTasks.forEach((task, index) => {
            const icon = categoryIcons[task.category] || '📋';
            html += `
                <div class="report-subsection">
                    <div class="report-subsection-title">
                        ${index + 1}. ${task.title}
                    </div>
                    <p>详情：${task.description || '暂无详细说明'}</p>
                    <p>分类：${icon} ${task.category}</p>
                    <p>状态：${task.isCompleted ? '✅ 已完成' : '🔄 进行中'}</p>
                </div>
            `;
        });
    }

    html += `
            </div>

            <div class="report-section">
                <div class="report-section-title">
                    <i class="fas fa-target"></i>
                    下一步计划
                </div>
    `;

    if (ongoingTasks.length > 0) {
        html += `
            <div class="report-subsection">
                <div class="report-subsection-title">
                    <i class="fas fa-clock" style="color: orange;"></i>
                    今日待完成
                </div>
                <ul class="report-list">
        `;
        ongoingTasks.forEach((task, index) => {
            const icon = categoryIcons[task.category] || '📋';
            html += `
                <li>
                    <span class="report-task-title">• ${task.title}</span>
                    <span class="report-task-meta">${icon} ${task.category}</span>
                </li>
            `;
        });
        html += '</ul></div>';
    }

    if (futureTasks.length > 0) {
        html += `
            <div class="report-subsection">
                <div class="report-subsection-title">
                    <i class="fas fa-calendar" style="color: purple;"></i>
                    未来安排
                </div>
                <ul class="report-list">
        `;
        futureTasks.forEach((task, index) => {
            const icon = categoryIcons[task.category] || '📋';
            const taskDate = formatTaskDate(new Date(task.dueDate));
            html += `
                <li>
                    <span class="report-task-title">• ${task.title}</span>
                    <span class="report-task-meta">${icon} ${task.category} | ${taskDate}</span>
                </li>
            `;
        });
        html += '</ul></div>';
    }

    if (ongoingTasks.length === 0 && futureTasks.length === 0) {
        html += '<p>暂无下一步计划</p>';
    }

    html += `
            </div>

            <div class="report-section">
                <div class="report-section-title">
                    <i class="fas fa-chart-bar"></i>
                    统计概览
                </div>
                <div class="report-stats">
                    <div class="report-stat-card">
                        <div class="report-stat-value">${todayTasks.length}</div>
                        <div class="report-stat-label">总任务</div>
                    </div>
                    <div class="report-stat-card">
                        <div class="report-stat-value">${completedTasks.length}</div>
                        <div class="report-stat-label">已完成</div>
                    </div>
                    <div class="report-stat-card">
                        <div class="report-stat-value">${todayTasks.length > 0 ? Math.round(completedTasks.length / todayTasks.length * 100) : 0}%</div>
                        <div class="report-stat-label">完成率</div>
                    </div>
                </div>
            </div>
        </div>
    `;

    return html;
}

function generateWeeklyReportHTML(weekTasks, tasksByCategory, weekStart, weekEnd) {
    const categoryIcons = {
        '工作': '💼',
        '学习': '📚',
        '运动': '🏃',
        '娱乐': '🎮',
        '生活': '🏠',
        '其他': '📝'
    };

    const completedTasks = weekTasks.filter(task => task.isCompleted);
    const ongoingTasks = weekTasks.filter(task => !task.isCompleted);

    let html = `
        <div class="report-content">
            <div class="report-section">
                <div class="report-section-title">
                    <i class="fas fa-list"></i>
                    本周工作内容
                </div>
                <ul class="report-list">
    `;

    if (weekTasks.length === 0) {
        html += '<li>本周暂无任务</li>';
    } else {
        weekTasks.forEach((task, index) => {
            const icon = categoryIcons[task.category] || '📋';
            const status = task.isCompleted ? '✅ 已完成' : '🔄 进行中';
            html += `
                <li>
                    <span class="report-task-title">${index + 1}. ${task.title}</span>
                    <span class="report-task-meta">${icon} ${task.category} | ${status}</span>
                </li>
            `;
        });
    }

    html += `
                </ul>
            </div>

            <div class="report-section">
                <div class="report-section-title">
                    <i class="fas fa-edit"></i>
                    本周工作总结
                </div>
    `;

    if (Object.keys(tasksByCategory).length === 0) {
        html += '<p>本周暂无工作总结</p>';
    } else {
        Object.keys(tasksByCategory).sort().forEach(category => {
            const tasks = tasksByCategory[category];
            const completed = tasks.filter(task => task.isCompleted);
            const ongoing = tasks.filter(task => !task.isCompleted);
            const icon = categoryIcons[category] || '📋';

            html += `
                <div class="report-subsection">
                    <div class="report-subsection-title">
                        ${icon} ${category} (${completed.length}/${tasks.length} 完成)
                    </div>
            `;

            if (completed.length > 0) {
                html += '<p><strong>✅ 已完成：</strong></p><ul class="report-list">';
                completed.forEach(task => {
                    html += `<li><span class="report-task-title">• ${task.title}</span></li>`;
                });
                html += '</ul>';
            }

            if (ongoing.length > 0) {
                html += '<p><strong>🔄 进行中：</strong></p><ul class="report-list">';
                ongoing.forEach(task => {
                    html += `<li><span class="report-task-title">• ${task.title}</span></li>`;
                });
                html += '</ul>';
            }

            html += '</div>';
        });
    }

    html += `
            </div>

            <div class="report-section">
                <div class="report-section-title">
                    <i class="fas fa-target"></i>
                    下周计划
                </div>
    `;

    if (ongoingTasks.length === 0) {
        html += '<p>暂无下周计划</p>';
    } else {
        html += '<p>继续推进以下任务：</p><ul class="report-list">';
        ongoingTasks.forEach((task, index) => {
            const icon = categoryIcons[task.category] || '📋';
            html += `
                <li>
                    <span class="report-task-title">${index + 1}. ${task.title}</span>
                    <span class="report-task-meta">${icon} ${task.category}</span>
                </li>
            `;
        });
        html += '</ul>';
    }

    html += `
            </div>

            <div class="report-section">
                <div class="report-section-title">
                    <i class="fas fa-chart-bar"></i>
                    本周统计
                </div>
                <div class="report-stats">
                    <div class="report-stat-card">
                        <div class="report-stat-value">${weekTasks.length}</div>
                        <div class="report-stat-label">总任务</div>
                    </div>
                    <div class="report-stat-card">
                        <div class="report-stat-value">${completedTasks.length}</div>
                        <div class="report-stat-label">已完成</div>
                    </div>
                    <div class="report-stat-card">
                        <div class="report-stat-value">${weekTasks.length > 0 ? Math.round(completedTasks.length / weekTasks.length * 100) : 0}%</div>
                        <div class="report-stat-label">完成率</div>
                    </div>
                    <div class="report-stat-card">
                        <div class="report-stat-value">${ongoingTasks.length}</div>
                        <div class="report-stat-label">进行中</div>
                    </div>
                </div>
    `;

    if (Object.keys(tasksByCategory).length > 0) {
        html += `
                <div style="margin-top: 20px;">
                    <h4>分类统计</h4>
                    <ul class="report-list">
        `;
        Object.keys(tasksByCategory).sort().forEach(category => {
            const tasks = tasksByCategory[category];
            const completed = tasks.filter(task => task.isCompleted).length;
            const icon = categoryIcons[category] || '📋';
            html += `
                <li>
                    <span class="report-task-title">${icon} ${category}</span>
                    <span class="report-task-meta">${completed}/${tasks.length}</span>
                </li>
            `;
        });
        html += '</ul></div>';
    }

    html += `
            </div>
        </div>
    `;

    return html;
}

// 日期格式化辅助函数
function formatDate(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}年${month}月${day}日`;
}

function formatWeekRange(startDate, endDate) {
    const startMonth = String(startDate.getMonth() + 1).padStart(2, '0');
    const startDay = String(startDate.getDate()).padStart(2, '0');
    const endMonth = String(endDate.getMonth() + 1).padStart(2, '0');
    const endDay = String(endDate.getDate()).padStart(2, '0');
    return `${startMonth}月${startDay}日 - ${endMonth}月${endDay}日`;
}

function formatTaskDate(date) {
    const today = new Date();
    const tomorrow = new Date(today.getTime() + 24 * 60 * 60 * 1000);
    const dayAfterTomorrow = new Date(today.getTime() + 2 * 24 * 60 * 60 * 1000);

    const taskDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    const todayDate = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    const tomorrowDate = new Date(tomorrow.getFullYear(), tomorrow.getMonth(), tomorrow.getDate());
    const dayAfterTomorrowDate = new Date(dayAfterTomorrow.getFullYear(), dayAfterTomorrow.getMonth(), dayAfterTomorrow.getDate());

    if (taskDate.getTime() === todayDate.getTime()) {
        return '今天';
    } else if (taskDate.getTime() === tomorrowDate.getTime()) {
        return '明天';
    } else if (taskDate.getTime() === dayAfterTomorrowDate.getTime()) {
        return '后天';
    } else {
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return `${month}月${day}日`;
    }
}

function getWeekStart(date) {
    const d = new Date(date);
    const day = d.getDay();
    const diff = d.getDate() - day + (day === 0 ? -6 : 1); // 调整为周一开始
    return new Date(d.setDate(diff));
}

// 生成纯文本报告用于复制
function generateReportText(htmlContent) {
    // 创建临时div来解析HTML
    const tempDiv = document.createElement('div');
    tempDiv.innerHTML = htmlContent;

    // 提取文本内容
    let text = '';

    // 获取报告标题
    const title = document.getElementById('reportTitle').textContent;
    text += title + '\n\n';

    // 遍历所有section
    const sections = tempDiv.querySelectorAll('.report-section');
    sections.forEach(section => {
        const sectionTitle = section.querySelector('.report-section-title');
        if (sectionTitle) {
            text += sectionTitle.textContent.trim() + '：\n';
        }

        // 处理列表
        const lists = section.querySelectorAll('.report-list');
        lists.forEach(list => {
            const items = list.querySelectorAll('li');
            items.forEach(item => {
                const taskTitle = item.querySelector('.report-task-title');
                if (taskTitle) {
                    text += taskTitle.textContent.trim() + '\n';
                } else {
                    text += item.textContent.trim() + '\n';
                }
            });
        });

        // 处理子section
        const subsections = section.querySelectorAll('.report-subsection');
        subsections.forEach(subsection => {
            const subsectionTitle = subsection.querySelector('.report-subsection-title');
            if (subsectionTitle) {
                text += '\n' + subsectionTitle.textContent.trim() + '\n';
            }

            const paragraphs = subsection.querySelectorAll('p');
            paragraphs.forEach(p => {
                if (p.textContent.trim()) {
                    text += p.textContent.trim() + '\n';
                }
            });

            const sublists = subsection.querySelectorAll('.report-list');
            sublists.forEach(list => {
                const items = list.querySelectorAll('li');
                items.forEach(item => {
                    const taskTitle = item.querySelector('.report-task-title');
                    if (taskTitle) {
                        text += taskTitle.textContent.trim() + '\n';
                    }
                });
            });
        });

        // 处理统计数据
        const stats = section.querySelectorAll('.report-stat-card');
        if (stats.length > 0) {
            stats.forEach(stat => {
                const value = stat.querySelector('.report-stat-value');
                const label = stat.querySelector('.report-stat-label');
                if (value && label) {
                    text += `• ${label.textContent}：${value.textContent}\n`;
                }
            });
        }

        text += '\n';
    });

    return text.trim();
}

// 初始化任务管理器
const taskManager = new TaskManager();

// 全局错误处理
window.addEventListener('error', (event) => {
    console.error('❌ 全局错误:', event.error);
});

// 页面加载完成后的初始化
document.addEventListener('DOMContentLoaded', () => {
    console.log('🚀 TaskFlow Web版已启动');
    console.log('📱 专业的个人效率提升工具');
    console.log('🌐 WebSocket服务器: ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082');

    // 添加一些快捷键
    document.addEventListener('keydown', (e) => {
        // Ctrl/Cmd + N 添加新任务
        if ((e.ctrlKey || e.metaKey) && e.key === 'n') {
            e.preventDefault();
            showAddTaskModal();
        }

        // Ctrl/Cmd + F 聚焦搜索框
        if ((e.ctrlKey || e.metaKey) && e.key === 'f') {
            e.preventDefault();
            document.getElementById('searchInput').focus();
        }
    });
});
