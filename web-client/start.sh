#!/bin/bash

# 儿童任务管理Web版 - 启动脚本
# 快速启动Web客户端的便捷脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 图标
ROCKET="🚀"
CHECK="✅"
CROSS="❌"
WARNING="⚠️"
INFO="💡"
WEB="🌐"
PHONE="📱"

echo -e "${CYAN}${ROCKET} 儿童任务管理Web版启动器${NC}"
echo -e "${CYAN}================================${NC}"

# 检查当前目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}📁 工作目录: $SCRIPT_DIR${NC}"

# 检查必要文件
echo -e "${BLUE}🔍 检查必要文件...${NC}"

required_files=("index.html" "app.js" "server.py")
missing_files=()

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}${CHECK} $file${NC}"
    else
        echo -e "${RED}${CROSS} $file (缺失)${NC}"
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -ne 0 ]; then
    echo -e "${RED}${CROSS} 缺少必要文件，无法启动${NC}"
    exit 1
fi

# 检查Python环境
echo -e "${BLUE}🐍 检查Python环境...${NC}"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1)
    echo -e "${GREEN}${CHECK} $PYTHON_VERSION${NC}"
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_VERSION=$(python --version 2>&1)
    echo -e "${YELLOW}${WARNING} 使用 $PYTHON_VERSION${NC}"
    PYTHON_CMD="python"
else
    echo -e "${RED}${CROSS} 未找到Python环境${NC}"
    echo -e "${INFO} 请安装Python 3.6+${NC}"
    exit 1
fi

# 检查端口占用
PORT=8000
echo -e "${BLUE}🔌 检查端口 $PORT...${NC}"

if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${YELLOW}${WARNING} 端口 $PORT 已被占用${NC}"
    
    # 尝试其他端口
    for alt_port in 8001 8002 8003 8080 3000; do
        if ! lsof -Pi :$alt_port -sTCP:LISTEN -t >/dev/null 2>&1; then
            PORT=$alt_port
            echo -e "${GREEN}${CHECK} 使用替代端口: $PORT${NC}"
            break
        fi
    done
    
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${RED}${CROSS} 无可用端口，请手动停止占用进程${NC}"
        echo -e "${INFO} 查看端口占用: lsof -i :8000${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}${CHECK} 端口 $PORT 可用${NC}"
fi

# 检查网络连接
echo -e "${BLUE}🌐 检查WebSocket服务器连接...${NC}"
WS_HOST="ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com"
WS_PORT="8082"

if nc -z "$WS_HOST" "$WS_PORT" 2>/dev/null; then
    echo -e "${GREEN}${CHECK} WebSocket服务器连接正常${NC}"
else
    echo -e "${YELLOW}${WARNING} 无法连接到WebSocket服务器${NC}"
    echo -e "${INFO} 请检查网络连接或服务器状态${NC}"
    echo -e "${INFO} 服务器地址: $WS_HOST:$WS_PORT${NC}"
fi

echo -e "${CYAN}================================${NC}"

# 显示启动信息
echo -e "${GREEN}${ROCKET} 准备启动Web服务器...${NC}"
echo -e "${BLUE}${WEB} 本地地址: http://localhost:$PORT${NC}"
echo -e "${BLUE}${PHONE} 与iOS应用实时同步${NC}"
echo -e "${BLUE}🔗 WebSocket: ws://$WS_HOST:$WS_PORT/ws${NC}"

echo ""
echo -e "${PURPLE}💡 使用说明:${NC}"
echo -e "   • 浏览器将自动打开Web应用"
echo -e "   • 确保iOS应用也在运行"
echo -e "   • 任务数据将实时同步"
echo -e "   • 按 Ctrl+C 停止服务器"

echo ""
echo -e "${CYAN}================================${NC}"

# 询问是否继续
read -p "$(echo -e ${GREEN}是否启动服务器？ [Y/n]: ${NC})" -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}${WARNING} 用户取消启动${NC}"
    exit 0
fi

echo -e "${GREEN}${ROCKET} 启动中...${NC}"
echo ""

# 设置执行权限
chmod +x server.py

# 启动服务器
if [ "$PORT" != "8000" ]; then
    exec $PYTHON_CMD server.py --port $PORT
else
    exec $PYTHON_CMD server.py
fi
