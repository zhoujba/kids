#!/usr/bin/env python3
"""
TaskFlow Web版 - 本地服务器
专业的个人效率提升工具
"""

import http.server
import socketserver
import webbrowser
import os
import sys
from pathlib import Path

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # 添加CORS头，允许跨域请求
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

    def log_message(self, format, *args):
        # 自定义日志格式
        print(f"📡 {self.address_string()} - {format % args}")

def main():
    # 设置端口
    PORT = 8000
    
    # 确保在正确的目录中
    script_dir = Path(__file__).parent
    os.chdir(script_dir)
    
    print("🚀 启动TaskFlow Web版...")
    print(f"📁 工作目录: {script_dir}")
    print(f"🌐 端口: {PORT}")
    
    # 检查必要文件
    required_files = ['index.html', 'app.js']
    missing_files = [f for f in required_files if not Path(f).exists()]
    
    if missing_files:
        print(f"❌ 缺少必要文件: {', '.join(missing_files)}")
        sys.exit(1)
    
    try:
        # 创建服务器
        with socketserver.TCPServer(("", PORT), CustomHTTPRequestHandler) as httpd:
            print(f"✅ 服务器启动成功")
            print(f"🔗 本地地址: http://localhost:{PORT}")
            print(f"🔗 网络地址: http://0.0.0.0:{PORT}")
            print("📱 与iOS应用实时同步")
            print("🌐 WebSocket服务器: ec2-18-183-213-175.ap-northeast-1.compute.amazonaws.com:8082")
            print("\n💡 使用说明:")
            print("   - 在浏览器中打开上述地址")
            print("   - 确保网络连接正常")
            print("   - 与iOS应用数据实时同步")
            print("   - 按 Ctrl+C 停止服务器")
            print("\n" + "="*60)
            
            # 自动打开浏览器
            try:
                webbrowser.open(f'http://localhost:{PORT}')
                print("🌐 已自动打开浏览器")
            except Exception as e:
                print(f"⚠️ 无法自动打开浏览器: {e}")
                print(f"请手动访问: http://localhost:{PORT}")
            
            print("="*60)
            print("🎯 服务器运行中...")
            
            # 启动服务器
            httpd.serve_forever()
            
    except KeyboardInterrupt:
        print("\n🛑 收到停止信号")
        print("✅ 服务器已停止")
    except OSError as e:
        if e.errno == 48:  # Address already in use
            print(f"❌ 端口 {PORT} 已被占用")
            print("💡 解决方案:")
            print(f"   1. 更换端口: python3 server.py --port 8001")
            print(f"   2. 停止占用进程: lsof -ti:{PORT} | xargs kill")
        else:
            print(f"❌ 服务器启动失败: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ 未知错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    # 检查命令行参数
    if len(sys.argv) > 1:
        if sys.argv[1] == '--help' or sys.argv[1] == '-h':
            print("TaskFlow Web版 - 本地服务器")
            print("\n使用方法:")
            print("  python3 server.py              # 默认端口8000")
            print("  python3 server.py --port 8001  # 指定端口")
            print("  python3 server.py --help       # 显示帮助")
            print("\n功能特性:")
            print("  ✅ 专业的个人效率提升工具")
            print("  ✅ 实时同步，多设备协作")
            print("  ✅ 智能分类和优先级管理")
            print("  ✅ 时间管理和看板视图")
            print("  ✅ 响应式设计，支持各种屏幕")
            print("  ✅ 自动重连WebSocket")
            sys.exit(0)
        elif sys.argv[1] == '--port' and len(sys.argv) > 2:
            try:
                PORT = int(sys.argv[2])
                if PORT < 1024 or PORT > 65535:
                    print("❌ 端口范围应在 1024-65535 之间")
                    sys.exit(1)
            except ValueError:
                print("❌ 端口必须是数字")
                sys.exit(1)
    
    main()
