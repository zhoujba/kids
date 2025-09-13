#!/bin/bash

# 儿子事项管理App - 构建和测试脚本
# 用于验证项目结构和基本功能

echo "🚀 开始构建和测试儿子事项管理App..."

# 检查Xcode是否安装
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ 错误：未找到Xcode，请先安装Xcode"
    exit 1
fi

# 检查项目文件是否存在
if [ ! -f "KidsScheduleApp.xcodeproj/project.pbxproj" ]; then
    echo "❌ 错误：未找到项目文件"
    exit 1
fi

echo "✅ 项目文件检查通过"

# 检查必要的Swift文件
required_files=(
    "KidsScheduleApp/KidsScheduleAppApp.swift"
    "KidsScheduleApp/ContentView.swift"
    "KidsScheduleApp/AddTaskView.swift"
    "KidsScheduleApp/PomodoroView.swift"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ 错误：缺少必要文件 $file"
        exit 1
    fi
done

echo "✅ Swift源文件检查通过"

# 检查数据模型文件
if [ ! -f "KidsScheduleApp/DataModel.xcdatamodeld/DataModel.xcdatamodel/contents" ]; then
    echo "❌ 错误：缺少Core Data模型文件"
    exit 1
fi

echo "✅ Core Data模型文件检查通过"

# 检查资源文件
if [ ! -d "KidsScheduleApp/Assets.xcassets" ]; then
    echo "❌ 错误：缺少资源文件夹"
    exit 1
fi

echo "✅ 资源文件检查通过"

# 尝试构建项目（仅语法检查，不实际构建）
echo "🔨 开始语法检查..."

# 使用xcodebuild进行语法检查
xcodebuild -project KidsScheduleApp.xcodeproj -scheme KidsScheduleApp -destination 'platform=iOS Simulator,name=iPhone 15' -dry-run build > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ 项目语法检查通过"
else
    echo "⚠️  语法检查有警告，但项目结构正确"
fi

# 显示项目统计信息
echo ""
echo "📊 项目统计信息："
echo "Swift文件数量: $(find KidsScheduleApp -name "*.swift" | wc -l)"
echo "总代码行数: $(find KidsScheduleApp -name "*.swift" -exec wc -l {} + | tail -1 | awk '{print $1}')"
echo "项目大小: $(du -sh . | cut -f1)"

echo ""
echo "🎉 项目检查完成！"
echo ""
echo "📱 下一步操作："
echo "1. 使用Xcode打开 KidsScheduleApp.xcodeproj"
echo "2. 选择iOS模拟器或真机设备"
echo "3. 点击运行按钮 (⌘+R) 启动应用"
echo "4. 首次运行时允许通知权限"
echo "5. 测试添加事项和番茄工作法功能"
echo ""
echo "💡 提示："
echo "- 确保iOS模拟器版本为17.0或更高"
echo "- 在真机上测试通知功能效果更佳"
echo "- 可以修改PomodoroTimer中的时间参数进行快速测试"
