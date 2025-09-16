# 儿童任务管理应用 - 完整使用指南

## 📋 项目概述

这是一个基于iOS的儿童任务管理应用，采用WebSocket实时同步架构，支持多设备间的实时数据同步。

### 🎯 核心功能
- ✅ 任务创建、编辑、删除
- ✅ 任务分类和优先级管理
- ✅ 多设备实时同步
- ✅ 番茄工作法计时器
- ✅ 语音输入支持
- ✅ 日历视图
- ✅ 本地数据持久化（Core Data）

### 🏗️ 技术架构
- **前端**: SwiftUI + Core Data (iOS 17+)
- **后端**: Go + SQLite + WebSocket
- **部署**: AWS EC2 + 自动化CI/CD
- **同步**: WebSocket实时双向通信

## 🚀 快速开始

### 1. 开发环境准备

#### iOS开发环境
```bash
# 确保已安装Xcode (最新版本)
# 确保iOS模拟器版本为17.0或更高
```

#### 服务器环境
- AWS EC2实例 (Amazon Linux 2023)
- Go 1.19+ 环境
- SQLite 数据库
- 端口8082 (WebSocket服务器)
- 端口9000 (Webhook服务器)

### 2. 项目结构
```
.
├── KidsScheduleApp/                 # iOS应用源码
│   ├── KidsScheduleAppApp.swift    # 应用入口
│   ├── ContentView.swift           # 主界面
│   ├── AddTaskView.swift           # 添加任务界面
│   ├── WebSocketManager.swift      # WebSocket客户端
│   ├── WebSocketStatusView.swift   # WebSocket状态显示
│   ├── DataModel.xcdatamodeld      # Core Data模型
│   └── ...                        # 其他视图和组件
├── KidsScheduleApp.xcodeproj/       # Xcode项目配置
├── websocket-server/               # WebSocket服务器
│   ├── main.go                     # 服务器主程序
│   ├── go.mod                      # Go模块配置
│   └── go.sum                      # 依赖锁定文件
├── deploy.sh                       # 手动部署脚本
├── auto_deploy.sh                  # 自动监控部署脚本
├── setup_git_webhook.sh            # Git Webhook设置脚本
└── *.md                           # 文档文件
```

## 📱 iOS应用操作指南

### 启动应用
1. 打开Xcode
2. 打开项目文件：`KidsScheduleApp.xcodeproj`
3. 选择iOS模拟器或真机设备
4. 点击运行按钮 (⌘+R)

### 主要功能使用

#### 任务管理
1. **创建任务**：点击"+"按钮，填写任务信息
2. **编辑任务**：点击任务项的编辑按钮
3. **删除任务**：
   - iPhone：左滑任务项
   - iPad：点击任务项的删除按钮
4. **完成任务**：点击任务前的圆圈

#### 任务分类和优先级
- **分类**：学习、运动、娱乐等
- **优先级**：1-3级，数字越小优先级越高

#### 实时同步
- 应用启动时自动连接WebSocket服务器
- 状态栏显示连接状态
- 所有操作自动同步到其他设备

## 🌐 服务器管理

### 服务器状态检查
```bash
# 检查WebSocket服务器状态
curl http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/health

# 检查webhook服务状态
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sudo systemctl status git-webhook'

# 检查WebSocket服务器进程
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'pgrep -f websocket-server-linux'
```

### 查看日志
```bash
# WebSocket服务器日志
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'tail -f /home/ec2-user/websocket-server-new/websocket.log'

# Webhook服务日志
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sudo journalctl -u git-webhook -f'

# 部署日志
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'tail -f /home/ec2-user/webhook/deploy.log'
```

## 🚀 部署操作指南

### 方案一：手动部署
```bash
# 适用场景：偶尔更新，手动控制部署时机
./deploy.sh
```

### 方案二：自动监控部署
```bash
# 适用场景：开发阶段，频繁代码变更
chmod +x auto_deploy.sh
./auto_deploy.sh
# 保持终端运行，自动检测git变化并部署
```

### 方案三：Git Webhook自动部署（推荐）
```bash
# 一次性设置，之后完全自动化
chmod +x setup_git_webhook.sh
./setup_git_webhook.sh

# 在GitHub仓库中配置Webhook：
# URL: http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:9000/webhook
# Content type: application/json
# Events: Just the push event
```

## 🔧 开发工作流程

### 日常开发流程
1. **修改代码**：在本地进行开发
2. **本地测试**：在Xcode中测试iOS应用
3. **提交代码**：
   ```bash
   git add .
   git commit -m "描述性提交信息"
   git push origin main
   ```
4. **自动部署**：GitHub webhook自动触发服务器部署
5. **验证部署**：检查服务器日志确认部署成功

### 版本管理
- 在`websocket-server/main.go`中更新版本信息
- 提交时使用语义化版本号
- 服务器日志会显示当前运行的版本

### 测试流程
1. **iOS应用测试**：
   - 在Xcode模拟器中测试
   - 验证WebSocket连接状态
   - 测试任务CRUD操作
   - 验证多设备同步

2. **服务器测试**：
   ```bash
   # 健康检查
   curl http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/health
   
   # WebSocket连接测试（浏览器控制台）
   const ws = new WebSocket('ws://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/ws');
   ws.onopen = () => console.log('连接成功');
   ws.onmessage = (event) => console.log('收到消息:', event.data);
   ```

## 🛠️ 故障排除

### 常见问题及解决方案

#### 1. iOS应用无法连接WebSocket
**症状**：状态栏显示"连接失败"
**解决方案**：
```bash
# 检查服务器状态
curl http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/health

# 重启WebSocket服务器
./deploy.sh
```

#### 2. 自动部署失败
**症状**：推送代码后服务器版本没有更新
**解决方案**：
```bash
# 检查webhook服务状态
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sudo systemctl status git-webhook'

# 查看部署日志
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'tail -20 /home/ec2-user/webhook/deploy.log'

# 手动部署
./deploy.sh
```

#### 3. 编译失败
**症状**：部署日志显示编译错误
**解决方案**：
```bash
# 检查Go环境
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'go version'

# 手动编译测试
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'cd /home/ec2-user/kids-schedule-app/websocket-server && go mod tidy && go build main.go'
```

#### 4. 数据同步异常
**症状**：任务在设备间不同步
**解决方案**：
1. 检查WebSocket连接状态
2. 查看服务器日志中的广播消息
3. 重启iOS应用
4. 检查网络连接

### 重启服务
```bash
# 重启WebSocket服务器
./deploy.sh

# 重启Webhook服务
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sudo systemctl restart git-webhook'

# 重启整个系统（谨慎使用）
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sudo reboot'
```

## 📞 技术支持

### 监控命令
```bash
# 实时监控WebSocket连接
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'tail -f /home/ec2-user/websocket-server-new/websocket.log | grep "客户端"'

# 监控部署活动
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'tail -f /home/ec2-user/webhook/deploy.log'

# 系统资源监控
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'top -p $(pgrep websocket-server-linux)'
```

### 备份和恢复
```bash
# 备份SQLite数据库
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'cp /home/ec2-user/websocket-server-new/tasks.db /home/ec2-user/tasks_backup_$(date +%Y%m%d_%H%M%S).db'

# 查看数据库内容
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sqlite3 /home/ec2-user/websocket-server-new/tasks.db "SELECT title, category, priority FROM tasks ORDER BY created_at DESC LIMIT 10;"'
```

## 🎯 最佳实践

### 开发建议
1. **提交频率**：小步快跑，频繁提交
2. **提交信息**：使用清晰的描述性信息
3. **测试先行**：本地测试通过后再推送
4. **版本标记**：重要更新时更新版本号

### 部署建议
1. **使用自动部署**：配置GitHub webhook实现自动化
2. **监控日志**：定期检查服务器和部署日志
3. **备份数据**：定期备份SQLite数据库
4. **性能监控**：关注服务器资源使用情况

### 安全建议
1. **SSH密钥管理**：妥善保管AWS EC2的SSH密钥
2. **端口安全**：确保只开放必要的端口
3. **代码审查**：重要变更前进行代码审查
4. **访问控制**：限制服务器访问权限

## 📚 详细操作手册

### iOS应用详细操作

#### WebSocket状态监控
- **绿色圆点**：连接正常
- **红色圆点**：连接断开
- **黄色圆点**：连接中

在`WebSocketStatusView.swift`中可以看到状态显示逻辑：
- 实时显示连接状态
- 显示最后更新时间
- 提供重连功能

#### 任务操作详解
1. **创建任务**：
   - 点击主界面"+"按钮
   - 填写标题（必填）
   - 选择分类：学习、运动、娱乐
   - 设置优先级：1（高）、2（中）、3（低）
   - 设置截止日期
   - 添加描述（可选）

2. **编辑任务**：
   - 点击任务右侧的编辑图标
   - 修改任务信息
   - 保存后自动同步到其他设备

3. **删除任务**：
   - iPhone：左滑任务项，点击删除
   - iPad：点击任务右侧的垃圾桶图标

4. **完成任务**：
   - 点击任务左侧的圆圈
   - 任务状态会实时同步

### 服务器配置详解

#### WebSocket服务器配置
- **端口**：8082
- **数据库**：SQLite (`tasks.db`)
- **日志文件**：`websocket.log`
- **进程名**：`websocket-server-linux`

#### 关键配置文件
1. **go.mod**：Go模块依赖
2. **main.go**：服务器主程序
3. **tasks.db**：SQLite数据库文件

### GitHub Webhook配置详解

#### 在GitHub中设置Webhook
1. 打开仓库：https://github.com/zhoujba/kids
2. 进入 **Settings** → **Webhooks**
3. 点击 **Add webhook**
4. 配置参数：
   ```
   Payload URL: http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:9000/webhook
   Content type: application/json
   Secret: (留空)
   Which events: Just the push event
   Active: ✅
   ```

#### Webhook工作流程
1. 代码推送到main分支
2. GitHub发送POST请求到webhook URL
3. 服务器接收请求并验证
4. 自动拉取最新代码
5. 编译Go程序
6. 停止旧进程，启动新进程
7. 验证服务状态

### 数据库操作

#### 查看任务数据
```bash
# 连接到服务器
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com

# 查看所有任务
sqlite3 /home/ec2-user/websocket-server-new/tasks.db "SELECT * FROM tasks ORDER BY created_at DESC;"

# 查看特定用户的任务
sqlite3 /home/ec2-user/websocket-server-new/tasks.db "SELECT title, category, priority, is_completed FROM tasks WHERE user_id='default_user';"

# 统计任务数量
sqlite3 /home/ec2-user/websocket-server-new/tasks.db "SELECT COUNT(*) as total_tasks FROM tasks;"
```

#### 数据库维护
```bash
# 备份数据库
cp /home/ec2-user/websocket-server-new/tasks.db /home/ec2-user/backup/tasks_$(date +%Y%m%d).db

# 清理旧数据（谨慎使用）
sqlite3 /home/ec2-user/websocket-server-new/tasks.db "DELETE FROM tasks WHERE created_at < date('now', '-30 days');"

# 优化数据库
sqlite3 /home/ec2-user/websocket-server-new/tasks.db "VACUUM;"
```

## 🔄 版本更新流程

### 更新iOS应用
1. 修改iOS代码
2. 在Xcode中测试
3. 提交代码到git
4. 无需额外操作（客户端代码不需要服务器部署）

### 更新WebSocket服务器
1. 修改`websocket-server/main.go`
2. 更新版本信息（可选）
3. 提交并推送代码：
   ```bash
   git add websocket-server/
   git commit -m "🔧 更新服务器功能"
   git push origin main
   ```
4. 自动部署会在几秒内完成

### 版本验证
```bash
# 检查当前运行的版本
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'head -10 /home/ec2-user/websocket-server-new/websocket.log | grep "版本"'

# 检查最新部署时间
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'tail -5 /home/ec2-user/webhook/deploy.log'
```

## 🎯 性能优化建议

### iOS应用优化
1. **内存管理**：及时释放不用的资源
2. **网络优化**：合理处理WebSocket重连
3. **UI响应**：使用异步操作避免阻塞主线程
4. **数据同步**：避免频繁的Core Data操作

### 服务器优化
1. **连接管理**：定期清理无效连接
2. **数据库优化**：定期执行VACUUM操作
3. **日志管理**：定期清理旧日志文件
4. **资源监控**：监控CPU和内存使用

### 网络优化
1. **消息压缩**：对大型消息进行压缩
2. **批量操作**：合并多个小操作
3. **错误重试**：实现智能重试机制
4. **连接池**：复用数据库连接

---

**🎉 现在您可以高效地开发和维护这个项目了！**

如有问题，请参考故障排除部分或查看相关日志文件。
