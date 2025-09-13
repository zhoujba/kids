<?php
/**
 * MySQL数据库配置文件
 */

// 数据库配置
define('DB_HOST', 'localhost');
define('DB_PORT', 3306);
define('DB_NAME', 'kids_schedule');
define('DB_USER', 'kidsapp');
define('DB_PASS', 'KidsApp2025!');
define('DB_CHARSET', 'utf8mb4');

// API配置
define('API_VERSION', '1.0');
define('CORS_ORIGIN', '*');

// 错误报告（生产环境设为0）
error_reporting(E_ALL);
ini_set('display_errors', 1);

// 时区设置
date_default_timezone_set('Asia/Shanghai');

/**
 * 获取数据库连接
 */
function getDBConnection() {
    try {
        $dsn = "mysql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME . ";charset=" . DB_CHARSET;
        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]);
        return $pdo;
    } catch (PDOException $e) {
        error_log("数据库连接失败: " . $e->getMessage());
        return null;
    }
}

/**
 * 设置CORS头
 */
function setCORSHeaders() {
    header("Access-Control-Allow-Origin: " . CORS_ORIGIN);
    header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
    header("Access-Control-Allow-Headers: Content-Type, Authorization");
    header("Content-Type: application/json; charset=UTF-8");
}

/**
 * 处理OPTIONS请求
 */
function handleOptionsRequest() {
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        setCORSHeaders();
        http_response_code(200);
        exit();
    }
}

/**
 * 返回JSON响应
 */
function jsonResponse($data, $statusCode = 200) {
    setCORSHeaders();
    http_response_code($statusCode);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit();
}

/**
 * 返回错误响应
 */
function errorResponse($message, $statusCode = 400) {
    jsonResponse(['error' => $message], $statusCode);
}

/**
 * 获取请求体JSON数据
 */
function getRequestData() {
    $input = file_get_contents('php://input');
    return json_decode($input, true);
}

/**
 * 验证必填字段
 */
function validateRequiredFields($data, $requiredFields) {
    foreach ($requiredFields as $field) {
        if (!isset($data[$field]) || empty($data[$field])) {
            errorResponse("缺少必填字段: $field");
        }
    }
}

/**
 * 记录日志
 */
function logMessage($message) {
    $timestamp = date('Y-m-d H:i:s');
    echo "[$timestamp] $message\n";
    error_log("[$timestamp] $message");
}
?>
