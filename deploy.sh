#!/bin/bash

# WebSocket服务器部署脚本
# 用于自动化部署和重启WebSocket服务器

set -e  # 遇到错误立即退出

# 配置
SERVER_HOST="ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com"
SERVER_USER="ec2-user"
KEY_PATH="~/Downloads/miyao.pem"
LOCAL_SOURCE="websocket-server/main.go"
REMOTE_DIR="~/websocket-server-new"
REMOTE_BINARY="websocket-server"
PORT="8082"

echo "🚀 开始部署WebSocket服务器..."

# 1. 编译本地代码
echo "📦 编译Go程序..."
cd websocket-server
GOOS=linux GOARCH=amd64 go build -o ${REMOTE_BINARY} main.go
cd ..

# 2. 停止远程服务器上的旧进程
echo "🛑 停止远程服务器上的旧进程..."
ssh -i "${KEY_PATH}" ${SERVER_USER}@${SERVER_HOST} << 'EOF'
# 查找并杀死占用端口8082的进程
echo "🔍 查找占用端口8082的进程..."
PORT_PID=$(lsof -ti:8082 2>/dev/null || true)
if [ ! -z "$PORT_PID" ]; then
    echo "🗑️ 杀死进程 $PORT_PID"
    kill -9 $PORT_PID
    sleep 2
fi

# 查找并杀死所有go run进程
echo "🔍 查找go run进程..."
GO_PIDS=$(pgrep -f "go run" 2>/dev/null || true)
if [ ! -z "$GO_PIDS" ]; then
    echo "🗑️ 杀死go run进程: $GO_PIDS"
    pkill -f "go run" || true
    sleep 2
fi

# 查找并杀死websocket-server进程
echo "🔍 查找websocket-server进程..."
WS_PIDS=$(pgrep -f "websocket-server" 2>/dev/null || true)
if [ ! -z "$WS_PIDS" ]; then
    echo "🗑️ 杀死websocket-server进程: $WS_PIDS"
    pkill -f "websocket-server" || true
    sleep 2
fi

echo "✅ 旧进程清理完成"
EOF

# 3. 上传新的二进制文件
echo "📤 上传新的二进制文件..."
scp -i "${KEY_PATH}" websocket-server/${REMOTE_BINARY} ${SERVER_USER}@${SERVER_HOST}:${REMOTE_DIR}/

# 4. 启动新的服务器
echo "🚀 启动新的WebSocket服务器..."
ssh -i "${KEY_PATH}" ${SERVER_USER}@${SERVER_HOST} << EOF
cd ${REMOTE_DIR}
chmod +x ${REMOTE_BINARY}

# 使用nohup在后台运行服务器
nohup ./${REMOTE_BINARY} > websocket-server.log 2>&1 &

# 等待服务器启动
sleep 3

# 检查服务器是否启动成功
if lsof -ti:${PORT} > /dev/null 2>&1; then
    echo "✅ WebSocket服务器启动成功，监听端口 ${PORT}"
    echo "📋 进程ID: \$(pgrep -f ${REMOTE_BINARY})"
else
    echo "❌ WebSocket服务器启动失败"
    echo "📋 最近的日志:"
    tail -10 websocket-server.log
    exit 1
fi
EOF

echo "🎉 部署完成！"
echo "📡 WebSocket服务器地址: ws://${SERVER_HOST}:${PORT}/ws"
echo "🔗 REST API地址: http://${SERVER_HOST}:${PORT}/api/tasks"
echo ""
echo "📋 查看日志: ssh -i ${KEY_PATH} ${SERVER_USER}@${SERVER_HOST} 'tail -f ${REMOTE_DIR}/websocket-server.log'"
echo "🛑 停止服务器: ssh -i ${KEY_PATH} ${SERVER_USER}@${SERVER_HOST} 'pkill -f websocket-server'"
