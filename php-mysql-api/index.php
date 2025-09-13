<?php
/**
 * PHP MySQL API 主入口文件
 * 轻量级API服务器，专门用于Kids Schedule App
 */

require_once 'config.php';

handleOptionsRequest();

// 路由处理
$requestUri = $_SERVER['REQUEST_URI'];
$path = parse_url($requestUri, PHP_URL_PATH);

// 移除查询参数
$path = strtok($path, '?');

// 路由映射
switch ($path) {
    case '/':
    case '/index.php':
        showWelcome();
        break;
        
    case '/health':
        require 'health.php';
        break;
        
    case '/api/tasks':
        require 'tasks.php';
        break;
        
    case '/api/pomodoro-sessions':
        require 'pomodoro.php';
        break;
        
    default:
        errorResponse('API端点不存在', 404);
}

/**
 * 显示欢迎信息
 */
function showWelcome() {
    setCORSHeaders();
    
    $info = [
        'name' => 'Kids Schedule App MySQL API',
        'version' => API_VERSION,
        'timestamp' => date('c'),
        'endpoints' => [
            'health' => '/health',
            'tasks' => '/api/tasks',
            'pomodoro' => '/api/pomodoro-sessions'
        ],
        'methods' => [
            'GET /health' => '健康检查',
            'GET /api/tasks?user_id=xxx' => '获取任务列表',
            'POST /api/tasks' => '创建新任务',
            'PUT /api/tasks' => '更新任务',
            'DELETE /api/tasks?id=xxx' => '删除任务',
            'GET /api/pomodoro-sessions?user_id=xxx' => '获取番茄工作法会话',
            'POST /api/pomodoro-sessions' => '创建新会话',
            'PUT /api/pomodoro-sessions' => '更新会话',
            'DELETE /api/pomodoro-sessions?id=xxx' => '删除会话'
        ],
        'database' => [
            'host' => DB_HOST,
            'name' => DB_NAME,
            'charset' => DB_CHARSET
        ]
    ];
    
    echo json_encode($info, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
}
?>
