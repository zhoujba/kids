#!/bin/bash

# Git Webhook自动部署设置脚本
# 在AWS服务器上设置git webhook，实现代码推送后自动部署

SERVER_HOST="ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com"
SERVER_USER="ec2-user"
KEY_PATH="~/Downloads/miyao.pem"
REPO_URL="https://github.com/YOUR_USERNAME/YOUR_REPO.git"  # 需要替换为实际的仓库地址
WEBHOOK_PORT="9000"

echo "🚀 设置Git Webhook自动部署系统..."

# 在服务器上创建webhook脚本
ssh -i "$KEY_PATH" "$SERVER_USER@$SERVER_HOST" << 'EOF'
# 创建webhook目录
mkdir -p ~/webhook
cd ~/webhook

# 创建webhook处理脚本
cat > webhook_handler.sh << 'WEBHOOK_SCRIPT'
#!/bin/bash

# Webhook处理脚本 - 接收git推送通知并自动部署

set -e

REPO_DIR="~/kids-schedule-app"
WEBSOCKET_DIR="~/websocket-server-new"
LOG_FILE="~/webhook/deploy.log"

echo "$(date): 收到webhook请求" >> $LOG_FILE

# 检查仓库目录是否存在
if [ ! -d "$REPO_DIR" ]; then
    echo "$(date): 克隆仓库..." >> $LOG_FILE
    git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git $REPO_DIR
else
    echo "$(date): 拉取最新代码..." >> $LOG_FILE
    cd $REPO_DIR
    git pull origin main
fi

cd $REPO_DIR

# 编译WebSocket服务器
echo "$(date): 编译WebSocket服务器..." >> $LOG_FILE
cd websocket-server

# 检查Go环境
if ! command -v go &> /dev/null; then
    echo "$(date): 错误 - 未找到Go环境" >> $LOG_FILE
    exit 1
fi

# 下载依赖并编译
go mod tidy
GOOS=linux GOARCH=amd64 CGO_ENABLED=1 go build -o websocket-server-linux main.go

if [ $? -ne 0 ]; then
    echo "$(date): 编译失败" >> $LOG_FILE
    exit 1
fi

# 复制到部署目录
cp websocket-server-linux $WEBSOCKET_DIR/

cd $WEBSOCKET_DIR

# 停止旧进程
echo "$(date): 停止旧进程..." >> $LOG_FILE
PORT_PID=$(lsof -ti:8082 2>/dev/null || true)
if [ ! -z "$PORT_PID" ]; then
    echo "$(date): 杀死进程 $PORT_PID" >> $LOG_FILE
    kill -9 $PORT_PID
    sleep 2
fi

# 设置执行权限
chmod +x websocket-server-linux

# 启动新进程
echo "$(date): 启动新进程..." >> $LOG_FILE
nohup ./websocket-server-linux > websocket.log 2>&1 &

# 等待启动
sleep 3

# 检查进程状态
if pgrep -f websocket-server-linux > /dev/null; then
    echo "$(date): WebSocket服务器启动成功" >> $LOG_FILE
else
    echo "$(date): WebSocket服务器启动失败" >> $LOG_FILE
    exit 1
fi

echo "$(date): 部署完成" >> $LOG_FILE
WEBHOOK_SCRIPT

chmod +x webhook_handler.sh

# 创建简单的HTTP服务器来接收webhook
cat > webhook_server.py << 'WEBHOOK_SERVER'
#!/usr/bin/env python3

import http.server
import socketserver
import subprocess
import json
import os
from urllib.parse import urlparse, parse_qs

class WebhookHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/webhook':
            # 读取请求体
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            try:
                # 解析JSON数据
                data = json.loads(post_data.decode('utf-8'))
                
                # 检查是否是push事件到main分支
                if data.get('ref') == 'refs/heads/main':
                    print(f"收到push到main分支的webhook")
                    
                    # 执行部署脚本
                    result = subprocess.run(['./webhook_handler.sh'], 
                                          capture_output=True, text=True)
                    
                    if result.returncode == 0:
                        self.send_response(200)
                        self.send_header('Content-type', 'text/plain')
                        self.end_headers()
                        self.wfile.write(b'Deployment successful')
                        print("部署成功")
                    else:
                        self.send_response(500)
                        self.send_header('Content-type', 'text/plain')
                        self.end_headers()
                        self.wfile.write(b'Deployment failed')
                        print(f"部署失败: {result.stderr}")
                else:
                    self.send_response(200)
                    self.send_header('Content-type', 'text/plain')
                    self.end_headers()
                    self.wfile.write(b'Not main branch, ignored')
                    
            except Exception as e:
                print(f"处理webhook失败: {e}")
                self.send_response(400)
                self.send_header('Content-type', 'text/plain')
                self.end_headers()
                self.wfile.write(b'Bad request')
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(b'Webhook server is running')
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == "__main__":
    PORT = 9000
    with socketserver.TCPServer(("", PORT), WebhookHandler) as httpd:
        print(f"Webhook服务器启动在端口 {PORT}")
        print(f"Webhook URL: http://localhost:{PORT}/webhook")
        httpd.serve_forever()
WEBHOOK_SERVER

chmod +x webhook_server.py

# 创建systemd服务文件
sudo tee /etc/systemd/system/git-webhook.service > /dev/null << 'SERVICE'
[Unit]
Description=Git Webhook Auto Deploy Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/webhook
ExecStart=/usr/bin/python3 /home/ec2-user/webhook/webhook_server.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

# 启动webhook服务
sudo systemctl daemon-reload
sudo systemctl enable git-webhook
sudo systemctl start git-webhook

echo "✅ Git Webhook服务设置完成"
echo "📡 Webhook URL: http://$(curl -s ifconfig.me):9000/webhook"
echo "🔍 查看状态: sudo systemctl status git-webhook"
echo "📋 查看日志: sudo journalctl -u git-webhook -f"

EOF

echo "🎉 Git Webhook自动部署系统设置完成！"
echo ""
echo "📋 下一步操作："
echo "1. 在GitHub仓库设置中添加Webhook"
echo "2. Webhook URL: http://$SERVER_HOST:$WEBHOOK_PORT/webhook"
echo "3. Content type: application/json"
echo "4. 选择 'Just the push event'"
echo "5. 确保Active选项被勾选"
echo ""
echo "🔧 管理命令："
echo "  查看webhook状态: ssh -i $KEY_PATH $SERVER_USER@$SERVER_HOST 'sudo systemctl status git-webhook'"
echo "  查看webhook日志: ssh -i $KEY_PATH $SERVER_USER@$SERVER_HOST 'sudo journalctl -u git-webhook -f'"
echo "  查看部署日志: ssh -i $KEY_PATH $SERVER_USER@$SERVER_HOST 'tail -f ~/webhook/deploy.log'"
