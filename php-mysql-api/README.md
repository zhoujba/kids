# Kids Schedule App - PHP MySQL API

轻量级PHP API服务器，专门为Kids Schedule App提供MySQL数据库连接服务。

## 🚀 特性

- **轻量级** - 纯PHP实现，资源占用极低
- **高性能** - 使用PDO和预处理语句
- **安全** - 防SQL注入，参数验证
- **RESTful** - 标准REST API设计
- **CORS支持** - 支持跨域请求
- **详细日志** - 完整的操作日志记录

## 📁 项目结构

```
php-mysql-api/
├── index.php          # 主入口文件和路由
├── config.php         # 数据库配置和公共函数
├── health.php         # 健康检查端点
├── tasks.php          # 任务管理API
├── pomodoro.php       # 番茄工作法会话API
├── .htaccess          # Apache配置
└── README.md          # 说明文档
```

## 🔧 安装部署

### 1. 服务器要求
- PHP 7.4+ (推荐PHP 8.0+)
- MySQL 5.7+ 或 MariaDB 10.3+
- Apache或Nginx Web服务器
- PDO MySQL扩展

### 2. 部署步骤

1. **上传文件到服务器**
   ```bash
   # 将php-mysql-api目录上传到Web根目录
   scp -r php-mysql-api/ user@server:/var/www/html/
   ```

2. **配置数据库连接**
   编辑 `config.php` 文件中的数据库配置：
   ```php
   define('DB_HOST', 'localhost');
   define('DB_NAME', 'kids_schedule');
   define('DB_USER', 'kidsapp');
   define('DB_PASS', 'KidsApp2025!');
   ```

3. **设置文件权限**
   ```bash
   chmod 644 *.php
   chmod 644 .htaccess
   ```

4. **测试连接**
   ```bash
   curl http://your-server.com/php-mysql-api/health
   ```

## 📚 API文档

### 基础信息
- **Base URL**: `http://your-server.com/php-mysql-api`
- **Content-Type**: `application/json`
- **字符编码**: UTF-8

### 端点列表

#### 1. 健康检查
```
GET /health
```
**响应示例**:
```json
{
  "status": "OK",
  "timestamp": "2025-09-12T12:00:00+08:00",
  "message": "MySQL连接正常"
}
```

#### 2. 任务管理

**获取任务列表**
```
GET /api/tasks?user_id=default_user
```

**创建新任务**
```
POST /api/tasks
Content-Type: application/json

{
  "id": "task-123",
  "user_id": "default_user",
  "title": "完成作业",
  "description": "数学作业第10页",
  "due_date": "2025-09-12T18:00:00Z",
  "is_completed": false,
  "device_id": "iPhone-001"
}
```

**更新任务**
```
PUT /api/tasks
Content-Type: application/json

{
  "id": "task-123",
  "title": "完成数学作业",
  "is_completed": true
}
```

**删除任务**
```
DELETE /api/tasks?id=task-123
```

#### 3. 番茄工作法会话

**获取会话列表**
```
GET /api/pomodoro-sessions?user_id=default_user
```

**创建新会话**
```
POST /api/pomodoro-sessions
Content-Type: application/json

{
  "id": "session-123",
  "user_id": "default_user",
  "task_id": "task-123",
  "duration": 25,
  "start_time": "2025-09-12T14:00:00Z",
  "end_time": "2025-09-12T14:25:00Z",
  "is_completed": true,
  "device_id": "iPhone-001"
}
```

## 🔒 安全特性

1. **SQL注入防护** - 使用PDO预处理语句
2. **参数验证** - 严格验证所有输入参数
3. **错误处理** - 不暴露敏感的系统信息
4. **访问控制** - 配置文件访问保护

## 📊 性能优化

1. **数据库连接池** - 复用数据库连接
2. **查询优化** - 使用索引和优化的SQL
3. **压缩传输** - 启用gzip压缩
4. **缓存头** - 适当的HTTP缓存设置

## 🐛 故障排除

### 常见问题

1. **数据库连接失败**
   - 检查数据库配置
   - 确认MySQL服务运行状态
   - 验证用户权限

2. **404错误**
   - 检查.htaccess文件
   - 确认Apache mod_rewrite模块启用

3. **CORS错误**
   - 检查Apache Headers模块
   - 验证CORS配置

### 日志查看
```bash
# 查看PHP错误日志
tail -f /var/log/apache2/error.log

# 查看访问日志
tail -f /var/log/apache2/access.log
```

## 📞 技术支持

如有问题，请检查：
1. PHP版本兼容性
2. 数据库连接配置
3. Web服务器配置
4. 文件权限设置
