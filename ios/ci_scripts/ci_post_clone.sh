#!/bin/sh

# 如果任何命令失败，立即退出
set -e

echo "--- [CI] Starting ci_post_clone.sh script (v4 - Final) ---"

# 日志显示，脚本是从 ios/ci_scripts 目录运行的。
# 我们需要返回到项目的根目录，也就是向上两级。
echo "Current directory: $(pwd)"
echo "Navigating to project root..."
cd ../..
echo "Now in project root: $(pwd)"

# 在项目根目录下，克隆 Flutter
echo "Cloning Flutter into project root..."
git clone --branch stable https://github.com/flutter/flutter.git --depth 1

# 将刚刚克隆的 Flutter 添加到系统路径中
# $PWD 现在是项目的根目录
export PATH="$PWD/flutter/bin:$PATH"

# 打印 Flutter 信息以供调试，确认路径设置成功
echo "Flutter path: $(which flutter)"
echo "Flutter version:"
flutter --version

# 运行 flutter doctor 检查环境
echo "Running flutter doctor..."
flutter doctor

# 在项目根目录运行 'flutter pub get' 来安装所有依赖
echo "Running 'flutter pub get'..."
flutter pub get

echo "--- [CI] Finished ci_post_clone.sh script successfully ---"
