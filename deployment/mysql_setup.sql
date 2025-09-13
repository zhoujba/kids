-- Kids Schedule App 数据库初始化脚本
-- 创建所需的数据表和索引

-- 使用数据库
USE kids_schedule;

-- 删除已存在的表（如果存在）
DROP TABLE IF EXISTS sync_status;
DROP TABLE IF EXISTS pomodoro_sessions;
DROP TABLE IF EXISTS tasks;

-- 创建任务表
CREATE TABLE tasks (
    id VARCHAR(255) PRIMARY KEY COMMENT '任务唯一标识符',
    user_id VARCHAR(255) NOT NULL COMMENT '用户ID',
    title VARCHAR(500) NOT NULL COMMENT '任务标题',
    description TEXT COMMENT '任务描述',
    due_date DATETIME COMMENT '截止日期',
    is_completed BOOLEAN DEFAULT FALSE COMMENT '是否完成',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    device_id VARCHAR(255) COMMENT '设备ID',
    
    -- 索引
    INDEX idx_user_id (user_id),
    INDEX idx_due_date (due_date),
    INDEX idx_updated_at (updated_at),
    INDEX idx_is_completed (is_completed),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='任务表';

-- 创建番茄工作法会话表
CREATE TABLE pomodoro_sessions (
    id VARCHAR(255) PRIMARY KEY COMMENT '会话唯一标识符',
    user_id VARCHAR(255) NOT NULL COMMENT '用户ID',
    task_id VARCHAR(255) COMMENT '关联的任务ID',
    duration INT NOT NULL COMMENT '持续时间（分钟）',
    start_time DATETIME NOT NULL COMMENT '开始时间',
    end_time DATETIME COMMENT '结束时间',
    is_completed BOOLEAN DEFAULT FALSE COMMENT '是否完成',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    device_id VARCHAR(255) COMMENT '设备ID',
    
    -- 索引
    INDEX idx_user_id (user_id),
    INDEX idx_task_id (task_id),
    INDEX idx_start_time (start_time),
    INDEX idx_updated_at (updated_at),
    INDEX idx_is_completed (is_completed),
    
    -- 外键约束（可选）
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='番茄工作法会话表';

-- 创建同步状态表
CREATE TABLE sync_status (
    device_id VARCHAR(255) PRIMARY KEY COMMENT '设备ID',
    user_id VARCHAR(255) NOT NULL COMMENT '用户ID',
    last_sync_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后同步时间',
    device_name VARCHAR(255) COMMENT '设备名称',
    app_version VARCHAR(50) COMMENT '应用版本',
    sync_count INT DEFAULT 0 COMMENT '同步次数',
    
    -- 索引
    INDEX idx_user_id (user_id),
    INDEX idx_last_sync_time (last_sync_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='同步状态表';

-- 插入测试数据（可选）
INSERT INTO tasks (id, user_id, title, description, due_date, is_completed, device_id) VALUES
('test-task-001', 'default_user', '完成数学作业', '第10页练习题', '2025-09-13 18:00:00', FALSE, 'test-device'),
('test-task-002', 'default_user', '阅读英语课文', '第5章内容', '2025-09-14 16:00:00', FALSE, 'test-device'),
('test-task-003', 'default_user', '练习钢琴', '练习曲目：小星星', '2025-09-13 20:00:00', TRUE, 'test-device');

INSERT INTO pomodoro_sessions (id, user_id, task_id, duration, start_time, end_time, is_completed, device_id) VALUES
('session-001', 'default_user', 'test-task-001', 25, '2025-09-12 14:00:00', '2025-09-12 14:25:00', TRUE, 'test-device'),
('session-002', 'default_user', 'test-task-002', 25, '2025-09-12 15:00:00', '2025-09-12 15:25:00', TRUE, 'test-device');

INSERT INTO sync_status (device_id, user_id, device_name, app_version, sync_count) VALUES
('test-device', 'default_user', 'iPhone Test Device', '1.0.0', 5);

-- 显示表结构
SHOW TABLES;
DESCRIBE tasks;
DESCRIBE pomodoro_sessions;
DESCRIBE sync_status;

-- 显示数据统计
SELECT 'tasks' as table_name, COUNT(*) as record_count FROM tasks
UNION ALL
SELECT 'pomodoro_sessions', COUNT(*) FROM pomodoro_sessions
UNION ALL
SELECT 'sync_status', COUNT(*) FROM sync_status;
