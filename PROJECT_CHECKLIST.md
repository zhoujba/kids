# 项目检查清单 - 儿童任务管理应用

## 🔍 系统健康检查清单

### 每日检查 (Daily Check)

#### ✅ 服务器状态检查
- [ ] WebSocket服务器运行状态
  ```bash
  curl http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/health
  ```
  预期结果：`{"status":"ok"}`

- [ ] Webhook服务运行状态
  ```bash
  ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sudo systemctl status git-webhook'
  ```
  预期结果：`Active: active (running)`

- [ ] 服务器进程检查
  ```bash
  ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'pgrep -f websocket-server-linux'
  ```
  预期结果：返回进程ID

#### ✅ 连接测试
- [ ] iOS应用WebSocket连接状态
  - 打开iOS应用
  - 检查状态栏显示绿色圆点
  - 验证"WebSocket实时同步已启动"消息

- [ ] 跨设备同步测试
  - 在一个设备上创建测试任务
  - 验证其他设备立即收到更新
  - 删除测试任务

#### ✅ 日志检查
- [ ] 检查错误日志
  ```bash
  ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'tail -50 /home/ec2-user/websocket-server-new/websocket.log | grep -i error'
  ```
  预期结果：无严重错误

- [ ] 检查连接数量
  ```bash
  ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'tail -20 /home/ec2-user/websocket-server-new/websocket.log | grep "连接数"'
  ```

### 每周检查 (Weekly Check)

#### ✅ 数据库维护
- [ ] 数据库备份
  ```bash
  ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'cp /home/ec2-user/websocket-server-new/tasks.db /home/ec2-user/backup/tasks_$(date +%Y%m%d).db'
  ```

- [ ] 数据库大小检查
  ```bash
  ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'ls -lh /home/ec2-user/websocket-server-new/tasks.db'
  ```

- [ ] 任务数量统计
  ```bash
  ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sqlite3 /home/ec2-user/websocket-server-new/tasks.db "SELECT COUNT(*) FROM tasks;"'
  ```

#### ✅ 性能检查
- [ ] 服务器资源使用
  ```bash
  ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'top -p $(pgrep websocket-server-linux) -n 1'
  ```

- [ ] 磁盘空间检查
  ```bash
  ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'df -h'
  ```

- [ ] 内存使用检查
  ```bash
  ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'free -h'
  ```

#### ✅ 日志清理
- [ ] 清理旧日志文件（保留最近30天）
  ```bash
  ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'find /home/ec2-user/ -name "*.log" -mtime +30 -delete'
  ```

### 每月检查 (Monthly Check)

#### ✅ 安全检查
- [ ] 检查SSH密钥安全性
- [ ] 更新系统包
  ```bash
  ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sudo dnf update -y'
  ```

- [ ] 检查防火墙规则
  ```bash
  ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sudo iptables -L'
  ```

#### ✅ 代码质量检查
- [ ] 检查Git提交历史
- [ ] 代码备份到其他位置
- [ ] 文档更新检查

## 🚨 故障诊断清单

### WebSocket连接问题

#### 症状：iOS应用显示连接失败
- [ ] 检查服务器状态
- [ ] 检查网络连接
- [ ] 重启WebSocket服务器
- [ ] 检查防火墙设置
- [ ] 验证端口8082是否开放

#### 症状：连接频繁断开
- [ ] 检查服务器资源使用
- [ ] 查看服务器错误日志
- [ ] 检查网络稳定性
- [ ] 验证客户端重连逻辑

### 自动部署问题

#### 症状：推送代码后没有自动部署
- [ ] 检查GitHub Webhook配置
- [ ] 验证Webhook服务状态
- [ ] 查看部署日志
- [ ] 检查仓库权限
- [ ] 手动触发部署测试

#### 症状：部署失败
- [ ] 检查编译错误
- [ ] 验证Go环境
- [ ] 检查依赖包
- [ ] 验证文件权限
- [ ] 检查磁盘空间

### 数据同步问题

#### 症状：任务不同步
- [ ] 检查WebSocket连接
- [ ] 验证服务器广播功能
- [ ] 检查客户端消息处理
- [ ] 重启iOS应用
- [ ] 清理本地缓存

#### 症状：数据丢失
- [ ] 检查数据库完整性
- [ ] 恢复最近备份
- [ ] 验证Core Data同步
- [ ] 检查服务器日志

## 📋 部署前检查清单

### 代码提交前
- [ ] 本地测试通过
- [ ] iOS应用编译成功
- [ ] WebSocket连接测试正常
- [ ] 任务CRUD操作正常
- [ ] 多设备同步测试通过
- [ ] 提交信息清晰描述

### 部署后验证
- [ ] 自动部署成功完成
- [ ] 新版本号正确显示
- [ ] 服务器健康检查通过
- [ ] WebSocket连接正常
- [ ] 数据同步功能正常
- [ ] 无错误日志产生

## 🔧 维护操作清单

### 定期维护任务

#### 每天
- [ ] 检查服务器状态
- [ ] 监控错误日志
- [ ] 验证基本功能

#### 每周
- [ ] 数据库备份
- [ ] 性能监控
- [ ] 日志分析

#### 每月
- [ ] 系统更新
- [ ] 安全检查
- [ ] 容量规划

### 紧急维护

#### 服务器宕机
1. [ ] 检查服务器状态
2. [ ] 重启相关服务
3. [ ] 验证数据完整性
4. [ ] 通知用户（如需要）

#### 数据库问题
1. [ ] 停止写入操作
2. [ ] 备份当前数据
3. [ ] 修复数据库问题
4. [ ] 验证数据完整性
5. [ ] 恢复服务

## 📊 性能基准

### 正常运行指标
- **WebSocket连接响应时间**: < 100ms
- **任务同步延迟**: < 1秒
- **服务器CPU使用率**: < 50%
- **内存使用**: < 1GB
- **磁盘使用**: < 80%

### 告警阈值
- **连接失败率**: > 5%
- **同步延迟**: > 5秒
- **CPU使用率**: > 80%
- **内存使用**: > 2GB
- **磁盘使用**: > 90%

## 📞 应急联系

### 关键信息
- **服务器IP**: ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com
- **SSH密钥**: ~/Downloads/miyao.pem
- **GitHub仓库**: https://github.com/zhoujba/kids.git
- **WebSocket端口**: 8082
- **Webhook端口**: 9000

### 快速恢复命令
```bash
# 完全重启服务
./deploy.sh

# 紧急备份
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'cp /home/ec2-user/websocket-server-new/tasks.db /home/ec2-user/emergency_backup_$(date +%Y%m%d_%H%M%S).db'

# 查看实时日志
ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'tail -f /home/ec2-user/websocket-server-new/websocket.log'
```

---

**📝 使用说明**: 定期按照此清单检查系统状态，确保项目稳定运行。遇到问题时，按照故障诊断清单逐步排查。
