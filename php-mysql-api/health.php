<?php
/**
 * 健康检查端点
 */

require_once 'config.php';

handleOptionsRequest();

try {
    // 测试数据库连接
    $pdo = getDBConnection();
    
    if ($pdo === null) {
        jsonResponse([
            'status' => 'ERROR',
            'timestamp' => date('c'),
            'message' => 'MySQL连接失败'
        ], 500);
    }
    
    // 测试数据库查询
    $stmt = $pdo->query("SELECT 1");
    $result = $stmt->fetch();
    
    if ($result) {
        jsonResponse([
            'status' => 'OK',
            'timestamp' => date('c'),
            'message' => 'MySQL连接正常',
            'version' => API_VERSION,
            'database' => DB_NAME
        ]);
    } else {
        jsonResponse([
            'status' => 'ERROR',
            'timestamp' => date('c'),
            'message' => 'MySQL查询失败'
        ], 500);
    }
    
} catch (Exception $e) {
    logMessage("健康检查失败: " . $e->getMessage());
    jsonResponse([
        'status' => 'ERROR',
        'timestamp' => date('c'),
        'message' => '服务器内部错误'
    ], 500);
}
?>
