# 快速参考卡片 - 儿童任务管理应用

## 🚀 常用命令速查

### 部署相关
```bash
# 手动部署
./deploy.sh

# 启动自动监控部署
./auto_deploy.sh

# 设置GitHub Webhook（一次性）
./setup_git_webhook.sh
```

### 服务器状态检查
```bash
# WebSocket服务器健康检查
curl http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/health

# 检查服务器进程
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'pgrep -f websocket-server-linux'

# 检查webhook服务状态
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sudo systemctl status git-webhook'
```

### 日志查看
```bash
# WebSocket服务器日志
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'tail -f /home/ec2-user/websocket-server-new/websocket.log'

# 部署日志
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'tail -f /home/ec2-user/webhook/deploy.log'

# Webhook服务日志
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sudo journalctl -u git-webhook -f'
```

### 数据库操作
```bash
# 查看最新任务
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sqlite3 /home/ec2-user/websocket-server-new/tasks.db "SELECT title, category, priority FROM tasks ORDER BY created_at DESC LIMIT 5;"'

# 备份数据库
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'cp /home/ec2-user/websocket-server-new/tasks.db /home/ec2-user/tasks_backup_$(date +%Y%m%d).db'
```

## 📱 iOS应用操作

### 启动应用
1. 打开Xcode
2. 打开 `KidsScheduleApp.xcodeproj`
3. 选择设备/模拟器
4. 按 ⌘+R 运行

### 任务操作
- **创建**：点击"+"按钮
- **编辑**：点击编辑图标
- **删除**：iPhone左滑 / iPad点击删除按钮
- **完成**：点击圆圈

### WebSocket状态
- 🟢 绿色：连接正常
- 🔴 红色：连接断开
- 🟡 黄色：连接中

## 🔧 故障排除速查

### WebSocket连接失败
```bash
# 1. 检查服务器状态
curl http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/health

# 2. 重启服务器
./deploy.sh

# 3. 检查防火墙
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sudo iptables -L'
```

### 自动部署失败
```bash
# 1. 检查webhook服务
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sudo systemctl status git-webhook'

# 2. 查看部署日志
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'tail -20 /home/ec2-user/webhook/deploy.log'

# 3. 手动部署
./deploy.sh
```

### 编译失败
```bash
# 1. 检查Go环境
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'go version'

# 2. 手动编译测试
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'cd /home/ec2-user/kids-schedule-app/websocket-server && go mod tidy && go build main.go'
```

## 🎯 开发工作流

### 日常开发
1. 修改代码
2. 本地测试
3. 提交代码：
   ```bash
   git add .
   git commit -m "描述性信息"
   git push origin main
   ```
4. 自动部署（约10秒）
5. 验证部署成功

### 版本更新
1. 更新版本信息（在main.go中）
2. 提交代码
3. 检查部署日志确认新版本

## 📊 重要端点和地址

### 服务器地址
- **WebSocket**: `ws://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/ws`
- **健康检查**: `http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/health`
- **Webhook**: `http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:9000/webhook`

### 文件路径
- **WebSocket服务器**: `/home/ec2-user/websocket-server-new/`
- **代码仓库**: `/home/ec2-user/kids-schedule-app/`
- **数据库**: `/home/ec2-user/websocket-server-new/tasks.db`
- **日志文件**: `/home/ec2-user/websocket-server-new/websocket.log`
- **部署日志**: `/home/ec2-user/webhook/deploy.log`

### GitHub仓库
- **仓库地址**: `https://github.com/zhoujba/kids.git`
- **主分支**: `main`

## ⚡ 紧急操作

### 服务器完全重启
```bash
# 谨慎使用！
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sudo reboot'
```

### 强制重新部署
```bash
# 停止所有相关进程
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sudo pkill -f websocket-server-linux'

# 重新部署
./deploy.sh
```

### 数据库紧急备份
```bash
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'cp /home/ec2-user/websocket-server-new/tasks.db /home/ec2-user/emergency_backup_$(date +%Y%m%d_%H%M%S).db'
```

## 📞 联系信息

### 技术栈
- **前端**: SwiftUI + Core Data
- **后端**: Go + SQLite + WebSocket
- **部署**: AWS EC2 + GitHub Actions
- **监控**: 自定义日志系统

### 关键组件
- **iOS应用**: KidsScheduleApp
- **WebSocket服务器**: Go程序
- **自动部署**: Python webhook服务器
- **数据存储**: SQLite数据库

---

**💡 提示**: 将此文件保存为书签，随时查阅常用命令和操作步骤！
