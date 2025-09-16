#!/bin/bash

# 项目清理脚本 - 删除无关和测试文件，保留核心代码

echo "🧹 开始清理项目，删除无关文件..."

# 要删除的测试和无关文件
FILES_TO_DELETE=(
    # 测试HTML文件
    "debug_test.html"
    "simple_test.html"
    "test-aws-websocket.html"
    "test-json-parse.go"
    "test-websocket-realtime.html"
    "test-websocket.html"
    "test_websocket.html"
    "websocket_test_clean.html"
    
    # 临时和测试脚本
    "local-test-server.js"
    "local_proxy.py"
    "mysql_api_server.py"
    "start_test_server.py"
    "temp_index.php"
    "test_php_api.sh"
    "test_sqlite_api.sh"
    
    # 旧的部署脚本（保留新的deploy.sh）
    "deploy_websocket.sh"
    "start_websocket_server.sh"
    "setup_cloudflare_tunnel.sh"
    
    # 旧的API服务器
    "go-api-main.go"
    
    # 不需要的Package.swift（这是iOS项目，不是Swift Package）
    "Package.swift"
)

# 要删除的目录
DIRS_TO_DELETE=(
    # PHP MySQL API（已不使用）
    "php-mysql-api"
    
    # PHP SQLite API（已不使用，WebSocket服务器直接操作SQLite）
    "php-sqlite-api"
    
    # 部署目录中的MySQL相关文件（已不使用）
    "deployment"
)

# 删除文件
for file in "${FILES_TO_DELETE[@]}"; do
    if [ -f "$file" ]; then
        echo "🗑️ 删除文件: $file"
        rm "$file"
    fi
done

# 删除目录
for dir in "${DIRS_TO_DELETE[@]}"; do
    if [ -d "$dir" ]; then
        echo "🗑️ 删除目录: $dir"
        rm -rf "$dir"
    fi
done

# 清理WebSocket服务器目录中的编译产物
if [ -d "websocket-server" ]; then
    echo "🧹 清理WebSocket服务器编译产物..."
    cd websocket-server
    rm -f main websocket-server websocket-server-debug websocket-server-linux websocket-server-linux-new
    cd ..
fi

# 清理Xcode用户数据
if [ -d "KidsScheduleApp.xcodeproj/xcuserdata" ]; then
    echo "🧹 清理Xcode用户数据..."
    rm -rf "KidsScheduleApp.xcodeproj/xcuserdata"
fi

echo "✅ 项目清理完成！"
echo ""
echo "📋 保留的核心文件："
echo "  📱 iOS应用: KidsScheduleApp/"
echo "  🔧 项目配置: KidsScheduleApp.xcodeproj/"
echo "  🌐 WebSocket服务器: websocket-server/"
echo "  📚 文档: *.md"
echo "  🚀 部署脚本: deploy.sh"
echo "  🔨 构建脚本: build_and_test.sh"
