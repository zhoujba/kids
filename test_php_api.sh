#!/bin/bash

# PHP API测试脚本
# 用于测试本地PHP API服务器

echo "🧪 测试PHP MySQL API"
echo "===================="

# 配置
BASE_URL="http://localhost:8080/php-mysql-api"
USER_ID="default_user"

echo ""
echo "📍 API地址: $BASE_URL"
echo ""

# 1. 测试健康检查
echo "1️⃣ 测试健康检查..."
curl -s "$BASE_URL/health" | jq '.' || echo "健康检查失败"
echo ""

# 2. 测试创建任务（正确的下划线格式）
echo "2️⃣ 测试创建任务（下划线格式）..."
curl -s -X POST "$BASE_URL/api/tasks" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-task-001",
    "user_id": "default_user",
    "title": "测试任务1",
    "description": "这是一个测试任务",
    "due_date": "2025-09-12T18:00:00Z",
    "is_completed": false,
    "device_id": "test-device"
  }' | jq '.' || echo "创建任务失败"
echo ""

# 3. 测试创建任务（错误的驼峰格式）
echo "3️⃣ 测试创建任务（驼峰格式 - 应该失败）..."
curl -s -X POST "$BASE_URL/api/tasks" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-task-002",
    "userId": "default_user",
    "title": "测试任务2",
    "description": "这应该失败",
    "dueDate": "2025-09-12T18:00:00Z",
    "isCompleted": false,
    "deviceId": "test-device"
  }' | jq '.' || echo "创建任务失败（预期）"
echo ""

# 4. 测试获取任务列表
echo "4️⃣ 测试获取任务列表..."
curl -s "$BASE_URL/api/tasks?user_id=$USER_ID" | jq '.' || echo "获取任务失败"
echo ""

# 5. 测试更新任务
echo "5️⃣ 测试更新任务..."
curl -s -X PUT "$BASE_URL/api/tasks" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-task-001",
    "title": "更新后的任务标题",
    "is_completed": true
  }' | jq '.' || echo "更新任务失败"
echo ""

# 6. 测试创建番茄工作法会话
echo "6️⃣ 测试创建番茄工作法会话..."
curl -s -X POST "$BASE_URL/api/pomodoro-sessions" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "session-001",
    "user_id": "default_user",
    "task_id": "test-task-001",
    "duration": 25,
    "start_time": "2025-09-12T14:00:00Z",
    "end_time": "2025-09-12T14:25:00Z",
    "is_completed": true,
    "device_id": "test-device"
  }' | jq '.' || echo "创建会话失败"
echo ""

# 7. 测试获取番茄工作法会话列表
echo "7️⃣ 测试获取番茄工作法会话列表..."
curl -s "$BASE_URL/api/pomodoro-sessions?user_id=$USER_ID" | jq '.' || echo "获取会话失败"
echo ""

echo "✅ 测试完成！"
echo ""
echo "💡 提示："
echo "   - 如果看到JSON响应，说明API工作正常"
echo "   - 如果看到错误信息，请检查PHP服务器配置"
echo "   - 确保MySQL数据库已正确设置"
