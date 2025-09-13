# CloudKit 配置指南

本指南将帮助您配置CloudKit以实现多设备数据同步功能。

## 1. Apple Developer 配置

### 1.1 启用CloudKit服务
1. 登录 [Apple Developer Portal](https://developer.apple.com)
2. 进入 "Certificates, Identifiers & Profiles"
3. 选择 "Identifiers" → "App IDs"
4. 找到您的应用ID（如：com.yourname.KidsScheduleApp）
5. 点击编辑，启用 "CloudKit" 服务
6. 保存更改

### 1.2 配置CloudKit容器
1. 在Apple Developer Portal中，进入 "CloudKit Console"
2. 选择您的应用对应的容器
3. 在 "Schema" 部分创建以下Record Types：

#### TaskItem Record Type
- `title` (String)
- `taskDescription` (String, Optional)
- `category` (String, Optional)
- `dueDate` (Date/Time, Optional)
- `priority` (Int64)
- `isCompleted` (Int64) // 0 = false, 1 = true
- `createdDate` (Date/Time)
- `notificationID` (String, Optional)

#### PomodoroSession Record Type
- `startTime` (Date/Time, Optional)
- `endTime` (Date/Time, Optional)
- `sessionType` (String, Optional)
- `completedCycles` (Int64)
- `isActive` (Int64) // 0 = false, 1 = true
- `totalDuration` (Int64)
- `createdDate` (Date/Time)

### 1.3 设置权限
1. 在CloudKit Console中，进入 "Security Roles"
2. 确保 "World" 角色对两个Record Types都有以下权限：
   - Create: Yes
   - Read: Yes
   - Write: Yes

## 2. Xcode 项目配置

### 2.1 启用CloudKit Capability
1. 在Xcode中打开项目
2. 选择项目目标 (Target)
3. 进入 "Signing & Capabilities" 标签
4. 点击 "+ Capability"
5. 添加 "CloudKit"
6. 选择正确的CloudKit容器

### 2.2 配置Core Data with CloudKit
1. 选择 `DataModel.xcdatamodeld` 文件
2. 在Data Model Inspector中：
   - 勾选 "Used with CloudKit"
   - 设置 "CloudKit Container" 为您的容器

### 2.3 更新Info.plist
添加以下权限描述（如果尚未添加）：

```xml
<key>NSUserNotificationUsageDescription</key>
<string>此应用需要发送通知来提醒您儿子的重要事项和番茄工作法时间。</string>
```

## 3. 代码集成

### 3.1 已包含的文件
- `CloudKitSyncManager.swift` - 核心同步管理器
- `SyncStatusView.swift` - 同步状态UI组件
- `SettingsView.swift` - 设置页面

### 3.2 自动启动同步
同步功能已在 `KidsScheduleAppApp.swift` 中自动配置，应用启动时会：
1. 配置CloudKit同步管理器
2. 启动网络监控
3. 开始自动同步

## 4. 测试多设备同步

### 4.1 准备工作
1. 确保两台设备都登录了相同的iCloud账号
2. 确保两台设备都安装了应用的最新版本
3. 确保两台设备都有网络连接

### 4.2 测试步骤
1. 在设备A上创建一个新任务
2. 等待几秒钟让同步完成
3. 在设备B上检查任务是否出现
4. 在设备B上修改任务
5. 在设备A上验证修改是否同步

### 4.3 同步状态监控
- 应用顶部会显示同步状态栏
- 绿色云图标表示同步成功
- 红色图标表示同步失败
- 旋转图标表示正在同步

## 5. 故障排除

### 5.1 常见问题

#### 同步不工作
1. 检查网络连接
2. 确认iCloud账号登录状态
3. 检查CloudKit容器配置
4. 查看Xcode控制台错误信息

#### 数据冲突
- 应用使用"最后修改时间优先"策略
- 如果同时在两台设备上修改同一项目，较新的修改会保留

#### 权限问题
1. 检查CloudKit Console中的权限设置
2. 确认应用有正确的CloudKit Capability

### 5.2 调试技巧
1. 在CloudKit Console中查看数据
2. 使用Xcode的CloudKit调试工具
3. 检查应用日志中的同步信息

## 6. 性能优化

### 6.1 同步策略
- 应用启动时立即同步
- 网络恢复时自动同步
- 每5分钟检查一次同步
- 数据变更时标记需要同步

### 6.2 冲突解决
- 使用时间戳比较解决冲突
- 保留最新修改的版本
- 避免数据丢失

## 7. 隐私和安全

### 7.1 数据保护
- 所有数据通过iCloud加密传输
- 数据存储在用户的私有CloudKit数据库中
- 只有用户本人可以访问数据

### 7.2 权限管理
- 应用只访问用户授权的数据
- 遵循Apple的隐私准则
- 不收集用户个人信息

## 8. 部署注意事项

### 8.1 生产环境
1. 确保CloudKit容器已部署到生产环境
2. 测试所有同步功能
3. 准备回滚计划

### 8.2 用户指导
1. 在应用中提供同步状态说明
2. 指导用户如何检查iCloud设置
3. 提供故障排除帮助

---

完成以上配置后，您的应用就具备了多设备数据同步功能，用户可以在iPhone、iPad等设备间无缝同步日历数据。
