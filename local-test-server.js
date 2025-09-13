const http = require('http');
const url = require('url');
const port = 8080;

// 模拟数据存储
let tasks = [];
let pomodoroSessions = [];

// 解析JSON请求体
function parseBody(req) {
    return new Promise((resolve, reject) => {
        let body = '';
        req.on('data', chunk => {
            body += chunk.toString();
        });
        req.on('end', () => {
            try {
                resolve(body ? JSON.parse(body) : {});
            } catch (error) {
                reject(error);
            }
        });
    });
}

// 创建HTTP服务器
const server = http.createServer(async (req, res) => {
    // 设置CORS头
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    res.setHeader('Content-Type', 'application/json');

    // 处理OPTIONS请求
    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }

    const parsedUrl = url.parse(req.url, true);
    const path = parsedUrl.pathname;
    const query = parsedUrl.query;

    try {
        // 健康检查端点
        if (path === '/health' && req.method === 'GET') {
            const response = {
                status: 'OK',
                timestamp: new Date().toISOString(),
                message: '本地测试服务器运行正常'
            };
            res.writeHead(200);
            res.end(JSON.stringify(response));
            return;
        }

        // 获取任务列表
        if (path === '/api/tasks' && req.method === 'GET') {
            const { user_id } = query;

            if (!user_id) {
                res.writeHead(400);
                res.end(JSON.stringify({ error: 'user_id is required' }));
                return;
            }

            const userTasks = tasks.filter(task => task.user_id === user_id);
            console.log(`获取任务列表: 用户 ${user_id}, 共 ${userTasks.length} 个任务`);
            res.writeHead(200);
            res.end(JSON.stringify(userTasks));
            return;
        }

        // 创建新任务
        if (path === '/api/tasks' && req.method === 'POST') {
            const taskData = await parseBody(req);

            // 验证必填字段
            if (!taskData.id || !taskData.user_id || !taskData.title) {
                res.writeHead(400);
                res.end(JSON.stringify({
                    error: '缺少必填字段: id, user_id, title'
                }));
                return;
            }

            // 检查字段格式（验证我们的修复）
            console.log('收到任务数据:', JSON.stringify(taskData, null, 2));

            // 验证字段名是否正确（snake_case格式）
            const expectedFields = ['id', 'user_id', 'title', 'description', 'due_date', 'is_completed', 'device_id'];
            const receivedFields = Object.keys(taskData);

            console.log('期望字段:', expectedFields);
            console.log('收到字段:', receivedFields);

            // 检查是否有驼峰命名法字段（说明修复未生效）
            const camelCaseFields = receivedFields.filter(field =>
                ['userId', 'dueDate', 'isCompleted', 'deviceId'].includes(field)
            );

            if (camelCaseFields.length > 0) {
                console.log('❌ 发现驼峰命名法字段:', camelCaseFields);
                res.writeHead(400);
                res.end(JSON.stringify({
                    error: `字段名格式错误，发现驼峰命名法字段: ${camelCaseFields.join(', ')}。应使用下划线格式。`
                }));
                return;
            }

            console.log('✅ 字段格式正确，使用下划线命名法');

            // 添加时间戳
            taskData.created_at = new Date().toISOString();
            taskData.updated_at = new Date().toISOString();

            // 保存任务
            tasks.push(taskData);

            console.log(`✅ 任务创建成功: ${taskData.title}`);
            res.writeHead(201);
            res.end(JSON.stringify({
                message: '任务创建成功',
                task: taskData
            }));
            return;
        }

        // 404 错误
        res.writeHead(404);
        res.end(JSON.stringify({ error: 'Not Found' }));

    } catch (error) {
        console.error('服务器错误:', error);
        res.writeHead(500);
        res.end(JSON.stringify({ error: '服务器内部错误' }));
    }
});

// 启动服务器
server.listen(port, () => {
    console.log(`🚀 本地测试服务器启动成功！`);
    console.log(`📍 地址: http://localhost:${port}`);
    console.log(`🔍 健康检查: http://localhost:${port}/health`);
    console.log(`📝 任务API: http://localhost:${port}/api/tasks`);
    console.log(`🍅 番茄工作法API: http://localhost:${port}/api/pomodoro-sessions`);
    console.log(`\n等待iOS应用连接...`);
    console.log(`\n🔧 这是一个测试服务器，用于验证字段映射修复`);
});
