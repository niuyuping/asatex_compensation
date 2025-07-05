#!/bin/sh

# 如果任何命令失败，立即退出
set -e

echo "--- [CI] Starting ci_post_clone.sh script ---"

# 脚本默认在仓库根目录执行，这里我们确认一下
echo "Workspace directory: $CI_WORKSPACE"
cd $CI_WORKSPACE

# 安装 Flutter
echo "Cloning Flutter from GitHub..."
git clone https://github.com/flutter/flutter.git --depth 1
export PATH="$CI_WORKSPACE/flutter/bin:$PATH"

# 打印版本号和路径以供调试
echo "Flutter path: $(which flutter)"
echo "Flutter version:"
flutter --version

# 运行 flutter doctor 检查环境
echo "Running flutter doctor..."
flutter doctor

# 获取 Dart 和 Flutter 依赖
echo "Running 'flutter pub get'..."
flutter pub get

# 为了确保万无一失，我们手动进入 ios 目录并运行 pod install
echo "Navigating to ios directory to run pod install..."
cd ios
pod install

echo "--- [CI] Finished ci_post_clone.sh script ---"
