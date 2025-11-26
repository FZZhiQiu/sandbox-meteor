#!/bin/bash

# Termux Android SDK 安装脚本
# 为在Termux中本地构建APK准备完整的Android SDK环境

set -e

# 颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🚀 Termux Android SDK 安装脚本${NC}"
echo -e "${PURPLE}==============================${NC}\n"

# 检查是否在Termux环境中
if [ ! -d "/data/data/com.termux/files" ]; then
    echo -e "${RED}❌ 错误: 此脚本仅适用于Termux环境${NC}"
    exit 1
fi

# 检查是否已安装必要工具
check_tools() {
    echo -e "${YELLOW}🔍 检查必要工具...${NC}"
    
    if ! command -v pkg &> /dev/null; then
        echo -e "${RED}❌ 错误: pkg 未安装${NC}"
        exit 1
    fi
    
    if ! command -v wget &> /dev/null; then
        echo -e "${YELLOW}⚠️  安装 wget...${NC}"
        pkg install wget -y
    fi
    
    if ! command -v unzip &> /dev/null; then
        echo -e "${YELLOW}⚠️  安装 unzip...${NC}"
        pkg install unzip -y
    fi
    
    echo -e "${GREEN}✅ 必要工具检查完成${NC}"
}

# 安装基础依赖
install_base_deps() {
    echo -e "${YELLOW}🔧 安装基础依赖...${NC}"
    
    pkg update -y
    pkg install openjdk-17 -y
    
    echo -e "${GREEN}✅ 基础依赖安装完成${NC}"
}

# 设置环境变量
setup_env() {
    echo -e "${YELLOW}🔧 设置环境变量...${NC}"
    
    # 设置Android SDK路径
    export ANDROID_HOME="$HOME/android-sdk"
    export ANDROID_SDK_ROOT="$ANDROID_HOME"
    
    # 创建目录
    mkdir -p "$ANDROID_HOME"
    
    # 添加到bashrc
    echo "export ANDROID_HOME=$ANDROID_HOME" >> ~/.bashrc
    echo "export ANDROID_SDK_ROOT=$ANDROID_HOME" >> ~/.bashrc
    echo "export PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools" >> ~/.bashrc
    
    echo -e "${GREEN}✅ 环境变量设置完成${NC}"
}

# 下载和安装Android SDK
install_android_sdk() {
    echo -e "${YELLOW}📥 下载和安装Android SDK...${NC}"
    
    # 进入SDK目录
    cd "$ANDROID_HOME"
    
    # 下载命令行工具
    echo -e "${CYAN}下载命令行工具...${NC}"
    wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O cmdline-tools.zip
    
    # 解压
    echo -e "${CYAN}解压命令行工具...${NC}"
    mkdir -p cmdline-tools
    unzip cmdline-tools.zip -d cmdline-tools/
    
    # 重命名目录
    mv cmdline-tools/cmdline-tools/ cmdline-tools/latest/
    
    # 更新SDK
    echo -e "${CYAN}更新SDK...${NC}"
    yes | sdkmanager --update
    
    # 安装必要组件
    echo -e "${CYAN}安装必要组件...${NC}"
    yes | sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" \
        "ndk;25.2.9519653" "cmake;3.22.1"
    
    # 接受许可证
    echo -e "${CYAN}接受许可证...${NC}"
    yes | sdkmanager --licenses
    
    echo -e "${GREEN}✅ Android SDK安装完成${NC}"
}

# 验证安装
verify_installation() {
    echo -e "${YELLOW}🔍 验证安装...${NC}"
    
    # 检查工具是否可用
    if command -v sdkmanager &> /dev/null; then
        echo -e "${GREEN}✅ sdkmanager 可用${NC}"
    else
        echo -e "${RED}❌ sdkmanager 不可用${NC}"
        return 1
    fi
    
    if command -v adb &> /dev/null; then
        echo -e "${GREEN}✅ adb 可用${NC}"
    else
        echo -e "${RED}❌ adb 不可用${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ 安装验证完成${NC}"
}

# 创建构建脚本
create_build_script() {
    echo -e "${YELLOW}📝 创建构建脚本...${NC}"
    
    cat > ~/build_apk_local.sh << 'EOF'
#!/bin/bash

# 本地APK构建脚本
# 使用完整的Android SDK环境构建APK

set -e

# 颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🚀 本地APK构建脚本${NC}"
echo -e "${PURPLE}==================${NC}\n"

# 设置环境变量
export ANDROID_HOME="$HOME/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
export JAVA_HOME="/data/data/com.termux/files/usr/lib/jvm/java-17-openjdk"

# 检查是否在正确的项目目录中
if [ ! -f "settings.gradle" ] || [ ! -f "build.gradle" ]; then
    echo -e "${RED}❌ 错误: 未在正确的Android项目目录中${NC}"
    exit 1
fi

echo -e "${YELLOW}🔧 准备构建环境...${NC}"

# 确保gradlew可执行
chmod +x ./gradlew

# 清理之前的构建
echo -e "${YELLOW}🧹 清理之前的构建...${NC}"
./gradlew clean

# 构建APK
echo -e "${YELLOW}🏗️  构建APK...${NC}"
echo -e "${CYAN}这可能需要几分钟时间...${NC}"

./gradlew assembleDebug \
    --no-daemon \
    -x test \
    -x lint \
    --console=plain \
    --max-workers=1 \
    -Dorg.gradle.jvmargs="-Xmx2g -XX:MaxMetaspaceSize=512m"

# 验证APK输出
echo -e "${YELLOW}🔍 验证APK输出...${NC}"

APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo -e "${GREEN}✅ APK构建成功!${NC}"
    echo -e "${GREEN}📁 APK路径: $APK_PATH${NC}"
    echo -e "${GREEN}📊 APK大小: $APK_SIZE${NC}"
    
    # 复制到apk目录
    mkdir -p apk
    cp "$APK_PATH" "apk/sandbox-meteor-debug.apk"
    echo -e "${GREEN}📁 已复制到: apk/sandbox-meteor-debug.apk${NC}"
else
    echo -e "${RED}❌ 错误: APK未创建${NC}"
    exit 1
fi

echo -e "\n${GREEN}🎉 构建完成!${NC}"
EOF

    chmod +x ~/build_apk_local.sh
    
    echo -e "${GREEN}✅ 构建脚本创建完成${NC}"
    echo -e "${GREEN}📁 脚本位置: ~/build_apk_local.sh${NC}"
}

# 主函数
main() {
    check_tools
    install_base_deps
    setup_env
    install_android_sdk
    verify_installation
    create_build_script
    
    echo -e "\n${GREEN}🎉 Android SDK安装完成!${NC}"
    echo -e "${GREEN}💡 要开始构建APK，请运行: ~/build_apk_local.sh${NC}"
    echo -e "${GREEN}💡 您可能需要重新启动Termux或运行: source ~/.bashrc${NC}"
}

# 运行主函数
main "$@"