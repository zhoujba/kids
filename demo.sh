#!/bin/bash

# TaskFlow - 演示脚本
# 专业的个人效率提升工具演示

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
COMPUTER="💻"

echo -e "${CYAN}${ROCKET} TaskFlow - 专业效率工具演示${NC}"
echo -e "${CYAN}========================================${NC}"

echo -e "${BLUE}${INFO} 项目概述：${NC}"
echo -e "   • ${PHONE} iOS应用：SwiftUI + Core Data"
echo -e "   • ${WEB} Web版：HTML5 + JavaScript"
echo -e "   • ${COMPUTER} 服务器：Go + SQLite + WebSocket"
echo -e "   • ☁️ 部署：AWS EC2 + 自动化CI/CD"

echo ""
echo -e "${PURPLE}🎯 核心功能：${NC}"
echo -e "   • 实时同步：多设备间任务数据实时同步"
echo -e "   • 任务管理：创建、编辑、删除、完成任务"
echo -e "   • 分类管理：学习、运动、娱乐等分类"
echo -e "   • 优先级设置：高、中、低三级优先级"
echo -e "   • 跨平台：iOS应用 + Web版客户端"

echo ""
echo -e "${CYAN}========================================${NC}"

# 检查服务器状态
echo -e "${BLUE}🔍 检查系统状态...${NC}"

echo -e "${BLUE}   检查WebSocket服务器...${NC}"
if curl -s http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/health | grep -q "ok"; then
    echo -e "${GREEN}   ${CHECK} WebSocket服务器运行正常${NC}"
else
    echo -e "${RED}   ${CROSS} WebSocket服务器连接失败${NC}"
fi

echo -e "${BLUE}   检查自动部署系统...${NC}"
if ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'sudo systemctl is-active git-webhook' | grep -q "active"; then
    echo -e "${GREEN}   ${CHECK} 自动部署系统运行正常${NC}"
else
    echo -e "${YELLOW}   ${WARNING} 自动部署系统状态未知${NC}"
fi

echo ""
echo -e "${CYAN}========================================${NC}"

# 演示选项
echo -e "${GREEN}${ROCKET} 选择演示内容：${NC}"
echo -e "   1. ${PHONE} 启动iOS应用（Xcode）"
echo -e "   2. ${WEB} 启动Web版客户端"
echo -e "   3. ${COMPUTER} 查看服务器状态"
echo -e "   4. 🔄 测试自动部署"
echo -e "   5. 📊 查看项目统计"
echo -e "   6. 📚 查看文档"
echo -e "   0. 退出"

echo ""
read -p "$(echo -e ${CYAN}请选择 [1-6, 0]: ${NC})" choice

case $choice in
    1)
        echo -e "${GREEN}${PHONE} 启动iOS应用...${NC}"
        if [ -f "KidsScheduleApp.xcodeproj/project.pbxproj" ]; then
            echo -e "${INFO} 正在打开Xcode项目..."
            open KidsScheduleApp.xcodeproj
            echo -e "${GREEN}${CHECK} Xcode已打开，请选择设备并按⌘+R运行${NC}"
        else
            echo -e "${RED}${CROSS} 未找到Xcode项目文件${NC}"
        fi
        ;;
    2)
        echo -e "${GREEN}${WEB} 启动Web版客户端...${NC}"
        if [ -d "web-client" ]; then
            echo -e "${INFO} 正在启动Web服务器..."
            cd web-client
            if [ -f "start.sh" ]; then
                ./start.sh
            else
                python3 server.py
            fi
        else
            echo -e "${RED}${CROSS} 未找到Web客户端目录${NC}"
        fi
        ;;
    3)
        echo -e "${GREEN}${COMPUTER} 查看服务器状态...${NC}"
        
        echo -e "${BLUE}WebSocket服务器健康检查：${NC}"
        curl -s http://ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082/health || echo "连接失败"
        
        echo -e "\n${BLUE}服务器进程状态：${NC}"
        ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'pgrep -f websocket-server-linux && echo "WebSocket服务器运行中" || echo "WebSocket服务器未运行"'
        
        echo -e "\n${BLUE}最近部署日志：${NC}"
        ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'tail -5 /home/ec2-user/webhook/deploy.log'
        ;;
    4)
        echo -e "${GREEN}🔄 测试自动部署...${NC}"
        
        echo -e "${INFO} 创建测试提交..."
        echo "# 自动部署测试 - $(date)" >> test_deploy.md
        git add test_deploy.md
        git commit -m "🧪 测试自动部署功能 - $(date +%H:%M:%S)"
        
        echo -e "${INFO} 推送到GitHub..."
        git push origin main
        
        echo -e "${INFO} 等待自动部署完成（约10秒）..."
        sleep 12
        
        echo -e "${BLUE}检查部署结果：${NC}"
        ssh -i "~/Downloads/miyao.pem" ec2-user@ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com 'tail -3 /home/ec2-user/webhook/deploy.log'
        
        # 清理测试文件
        rm -f test_deploy.md
        git add test_deploy.md
        git commit -m "🧹 清理测试文件"
        git push origin main
        ;;
    5)
        echo -e "${GREEN}📊 项目统计信息...${NC}"
        
        echo -e "${BLUE}代码统计：${NC}"
        echo -e "   Swift文件: $(find . -name "*.swift" | wc -l | tr -d ' ')"
        echo -e "   Go文件: $(find . -name "*.go" | wc -l | tr -d ' ')"
        echo -e "   JavaScript文件: $(find . -name "*.js" | wc -l | tr -d ' ')"
        echo -e "   HTML文件: $(find . -name "*.html" | wc -l | tr -d ' ')"
        echo -e "   Markdown文档: $(find . -name "*.md" | wc -l | tr -d ' ')"
        
        echo -e "\n${BLUE}Git统计：${NC}"
        echo -e "   总提交数: $(git rev-list --count HEAD)"
        echo -e "   最近提交: $(git log -1 --format='%h - %s (%cr)')"
        
        echo -e "\n${BLUE}文件大小：${NC}"
        echo -e "   项目总大小: $(du -sh . | cut -f1)"
        echo -e "   iOS应用: $(du -sh KidsScheduleApp 2>/dev/null | cut -f1 || echo '未知')"
        echo -e "   Web客户端: $(du -sh web-client 2>/dev/null | cut -f1 || echo '未知')"
        echo -e "   WebSocket服务器: $(du -sh websocket-server 2>/dev/null | cut -f1 || echo '未知')"
        ;;
    6)
        echo -e "${GREEN}📚 项目文档...${NC}"
        
        echo -e "${BLUE}主要文档：${NC}"
        echo -e "   📖 README.md - 项目主文档"
        echo -e "   📋 USER_GUIDE.md - 详细使用指南"
        echo -e "   ⚡ QUICK_REFERENCE.md - 快速参考"
        echo -e "   ✅ PROJECT_CHECKLIST.md - 检查清单"
        echo -e "   🌐 web-client/README.md - Web版说明"
        
        echo -e "\n${BLUE}技术文档：${NC}"
        echo -e "   🚀 DEPLOYMENT_GUIDE.md - 部署指南"
        echo -e "   📊 PROJECT_SUMMARY.md - 项目总结"
        echo -e "   🔧 WebSocket实时同步架构说明.md"
        
        echo -e "\n${INFO} 使用 'open README.md' 查看主文档${NC}"
        ;;
    0)
        echo -e "${YELLOW}👋 演示结束${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}${CROSS} 无效选择${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}${CHECK} 演示完成！${NC}"
echo -e "${INFO} 查看完整文档：README.md${NC}"
echo -e "${INFO} 快速参考：QUICK_REFERENCE.md${NC}"
echo -e "${INFO} 使用指南：USER_GUIDE.md${NC}"
