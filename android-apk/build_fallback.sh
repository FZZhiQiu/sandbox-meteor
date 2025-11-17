#!/bin/bash

# 统一构建管理脚本
# 自动选择最佳构建方式，如果主要方式失败则使用备用方案

set -e

# 颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🚀 统一构建管理脚本${NC}"
echo -e "${PURPLE}=====================${NC}\n"

# 构建方案数组
BUILD_METHODS=(
    "github_actions"    # 主要方案
    "docker"           # 方案1: Docker本地构建
    "android_studio"   # 方案2: Android Studio (说明)
    "bitrise"          # 方案3: Bitrise构建
    "termux_sdk"       # 方案4: Termux完整SDK
    "codespaces"       # 方案5: 预构建环境
)

# 检查是否在正确的项目目录中
if [ ! -f "settings.gradle" ] || [ ! -f "build.gradle" ]; then
    echo -e "${RED}❌ 错误: 未在正确的Android项目目录中${NC}"
    exit 1
fi

# 方案1: Docker本地构建
build_with_docker() {
    echo -e "${YELLOW}方案1: Docker本地构建${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker未安装，跳过此方案${NC}"
        return 1
    fi
    
    echo -e "${CYAN}构建Docker镜像...${NC}"
    if docker build -t sandbox-meteor-builder .; then
        echo -e "${CYAN}运行Docker构建...${NC}"
        if docker run --rm -v $(pwd)/apk:/workspace/app/build/outputs/apk/debug/ sandbox-meteor-builder; then
            echo -e "${GREEN}✅ Docker构建成功!${NC}"
            return 0
        else
            echo -e "${RED}❌ Docker构建失败${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Docker镜像构建失败${NC}"
        return 1
    fi
}

# 方案2: Android Studio (说明)
build_with_android_studio() {
    echo -e "${YELLOW}方案2: Android Studio构建${NC}"
    echo -e "${CYAN}此方案需要手动操作:${NC}"
    echo -e "${CYAN}- 在Android Studio中打开此项目${NC}"
    echo -e "${CYAN}- 等待项目同步完成${NC}"
    echo -e "${CYAN}- 选择Build > Build Bundle(s) / APK(s) > Build APK${NC}"
    echo -e "${CYAN}- APK将在app/build/outputs/apk/debug/目录中生成${NC}"
    echo -e "${GREEN}✅ Android Studio导入说明已创建: ANDROID_STUDIO_IMPORT.md${NC}"
    return 0
}

# 方案3: Bitrise构建
build_with_bitrise() {
    echo -e "${YELLOW}方案3: Bitrise构建${NC}"
    
    if [ ! -f "BITRISE_SETUP.md" ]; then
        echo -e "${RED}❌ Bitrise配置文件不存在${NC}"
        return 1
    fi
    
    if [ ! -f "build_with_bitrise.sh" ]; then
        echo -e "${RED}❌ Bitrise构建脚本不存在${NC}"
        return 1
    fi
    
    echo -e "${CYAN}运行Bitrise构建脚本...${NC}"
    if chmod +x build_with_bitrise.sh && ./build_with_bitrise.sh; then
        echo -e "${GREEN}✅ Bitrise构建启动成功!${NC}"
        return 0
    else
        echo -e "${RED}❌ Bitrise构建失败${NC}"
        return 1
    fi
}

# 方案4: Termux完整SDK
build_with_termux_sdk() {
    echo -e "${YELLOW}方案4: Termux完整SDK${NC}"
    
    if [ ! -f "TERMUX_SDK_INSTALL.sh" ]; then
        echo -e "${RED}❌ Termux SDK安装脚本不存在${NC}"
        return 1
    fi
    
    echo -e "${CYAN}要在Termux中构建，您需要先运行SDK安装脚本:${NC}"
    echo -e "${CYAN}bash TERMUX_SDK_INSTALL.sh${NC}"
    echo -e "${CYAN}然后运行: ~/build_apk_local.sh${NC}"
    echo -e "${GREEN}✅ Termux SDK安装脚本已准备: TERMUX_SDK_INSTALL.sh${NC}"
    return 0
}

# 方案5: Codespaces/Gitpod等预构建环境
build_with_codespaces() {
    echo -e "${YELLOW}方案5: 预构建环境 (GitHub Codespaces/Gitpod)${NC}"
    
    if [ ! -f ".devcontainer.json" ]; then
        echo -e "${RED}❌ 开发容器配置文件不存在${NC}"
        return 1
    fi
    
    echo -e "${CYAN}在预构建环境中构建:${NC}"
    echo -e "${CYAN}- 在Codespaces/Gitpod中打开此项目${NC}"
    echo -e "${CYAN}- 环境将自动配置${NC}"
    echo -e "${CYAN}- 运行: ./gradlew assembleDebug${NC}"
    echo -e "${GREEN}✅ 开发容器配置已创建: .devcontainer.json${NC}"
    return 0
}

# 主构建函数
main_build() {
    echo -e "${YELLOW}尝试主要构建方式: GitHub Actions${NC}"
    echo -e "${CYAN}推送代码到GitHub以触发构建:${NC}"
    echo -e "${CYAN}git add . && git commit -m \"Trigger build\" && git push${NC}"
    
    # 检查是否已配置GitHub并询问用户是否继续
    if git remote -v | grep -q "origin"; then
        read -p "是否推送以触发GitHub Actions构建? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git add .
            git commit -m "Configure build and trigger GitHub Actions" || echo "No changes to commit"
            git push origin main
            echo -e "${GREEN}✅ GitHub Actions构建已触发${NC}"
            return 0
        fi
    else
        echo -e "${YELLOW}GitHub远程仓库未配置，跳过GitHub Actions${NC}"
    fi
    
    return 1
}

# 执行构建方案
execute_build_fallback() {
    echo -e "${YELLOW}开始执行备用构建方案...${NC}"
    
    # 尝试主要方案
    if main_build; then
        echo -e "${GREEN}🎉 主要构建方案成功!${NC}"
        return 0
    else
        echo -e "${YELLOW}主要方案失败，尝试备用方案...${NC}"
    fi
    
    # 按优先级尝试备用方案
    for i in {1..5}; do
        method_name=${BUILD_METHODS[$i]}
        echo -e "\n${YELLOW}尝试备用方案 $i: $method_name${NC}"
        
        case $method_name in
            "docker")
                if build_with_docker; then
                    echo -e "${GREEN}🎉 Docker构建成功!${NC}"
                    return 0
                fi
                ;;
            "android_studio")
                if build_with_android_studio; then
                    echo -e "${GREEN}🎉 Android Studio说明已提供!${NC}"
                    return 0
                fi
                ;;
            "bitrise")
                if build_with_bitrise; then
                    echo -e "${GREEN}🎉 Bitrise构建启动成功!${NC}"
                    return 0
                fi
                ;;
            "termux_sdk")
                if build_with_termux_sdk; then
                    echo -e "${GREEN}🎉 Termux SDK构建说明已提供!${NC}"
                    return 0
                fi
                ;;
            "codespaces")
                if build_with_codespaces; then
                    echo -e "${GREEN}🎉 预构建环境配置已提供!${NC}"
                    return 0
                fi
                ;;
        esac
        
        echo -e "${YELLOW}方案 $i 失败，尝试下一个...${NC}"
    done
    
    echo -e "${RED}❌ 所有构建方案都失败了${NC}"
    return 1
}

# 显示使用说明
show_usage() {
    echo -e "${CYAN}使用方法:${NC}"
    echo -e "${CYAN}1. 主要方式: 推送代码以触发GitHub Actions${NC}"
    echo -e "${CYAN}2. 备用方式: 如果GitHub Actions失败，使用以下任一方式${NC}"
    echo -e "${CYAN}   - Docker: bash $0 docker${NC}"
    echo -e "${CYAN}   - Android Studio: 查看 ANDROID_STUDIO_IMPORT.md${NC}"
    echo -e "${CYAN}   - Bitrise: 配置并运行 build_with_bitrise.sh${NC}"
    echo -e "${CYAN}   - Termux SDK: bash TERMUX_SDK_INSTALL.sh${NC}"
    echo -e "${CYAN}   - Codespaces: 在GitHub Codespaces中打开项目${NC}"
}

# 主函数
main() {
    if [ "$1" = "docker" ]; then
        build_with_docker
    elif [ "$1" = "help" ] || [ "$1" = "-h" ]; then
        show_usage
    else
        execute_build_fallback
    fi
}

# 运行主函数
main "$@"
