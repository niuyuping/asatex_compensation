#!/bin/sh

# 当任何命令失败时，立即退出
set -e

# --- Flutter 环境设置 ---
# Xcode Cloud 默认已安装 Flutter，我们可以在这里指定一个版本（如果需要）
# 或者直接使用默认版本。
# 为了确保使用的是最新版本，我们可以从 Flutter 的 git 仓库获取。
git clone https://github.com/flutter/flutter.git --depth 1
export PATH="$PWD/flutter/bin:$PATH"

echo "Flutter version:"
flutter --version

# --- 安装依赖 ---
echo "Running 'flutter pub get' to install Dart dependencies and trigger pod install..."
flutter pub get

echo "Post-clone script completed successfully."

exit 0
