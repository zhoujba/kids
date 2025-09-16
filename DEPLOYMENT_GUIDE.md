# 部署指南 - 儿童任务管理应用

## 🎯 当前状态

### ✅ 已完成的工作
1. **代码清理完成**：删除了所有无关的测试文件、MySQL相关代码、PHP API服务器
2. **项目结构优化**：保留了核心的iOS应用和WebSocket服务器代码
3. **自动部署脚本**：创建了三种部署方案的脚本
4. **文档完善**：提供了完整的项目文档和使用说明

### 📁 当前项目结构
```
.
├── KidsScheduleApp/                 # iOS应用源码（核心）
├── KidsScheduleApp.xcodeproj/       # Xcode项目配置
├── websocket-server/               # WebSocket服务器（核心）
├── deploy.sh                       # 手动部署脚本
├── auto_deploy.sh                  # 自动监控部署脚本
├── setup_git_webhook.sh            # Git Webhook设置脚本
├── PROJECT_SUMMARY.md              # 项目总结文档
└── 其他文档文件
```

## 🚀 部署方案选择

### 方案一：手动部署（当前可用）
**适用场景**：偶尔更新，手动控制部署时机

```bash
# 1. 编译和部署到服务器
./deploy.sh

# 2. 验证部署
curl http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/health
```

**优点**：
- ✅ 简单直接，立即可用
- ✅ 完全手动控制
- ✅ 适合调试和测试

**缺点**：
- ❌ 需要手动执行
- ❌ 容易忘记部署

### 方案二：自动监控部署
**适用场景**：开发阶段，频繁代码变更

```bash
# 1. 启动自动监控（在本地运行）
chmod +x auto_deploy.sh
./auto_deploy.sh
```

**优点**：
- ✅ 自动检测git变化
- ✅ 无需手动干预
- ✅ 适合开发阶段

**缺点**：
- ❌ 需要本地机器持续运行
- ❌ 依赖本地网络环境

### 方案三：Git Webhook自动部署（推荐）
**适用场景**：生产环境，代码推送后自动部署

```bash
# 1. 在服务器上设置webhook服务
chmod +x setup_git_webhook.sh
./setup_git_webhook.sh

# 2. 在GitHub仓库中配置Webhook
# URL: http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:9000/webhook
# Content type: application/json
# Events: Just the push event
```

**优点**：
- ✅ 完全自动化
- ✅ 服务器端运行，不依赖本地环境
- ✅ 适合团队协作
- ✅ 生产环境最佳选择

**缺点**：
- ❌ 初始设置稍复杂
- ❌ 需要配置GitHub Webhook

## 📋 部署步骤详解

### 立即可用的部署方案

由于当前git push可能有网络问题，建议先使用**方案一：手动部署**：

```bash
# 1. 确保WebSocket服务器代码是最新的
cd websocket-server
ls -la  # 确认main.go存在

# 2. 执行部署
cd ..
./deploy.sh

# 3. 验证部署成功
# 检查服务器状态
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'pgrep -f websocket-server-linux'

# 检查WebSocket连接
curl http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/health
```

### 设置自动部署（推荐）

等网络问题解决，git push成功后：

```bash
# 1. 推送代码到GitHub
git push origin main

# 2. 设置服务器端Webhook
./setup_git_webhook.sh

# 3. 在GitHub仓库设置中添加Webhook
# Settings -> Webhooks -> Add webhook
# Payload URL: http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:9000/webhook
# Content type: application/json
# Which events: Just the push event
# Active: ✅

# 4. 测试自动部署
# 修改任意文件并推送，观察是否自动部署
echo "# Test" >> README.md
git add README.md
git commit -m "测试自动部署"
git push origin main
```

## 🔍 验证部署成功

### 1. 服务器状态检查
```bash
# 检查WebSocket服务器进程
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'pgrep -f websocket-server-linux'

# 检查端口占用
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'lsof -i:8082'
```

### 2. 功能测试
```bash
# 健康检查
curl http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/health

# WebSocket连接测试（在浏览器控制台）
const ws = new WebSocket('ws://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/ws');
ws.onopen = () => console.log('WebSocket连接成功');
ws.onmessage = (event) => console.log('收到消息:', event.data);
```

### 3. iOS应用测试
1. 在Xcode中运行iOS应用
2. 观察WebSocket连接状态
3. 创建、修改、删除任务
4. 验证多设备间的实时同步

## 🛠️ 故障排除

### 常见问题

1. **编译失败**
   ```bash
   # 检查Go环境
   go version
   
   # 重新下载依赖
   cd websocket-server
   go mod tidy
   ```

2. **部署失败**
   ```bash
   # 检查SSH连接
   ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'echo "连接成功"'
   
   # 检查服务器磁盘空间
   ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'df -h'
   ```

3. **WebSocket连接失败**
   ```bash
   # 检查防火墙设置
   ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sudo iptables -L'
   
   # 检查端口是否开放
   telnet ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 8082
   ```

## 📞 技术支持

### 日志查看
```bash
# WebSocket服务器日志
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'tail -f ~/websocket-server-new/websocket.log'

# Webhook服务日志（如果使用方案三）
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sudo journalctl -u git-webhook -f'
```

### 重启服务
```bash
# 手动重启WebSocket服务器
./deploy.sh

# 重启Webhook服务（如果使用方案三）
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sudo systemctl restart git-webhook'
```

## 🎯 下一步建议

1. **立即执行**：使用`./deploy.sh`进行手动部署，确保当前功能正常
2. **网络恢复后**：推送代码到GitHub，设置自动部署
3. **长期规划**：考虑使用Docker容器化部署，提高部署的一致性和可靠性
