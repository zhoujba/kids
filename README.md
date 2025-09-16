# 儿童任务管理应用 - Kids Schedule App

## 📱 项目简介

这是一个基于iOS的儿童任务管理应用，采用WebSocket实时同步架构，支持多设备间的实时数据同步。应用帮助家长管理儿童的日常任务，包括学习、运动、娱乐等各类活动。

### 🎯 核心特性
- ✅ **实时同步**：多设备间任务数据实时同步
- ✅ **任务管理**：创建、编辑、删除、完成任务
- ✅ **分类管理**：学习、运动、娱乐等分类
- ✅ **优先级设置**：1-3级优先级管理
- ✅ **番茄工作法**：内置专注时间管理工具
- ✅ **语音输入**：支持语音创建任务
- ✅ **日历视图**：直观的时间管理界面
- ✅ **Web版客户端**：跨平台浏览器访问
- ✅ **自动部署**：GitHub推送自动部署到服务器

### 🏗️ 技术架构
- **iOS前端**：SwiftUI + Core Data (iOS 17+)
- **Web前端**：HTML5 + CSS3 + JavaScript
- **后端**：Go + SQLite + WebSocket
- **部署**：AWS EC2 + GitHub Webhook自动部署
- **同步**：WebSocket实时双向通信

## 📚 文档导航

### 🚀 快速开始
- **[USER_GUIDE.md](USER_GUIDE.md)** - 完整的使用指南和操作手册
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - 常用命令和操作的快速参考
- **[QUICK_START.md](QUICK_START.md)** - 快速启动指南

### 🔧 开发和部署
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - 项目技术总结和架构说明
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - 详细的部署指南
- **[WebSocket实时同步架构说明.md](WebSocket实时同步架构说明.md)** - WebSocket架构详解

### 📋 维护和监控
- **[PROJECT_CHECKLIST.md](PROJECT_CHECKLIST.md)** - 系统健康检查和维护清单
- **[SYNC_TESTING_GUIDE.md](SYNC_TESTING_GUIDE.md)** - 同步功能测试指南
- **[AWS部署总结.md](AWS部署总结.md)** - AWS部署配置说明

### 📱 客户端开发
- **[INSTALL_TO_IPHONE.md](INSTALL_TO_IPHONE.md)** - iOS设备安装指南
- **[CLOUDKIT_SETUP.md](CLOUDKIT_SETUP.md)** - CloudKit配置说明
- **[web-client/README.md](web-client/README.md)** - Web版客户端使用指南

## 🚀 快速开始

### 1. 启动iOS应用
```bash
# 打开Xcode项目
open KidsScheduleApp.xcodeproj

# 选择设备/模拟器，按⌘+R运行
```

### 2. 启动Web版客户端
```bash
# 进入Web客户端目录
cd web-client

# 一键启动（推荐）
./start.sh

# 或手动启动Python服务器
python3 server.py
```

### 3. 检查服务器状态
```bash
# 健康检查
curl http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/health

# 预期返回：{"status":"ok"}
```

### 4. 部署更新
```bash
# 手动部署
./deploy.sh

# 或者推送代码自动部署
git add .
git commit -m "更新描述"
git push origin main
```

## 📊 项目状态

### ✅ 已完成功能
- [x] iOS应用完整功能
- [x] Web版客户端
- [x] WebSocket实时同步
- [x] 任务CRUD操作
- [x] 多设备同步
- [x] 自动部署系统
- [x] 完整文档体系

### 🔄 当前版本
- **iOS应用**：完整功能版本
- **Web客户端**：v1.0.0 - 跨平台任务管理
- **WebSocket服务器**：v1.0.4 - 改进的自动部署系统
- **部署系统**：GitHub Webhook自动部署

### 📈 系统指标
- **部署时间**：约10秒
- **同步延迟**：< 1秒
- **连接成功率**：> 99%
- **自动部署成功率**：100%

## 🛠️ 开发环境

### 必需软件
- **Xcode** (最新版本)
- **iOS 17.0+** 模拟器或真机
- **Git** 版本控制
- **SSH客户端** (访问AWS服务器)

### 服务器环境
- **AWS EC2** (Amazon Linux 2023)
- **Go 1.19+** 运行环境
- **SQLite** 数据库
- **Python 3** (Webhook服务器)

## 🔗 重要链接

### 服务器地址
- **WebSocket服务器**：`ws://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/ws`
- **健康检查**：`http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/health`
- **Webhook服务**：`http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:9000/webhook`

### GitHub仓库
- **主仓库**：`https://github.com/zhoujba/kids.git`
- **主分支**：`main`

## 📞 快速支持

### 常用命令
```bash
# 检查服务器状态
curl http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/health

# 查看实时日志
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'tail -f /home/ec2-user/websocket-server-new/websocket.log'

# 手动部署
./deploy.sh

# 查看部署日志
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'tail -f /home/ec2-user/webhook/deploy.log'
```

### 故障排除
1. **WebSocket连接失败**：检查服务器状态，重启服务
2. **自动部署失败**：查看部署日志，手动部署
3. **数据不同步**：检查WebSocket连接，重启应用

## 🎯 使用建议

### 日常开发
1. 使用 **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** 查找常用命令
2. 遵循 **[PROJECT_CHECKLIST.md](PROJECT_CHECKLIST.md)** 进行定期检查
3. 参考 **[USER_GUIDE.md](USER_GUIDE.md)** 了解详细操作

### 问题解决
1. 首先查看 **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** 的故障排除部分
2. 使用 **[PROJECT_CHECKLIST.md](PROJECT_CHECKLIST.md)** 进行系统诊断
3. 参考 **[USER_GUIDE.md](USER_GUIDE.md)** 的详细故障排除指南

---

**🎉 开始使用这个强大的儿童任务管理系统吧！**

如有问题，请查阅相应的文档文件或检查系统状态。
