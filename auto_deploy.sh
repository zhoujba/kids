#!/bin/bash

# 自动部署脚本 - Git监控和自动发布到AWS
# 监控git仓库变化，自动编译和部署WebSocket服务器

set -e

# 配置
SERVER_HOST="ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com"
SERVER_USER="ec2-user"
KEY_PATH="~/Downloads/miyao.pem"
REMOTE_DIR="~/websocket-server-new"
PORT="8082"
BRANCH="main"
CHECK_INTERVAL=30  # 检查间隔（秒）

echo "🚀 启动自动部署监控系统..."
echo "📡 监控分支: $BRANCH"
echo "⏰ 检查间隔: ${CHECK_INTERVAL}秒"
echo "🎯 目标服务器: $SERVER_HOST"
echo ""

# 获取当前commit hash
get_current_commit() {
    git rev-parse HEAD
}

# 检查是否有新的提交
check_for_updates() {
    git fetch origin $BRANCH >/dev/null 2>&1
    local remote_commit=$(git rev-parse origin/$BRANCH)
    local local_commit=$(get_current_commit)
    
    if [ "$remote_commit" != "$local_commit" ]; then
        echo "🔄 发现新提交: $remote_commit"
        return 0
    else
        return 1
    fi
}

# 部署函数
deploy_to_server() {
    echo "🚀 开始自动部署..."
    
    # 1. 拉取最新代码
    echo "📥 拉取最新代码..."
    git pull origin $BRANCH
    
    # 2. 编译WebSocket服务器
    echo "📦 编译WebSocket服务器..."
    cd websocket-server
    
    # 检查go.mod文件
    if [ ! -f "go.mod" ]; then
        echo "❌ 未找到go.mod文件"
        cd ..
        return 1
    fi
    
    # 下载依赖
    go mod tidy
    
    # 交叉编译为Linux版本
    GOOS=linux GOARCH=amd64 CGO_ENABLED=1 go build -o websocket-server-linux main.go
    
    if [ $? -ne 0 ]; then
        echo "❌ 编译失败"
        cd ..
        return 1
    fi
    
    echo "✅ 编译成功"
    cd ..
    
    # 3. 部署到服务器
    echo "📤 部署到服务器..."
    
    # 上传二进制文件
    scp -i "$KEY_PATH" websocket-server/websocket-server-linux "$SERVER_USER@$SERVER_HOST:$REMOTE_DIR/"
    
    # 在服务器上重启服务
    ssh -i "$KEY_PATH" "$SERVER_USER@$SERVER_HOST" << EOF
        cd $REMOTE_DIR
        
        # 停止旧进程
        echo "🛑 停止旧进程..."
        PORT_PID=\$(lsof -ti:$PORT 2>/dev/null || true)
        if [ ! -z "\$PORT_PID" ]; then
            echo "🗑️ 杀死进程 \$PORT_PID"
            kill -9 \$PORT_PID
            sleep 2
        fi
        
        # 设置执行权限
        chmod +x websocket-server-linux
        
        # 启动新进程
        echo "🚀 启动新进程..."
        nohup ./websocket-server-linux > websocket.log 2>&1 &
        
        # 等待启动
        sleep 3
        
        # 检查进程状态
        if pgrep -f websocket-server-linux > /dev/null; then
            echo "✅ WebSocket服务器启动成功"
            echo "📡 服务地址: ws://$SERVER_HOST:$PORT/ws"
        else
            echo "❌ WebSocket服务器启动失败"
            exit 1
        fi
EOF
    
    if [ $? -eq 0 ]; then
        echo "🎉 部署成功！"
        echo "📊 部署时间: $(date)"
        echo "📡 WebSocket端点: ws://$SERVER_HOST:$PORT/ws"
        return 0
    else
        echo "❌ 部署失败"
        return 1
    fi
}

# 主监控循环
main_loop() {
    local last_commit=$(get_current_commit)
    echo "📍 当前commit: $last_commit"
    echo "👀 开始监控git仓库变化..."
    echo ""
    
    while true; do
        if check_for_updates; then
            echo "🔔 检测到代码更新，开始自动部署..."
            
            if deploy_to_server; then
                last_commit=$(get_current_commit)
                echo "✅ 自动部署完成，当前commit: $last_commit"
            else
                echo "❌ 自动部署失败，将在下次检查时重试"
            fi
            echo ""
        else
            echo "⏰ $(date '+%H:%M:%S') - 无更新，继续监控..."
        fi
        
        sleep $CHECK_INTERVAL
    done
}

# 信号处理
cleanup() {
    echo ""
    echo "🛑 收到停止信号，正在退出..."
    exit 0
}

trap cleanup SIGINT SIGTERM

# 检查依赖
echo "🔍 检查依赖..."

# 检查git
if ! command -v git &> /dev/null; then
    echo "❌ 未找到git命令"
    exit 1
fi

# 检查go
if ! command -v go &> /dev/null; then
    echo "❌ 未找到go命令"
    exit 1
fi

# 检查SSH密钥
if [ ! -f "$(eval echo $KEY_PATH)" ]; then
    echo "❌ 未找到SSH密钥文件: $KEY_PATH"
    exit 1
fi

# 检查是否在git仓库中
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ 当前目录不是git仓库"
    exit 1
fi

echo "✅ 依赖检查通过"
echo ""

# 启动监控
main_loop
