#!/usr/bin/env python3
"""
创建TaskFlow应用Logo
生成不同尺寸的应用图标
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_logo():
    """创建TaskFlow应用的Logo"""
    
    # 创建图标目录
    os.makedirs("icons", exist_ok=True)
    
    # 定义颜色
    primary_color = "#007AFF"  # iOS蓝色
    secondary_color = "#34C759"  # iOS绿色
    background_color = "#FFFFFF"  # 白色背景
    
    # 需要生成的尺寸
    sizes = [
        (1024, 1024),  # App Store
        (512, 512),    # 大图标
        (256, 256),    # 中等图标
        (128, 128),    # 小图标
        (64, 64),      # 最小图标
        (32, 32),      # Favicon
    ]
    
    for width, height in sizes:
        # 创建画布
        img = Image.new('RGB', (width, height), background_color)
        draw = ImageDraw.Draw(img)
        
        # 计算尺寸比例
        scale = width / 1024
        
        # 绘制圆形背景
        margin = int(80 * scale)
        circle_bbox = [margin, margin, width - margin, height - margin]
        draw.ellipse(circle_bbox, fill=primary_color)
        
        # 绘制任务列表图标
        # 绘制三个矩形代表任务项
        task_width = int(400 * scale)
        task_height = int(60 * scale)
        task_spacing = int(80 * scale)
        start_x = (width - task_width) // 2
        start_y = int(300 * scale)
        
        for i in range(3):
            y = start_y + i * (task_height + task_spacing)
            
            # 任务矩形
            task_rect = [start_x, y, start_x + task_width, y + task_height]
            draw.rectangle(task_rect, fill=background_color, outline=None)
            
            # 复选框
            checkbox_size = int(40 * scale)
            checkbox_x = start_x + int(20 * scale)
            checkbox_y = y + (task_height - checkbox_size) // 2
            checkbox_rect = [checkbox_x, checkbox_y, checkbox_x + checkbox_size, checkbox_y + checkbox_size]
            
            if i == 0:  # 第一个任务已完成
                draw.rectangle(checkbox_rect, fill=secondary_color)
                # 绘制对勾
                check_points = [
                    (checkbox_x + int(8 * scale), checkbox_y + int(20 * scale)),
                    (checkbox_x + int(16 * scale), checkbox_y + int(28 * scale)),
                    (checkbox_x + int(32 * scale), checkbox_y + int(12 * scale))
                ]
                draw.line(check_points[:2], fill=background_color, width=int(4 * scale))
                draw.line(check_points[1:], fill=background_color, width=int(4 * scale))
            else:  # 其他任务未完成
                draw.rectangle(checkbox_rect, fill=background_color, outline=primary_color, width=int(3 * scale))
        
        # 添加流动效果 - 右上角的箭头
        arrow_size = int(80 * scale)
        arrow_x = width - int(150 * scale)
        arrow_y = int(150 * scale)
        
        # 绘制向上的箭头
        arrow_points = [
            (arrow_x, arrow_y + arrow_size),
            (arrow_x + arrow_size // 2, arrow_y),
            (arrow_x + arrow_size, arrow_y + arrow_size),
            (arrow_x + arrow_size * 0.7, arrow_y + arrow_size),
            (arrow_x + arrow_size // 2, arrow_y + arrow_size * 0.4),
            (arrow_x + arrow_size * 0.3, arrow_y + arrow_size)
        ]
        draw.polygon(arrow_points, fill=secondary_color)
        
        # 保存图标
        filename = f"icons/taskflow_logo_{width}x{height}.png"
        img.save(filename, "PNG", quality=95)
        print(f"✅ 创建图标: {filename}")
    
    # 创建Web版favicon
    favicon = Image.open("icons/taskflow_logo_32x32.png")
    favicon.save("web-client/favicon.ico", format="ICO")
    print("✅ 创建Web版favicon: web-client/favicon.ico")
    
    # 创建iOS应用图标 (需要特定尺寸)
    ios_sizes = [
        (180, 180, "AppIcon-60@3x"),      # iPhone
        (120, 120, "AppIcon-60@2x"),      # iPhone
        (152, 152, "AppIcon-76@2x"),      # iPad
        (76, 76, "AppIcon-76"),           # iPad
        (167, 167, "AppIcon-83.5@2x"),    # iPad Pro
        (1024, 1024, "AppIcon-1024"),     # App Store
    ]
    
    ios_dir = "KidsScheduleApp/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(ios_dir, exist_ok=True)
    
    for width, height, name in ios_sizes:
        # 如果没有对应尺寸的图标，从最接近的尺寸缩放
        source_file = f"icons/taskflow_logo_{width}x{height}.png"
        if not os.path.exists(source_file):
            # 使用1024x1024作为源图像进行缩放
            source_img = Image.open("icons/taskflow_logo_1024x1024.png")
            img = source_img.resize((width, height), Image.Resampling.LANCZOS)
        else:
            img = Image.open(source_file)

        ios_filename = f"{ios_dir}/{name}.png"
        img.save(ios_filename, "PNG", quality=95)
        print(f"✅ 创建iOS图标: {ios_filename}")
    
    print("\n🎉 Logo创建完成！")
    print("📁 图标文件位置：")
    print("   - icons/ - 通用图标")
    print("   - web-client/favicon.ico - Web版图标")
    print("   - KidsScheduleApp/Assets.xcassets/AppIcon.appiconset/ - iOS应用图标")

if __name__ == "__main__":
    try:
        create_logo()
    except ImportError:
        print("❌ 需要安装Pillow库：pip install Pillow")
    except Exception as e:
        print(f"❌ 创建Logo时出错：{e}")
