#!/bin/bash
# Flutter 代码检查脚本

echo "=== 检查 Flutter 依赖 ==="
cd mobile
flutter pub get

echo ""
echo "=== 运行 flutter analyze ==="
flutter analyze

echo ""
echo "=== 如果有错误，尝试详细诊断 ==="
if [ $? -ne 0 ]; then
    flutter doctor -v
fi
