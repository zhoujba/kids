# 📱 安装到iPhone详细指南

## 🎯 推荐方法：使用个人Apple ID（免费）

### 步骤1：准备设备
1. **连接iPhone**
   - 用USB线连接iPhone到Mac
   - 在iPhone上点击"信任此电脑"
   - 输入iPhone密码确认

2. **检查iPhone系统版本**
   - 设置 > 通用 > 关于本机
   - 确保iOS版本为17.0或更高

### 步骤2：配置Xcode项目

1. **打开项目**
   ```bash
   open KidsScheduleApp.xcodeproj
   ```

2. **添加Apple ID**
   - Xcode菜单 > Preferences > Accounts
   - 点击"+"号 > Apple ID
   - 输入你的Apple ID和密码
   - 点击"Sign In"

3. **配置项目签名**
   - 点击项目导航器中的"KidsScheduleApp"（蓝色图标）
   - 选择"TARGETS"下的"KidsScheduleApp"
   - 点击"Signing & Capabilities"标签
   
4. **设置签名信息**
   - ✅ 勾选"Automatically manage signing"
   - **Team**: 选择你的个人团队（显示为你的姓名）
   - **Bundle Identifier**: 修改为唯一标识符
     ```
     com.yourname.KidsScheduleApp
     ```
     （将yourname替换为你的名字，例如：com.zhangsan.KidsScheduleApp）

### 步骤3：安装到设备

1. **选择目标设备**
   - 在Xcode顶部工具栏，点击设备选择器
   - 选择你连接的iPhone（应该显示设备名称）

2. **构建并安装**
   - 点击运行按钮▶️或按快捷键⌘+R
   - 等待编译完成（首次可能需要几分钟）
   - 应用会自动安装到iPhone上

### 步骤4：信任开发者证书

首次安装后，应用图标会出现在iPhone上，但点击时会提示"不受信任的开发者"：

1. **打开iPhone设置**
   - 设置 > 通用 > VPN与设备管理

2. **信任开发者**
   - 找到"开发者应用"部分
   - 点击你的Apple ID
   - 点击"信任 [你的Apple ID]"
   - 在弹窗中再次点击"信任"

3. **启动应用**
   - 返回主屏幕
   - 点击"儿子事项管理"应用图标
   - 应用应该正常启动

## ⚠️ 重要注意事项

### 免费Apple ID限制
- **7天限制**：应用会在7天后过期，需要重新安装
- **设备限制**：同时只能在3台设备上安装
- **重新安装**：过期后重复上述步骤即可

### 解决常见问题

**问题1：Bundle Identifier已被使用**
```
解决方案：修改Bundle Identifier
例如：com.yourname.KidsScheduleApp2024
```

**问题2：设备未出现在列表中**
```
解决方案：
1. 重新连接USB线
2. 在iPhone上重新信任电脑
3. 重启Xcode
```

**问题3：编译失败**
```
解决方案：
1. Product > Clean Build Folder
2. 重新运行项目
```

**问题4：应用闪退**
```
解决方案：
1. 检查iOS版本是否为17.0+
2. 重新安装应用
3. 重启iPhone
```

## 🔄 重新安装步骤（7天后）

当应用过期时：
1. 打开Xcode项目
2. 连接iPhone
3. 直接点击运行▶️
4. 应用会自动更新安装

## 💰 升级到付费开发者账号

如果你经常使用，建议购买Apple Developer账号（99美元/年）：

**优势：**
- 应用永不过期
- 可以分发给其他人
- 可以上架App Store
- 支持更多高级功能

**购买地址：**
https://developer.apple.com/programs/

## 📋 安装检查清单

安装前请确认：
- [ ] iPhone iOS版本17.0+
- [ ] Mac已安装Xcode 15.0+
- [ ] 有可用的Apple ID
- [ ] iPhone和Mac已连接并信任
- [ ] Bundle Identifier已修改为唯一值

安装后请测试：
- [ ] 应用正常启动
- [ ] 可以添加事项
- [ ] 番茄工作法功能正常
- [ ] 通知权限已允许
- [ ] 收到测试通知

## 🆘 需要帮助？

如果遇到问题：
1. 检查上述常见问题解决方案
2. 重启Xcode和iPhone
3. 确保网络连接正常
4. 尝试使用不同的USB线

---

**祝你安装成功！** 🎉

安装完成后，你就可以在iPhone上使用这个专为管理儿子日程设计的应用了。
