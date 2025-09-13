<?php
/**
 * 任务管理API端点
 */

require_once 'config.php';

handleOptionsRequest();

$method = $_SERVER['REQUEST_METHOD'];
$pdo = getDBConnection();

if ($pdo === null) {
    errorResponse('数据库连接失败', 500);
}

switch ($method) {
    case 'GET':
        getTasks($pdo);
        break;
    case 'POST':
        createTask($pdo);
        break;
    case 'PUT':
        updateTask($pdo);
        break;
    case 'DELETE':
        deleteTask($pdo);
        break;
    default:
        errorResponse('不支持的请求方法', 405);
}

/**
 * 获取任务列表
 */
function getTasks($pdo) {
    $userId = $_GET['user_id'] ?? null;
    
    if (!$userId) {
        errorResponse('user_id参数是必需的');
    }
    
    try {
        $stmt = $pdo->prepare("
            SELECT id, user_id, title, description, due_date, is_completed, 
                   device_id, created_at, updated_at
            FROM tasks 
            WHERE user_id = ? 
            ORDER BY created_at DESC
        ");
        
        $stmt->execute([$userId]);
        $tasks = $stmt->fetchAll();
        
        // 格式化日期
        foreach ($tasks as &$task) {
            if ($task['due_date']) {
                $task['due_date'] = date('c', strtotime($task['due_date']));
            }
            if ($task['created_at']) {
                $task['created_at'] = date('c', strtotime($task['created_at']));
            }
            if ($task['updated_at']) {
                $task['updated_at'] = date('c', strtotime($task['updated_at']));
            }
            // 转换布尔值
            $task['is_completed'] = (bool)$task['is_completed'];
        }
        
        logMessage("获取任务列表: 用户 $userId, 共 " . count($tasks) . " 个任务");
        jsonResponse($tasks);
        
    } catch (PDOException $e) {
        logMessage("获取任务失败: " . $e->getMessage());
        errorResponse('获取任务失败', 500);
    }
}

/**
 * 创建新任务
 */
function createTask($pdo) {
    $data = getRequestData();
    
    if (!$data) {
        errorResponse('无效的JSON数据');
    }
    
    // 验证必填字段
    validateRequiredFields($data, ['id', 'user_id', 'title']);
    
    // 记录接收到的数据
    logMessage("收到任务数据: " . json_encode($data, JSON_UNESCAPED_UNICODE));
    
    // 验证字段格式（检查是否使用了正确的下划线命名法）
    $expectedFields = ['id', 'user_id', 'title', 'description', 'due_date', 'is_completed', 'device_id'];
    $receivedFields = array_keys($data);
    
    logMessage("期望字段: " . implode(', ', $expectedFields));
    logMessage("收到字段: " . implode(', ', $receivedFields));
    
    // 检查是否有驼峰命名法字段
    $camelCaseFields = array_intersect($receivedFields, ['userId', 'dueDate', 'isCompleted', 'deviceId']);
    
    if (!empty($camelCaseFields)) {
        logMessage("❌ 发现驼峰命名法字段: " . implode(', ', $camelCaseFields));
        errorResponse("字段名格式错误，发现驼峰命名法字段: " . implode(', ', $camelCaseFields) . "。应使用下划线格式。");
    }
    
    logMessage("✅ 字段格式正确，使用下划线命名法");
    
    try {
        $stmt = $pdo->prepare("
            INSERT INTO tasks (id, user_id, title, description, due_date, is_completed, device_id, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
        ");
        
        $result = $stmt->execute([
            $data['id'],
            $data['user_id'],
            $data['title'],
            $data['description'] ?? '',
            $data['due_date'] ?? null,
            $data['is_completed'] ?? false,
            $data['device_id'] ?? ''
        ]);
        
        if ($result) {
            logMessage("✅ 任务创建成功: " . $data['title']);
            jsonResponse([
                'message' => '任务创建成功',
                'task_id' => $data['id']
            ], 201);
        } else {
            logMessage("❌ 任务创建失败");
            errorResponse('任务创建失败', 500);
        }
        
    } catch (PDOException $e) {
        logMessage("❌ 创建任务失败: " . $e->getMessage());
        
        // 检查是否是重复ID错误
        if ($e->getCode() == 23000) {
            errorResponse('任务ID已存在', 409);
        } else {
            errorResponse('保存任务失败', 500);
        }
    }
}

/**
 * 更新任务
 */
function updateTask($pdo) {
    $data = getRequestData();
    
    if (!$data || !isset($data['id'])) {
        errorResponse('缺少任务ID');
    }
    
    try {
        $updateFields = [];
        $values = [];
        
        if (isset($data['title'])) {
            $updateFields[] = 'title = ?';
            $values[] = $data['title'];
        }
        if (isset($data['description'])) {
            $updateFields[] = 'description = ?';
            $values[] = $data['description'];
        }
        if (isset($data['due_date'])) {
            $updateFields[] = 'due_date = ?';
            $values[] = $data['due_date'];
        }
        if (isset($data['is_completed'])) {
            $updateFields[] = 'is_completed = ?';
            $values[] = $data['is_completed'];
        }
        
        if (empty($updateFields)) {
            errorResponse('没有要更新的字段');
        }
        
        $updateFields[] = 'updated_at = NOW()';
        $values[] = $data['id'];
        
        $sql = "UPDATE tasks SET " . implode(', ', $updateFields) . " WHERE id = ?";
        $stmt = $pdo->prepare($sql);
        $result = $stmt->execute($values);
        
        if ($stmt->rowCount() > 0) {
            logMessage("✅ 任务更新成功: " . $data['id']);
            jsonResponse(['message' => '任务更新成功']);
        } else {
            errorResponse('任务不存在或无变化', 404);
        }
        
    } catch (PDOException $e) {
        logMessage("❌ 更新任务失败: " . $e->getMessage());
        errorResponse('更新任务失败', 500);
    }
}

/**
 * 删除任务
 */
function deleteTask($pdo) {
    $taskId = $_GET['id'] ?? null;
    
    if (!$taskId) {
        errorResponse('缺少任务ID');
    }
    
    try {
        $stmt = $pdo->prepare("DELETE FROM tasks WHERE id = ?");
        $result = $stmt->execute([$taskId]);
        
        if ($stmt->rowCount() > 0) {
            logMessage("✅ 任务删除成功: " . $taskId);
            jsonResponse(['message' => '任务删除成功']);
        } else {
            errorResponse('任务不存在', 404);
        }
        
    } catch (PDOException $e) {
        logMessage("❌ 删除任务失败: " . $e->getMessage());
        errorResponse('删除任务失败', 500);
    }
}
?>
