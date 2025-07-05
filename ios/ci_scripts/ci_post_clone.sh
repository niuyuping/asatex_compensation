#!/bin/sh

# 如果任何命令失败，立即退出
set -e

echo "--- [CI] Starting ci_post_clone.sh script (v6 - The Ultimate) ---"

# 导航到项目根目录 (已验证此方法有效)
echo "Navigating to project root..."
cd ../..
echo "Now in project root: $(pwd)"

# 克隆 Flutter 稳定版
echo "Cloning Flutter (stable branch)..."
git clone --branch stable https://github.com/flutter/flutter.git --depth 1
export PATH="$PWD/flutter/bin:$PATH"

# 打印 Flutter 信息以供调试
echo "Flutter path: $(which flutter)"
flutter --version

# 预先下载和缓存 iOS 构建工具 (关键改进)
echo "Precaching Flutter iOS artifacts..."
flutter precache --ios

# 安装 Dart 依赖
echo "Running 'flutter pub get'..."
flutter pub get

# 确保 CocoaPods 已安装 (关键改进)
echo "Installing CocoaPods via Homebrew..."
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods

# 明确地、彻底地重新安装原生 iOS 依赖 (关键改进)
echo "Navigating to ios directory to deintegrate and update pods..."
cd ios
echo "Now in directory: $(pwd)"

echo "Deintegrating pods for a clean state..."
pod deintegrate

echo "Updating pods..."
pod update

echo "--- [CI] Finished ci_post_clone.sh script successfully ---"
# 脚本在这里结束，把控制权交还给 Xcode Cloud 去执行 Archive 操作
exit 0
