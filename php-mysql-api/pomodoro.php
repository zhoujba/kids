<?php
/**
 * 番茄工作法会话管理API端点
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
        getPomodoroSessions($pdo);
        break;
    case 'POST':
        createPomodoroSession($pdo);
        break;
    case 'PUT':
        updatePomodoroSession($pdo);
        break;
    case 'DELETE':
        deletePomodoroSession($pdo);
        break;
    default:
        errorResponse('不支持的请求方法', 405);
}

/**
 * 获取番茄工作法会话列表
 */
function getPomodoroSessions($pdo) {
    $userId = $_GET['user_id'] ?? null;
    
    if (!$userId) {
        errorResponse('user_id参数是必需的');
    }
    
    try {
        $stmt = $pdo->prepare("
            SELECT id, user_id, task_id, duration, start_time, end_time, 
                   is_completed, device_id, created_at, updated_at
            FROM pomodoro_sessions 
            WHERE user_id = ? 
            ORDER BY start_time DESC
        ");
        
        $stmt->execute([$userId]);
        $sessions = $stmt->fetchAll();
        
        // 格式化日期
        foreach ($sessions as &$session) {
            if ($session['start_time']) {
                $session['start_time'] = date('c', strtotime($session['start_time']));
            }
            if ($session['end_time']) {
                $session['end_time'] = date('c', strtotime($session['end_time']));
            }
            if ($session['created_at']) {
                $session['created_at'] = date('c', strtotime($session['created_at']));
            }
            if ($session['updated_at']) {
                $session['updated_at'] = date('c', strtotime($session['updated_at']));
            }
            // 转换布尔值
            $session['is_completed'] = (bool)$session['is_completed'];
        }
        
        logMessage("获取番茄工作法会话: 用户 $userId, 共 " . count($sessions) . " 个会话");
        jsonResponse($sessions);
        
    } catch (PDOException $e) {
        logMessage("获取会话失败: " . $e->getMessage());
        errorResponse('获取会话失败', 500);
    }
}

/**
 * 创建新的番茄工作法会话
 */
function createPomodoroSession($pdo) {
    $data = getRequestData();
    
    if (!$data) {
        errorResponse('无效的JSON数据');
    }
    
    // 验证必填字段
    validateRequiredFields($data, ['id', 'user_id', 'duration', 'start_time']);
    
    logMessage("收到番茄工作法会话数据: " . json_encode($data, JSON_UNESCAPED_UNICODE));
    
    try {
        $stmt = $pdo->prepare("
            INSERT INTO pomodoro_sessions (id, user_id, task_id, duration, start_time, end_time, is_completed, device_id, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
        ");
        
        $result = $stmt->execute([
            $data['id'],
            $data['user_id'],
            $data['task_id'] ?? null,
            $data['duration'],
            $data['start_time'],
            $data['end_time'] ?? null,
            $data['is_completed'] ?? false,
            $data['device_id'] ?? ''
        ]);
        
        if ($result) {
            logMessage("✅ 番茄工作法会话创建成功: " . $data['duration'] . "分钟");
            jsonResponse([
                'message' => '会话创建成功',
                'session_id' => $data['id']
            ], 201);
        } else {
            logMessage("❌ 会话创建失败");
            errorResponse('会话创建失败', 500);
        }
        
    } catch (PDOException $e) {
        logMessage("❌ 创建会话失败: " . $e->getMessage());
        
        if ($e->getCode() == 23000) {
            errorResponse('会话ID已存在', 409);
        } else {
            errorResponse('保存会话失败', 500);
        }
    }
}

/**
 * 更新番茄工作法会话
 */
function updatePomodoroSession($pdo) {
    $data = getRequestData();
    
    if (!$data || !isset($data['id'])) {
        errorResponse('缺少会话ID');
    }
    
    try {
        $updateFields = [];
        $values = [];
        
        if (isset($data['duration'])) {
            $updateFields[] = 'duration = ?';
            $values[] = $data['duration'];
        }
        if (isset($data['start_time'])) {
            $updateFields[] = 'start_time = ?';
            $values[] = $data['start_time'];
        }
        if (isset($data['end_time'])) {
            $updateFields[] = 'end_time = ?';
            $values[] = $data['end_time'];
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
        
        $sql = "UPDATE pomodoro_sessions SET " . implode(', ', $updateFields) . " WHERE id = ?";
        $stmt = $pdo->prepare($sql);
        $result = $stmt->execute($values);
        
        if ($stmt->rowCount() > 0) {
            logMessage("✅ 会话更新成功: " . $data['id']);
            jsonResponse(['message' => '会话更新成功']);
        } else {
            errorResponse('会话不存在或无变化', 404);
        }
        
    } catch (PDOException $e) {
        logMessage("❌ 更新会话失败: " . $e->getMessage());
        errorResponse('更新会话失败', 500);
    }
}

/**
 * 删除番茄工作法会话
 */
function deletePomodoroSession($pdo) {
    $sessionId = $_GET['id'] ?? null;
    
    if (!$sessionId) {
        errorResponse('缺少会话ID');
    }
    
    try {
        $stmt = $pdo->prepare("DELETE FROM pomodoro_sessions WHERE id = ?");
        $result = $stmt->execute([$sessionId]);
        
        if ($stmt->rowCount() > 0) {
            logMessage("✅ 会话删除成功: " . $sessionId);
            jsonResponse(['message' => '会话删除成功']);
        } else {
            errorResponse('会话不存在', 404);
        }
        
    } catch (PDOException $e) {
        logMessage("❌ 删除会话失败: " . $e->getMessage());
        errorResponse('删除会话失败', 500);
    }
}
?>
