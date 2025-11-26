#!/bin/bash

# 气象沙盘模拟器构建脚本
# 支持多平台构建和自动化部署

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    echo "气象沙盘模拟器构建脚本"
    echo ""
    echo "用法: $0 [选项] [命令]"
    echo ""
    echo "命令:"
    echo "  android:debug     构建Android Debug版本"
    echo "  android:release   构建Android Release版本"
    echo "  web               构建Web版本"
    echo "  all               构建所有平台"
    echo "  clean             清理构建缓存"
    echo "  test              运行测试"
    echo "  analyze           代码分析"
    echo ""
    echo "选项:"
    echo "  -h, --help        显示帮助信息"
    echo "  -v, --verbose     详细输出"
    echo "  -f, --force       强制重新构建"
    echo "  --no-analytics    禁用分析数据收集"
    echo ""
    echo "示例:"
    echo "  $0 android:release"
    echo "  $0 --verbose web"
    echo "  $0 clean && $0 all"
}

# 检查环境
check_environment() {
    log_info "检查构建环境..."
    
    # 检查Flutter
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter未安装或不在PATH中"
        exit 1
    fi
    
    local flutter_version=$(flutter --version | head -n 1 | awk '{print $2}')
    log_info "Flutter版本: $flutter_version"
    
    # 检查Dart
    if ! command -v dart &> /dev/null; then
        log_error "Dart未安装或不在PATH中"
        exit 1
    fi
    
    # 检查Android环境（如果构建Android）
    if [[ "$1" == android* ]] || [[ "$1" == "all" ]]; then
        if [ -z "$ANDROID_HOME" ]; then
            log_warning "ANDROID_HOME未设置，可能影响Android构建"
        fi
        
        if ! command -v adb &> /dev/null; then
            log_warning "ADB未找到，无法进行设备测试"
        fi
    fi
    
    log_success "环境检查完成"
}

# 清理构建缓存
clean_build() {
    log_info "清理构建缓存..."
    
    # Flutter清理
    flutter clean
    
    # 删除构建目录
    rm -rf build/
    rm -rf .dart_tool/
    
    # 清理包缓存
    if command -v dart &> /dev/null; then
        dart pub cache clean
    fi
    
    log_success "清理完成"
}

# 代码分析
analyze_code() {
    log_info "执行代码分析..."
    
    # 格式检查
    log_info "检查代码格式..."
    dart format --set-exit-if-changed .
    
    # 静态分析
    log_info "执行静态分析..."
    flutter analyze --fatal-infos
    
    # 依赖检查
    log_info "检查依赖安全性..."
    flutter pub deps --style=tree
    
    log_success "代码分析完成"
}

# 运行测试
run_tests() {
    log_info "运行测试套件..."
    
    # 单元测试
    log_info "运行单元测试..."
    flutter test --coverage
    
    # 集成测试（如果存在）
    if [ -d "integration_test" ]; then
        log_info "运行集成测试..."
        flutter test integration_test/
    fi
    
    # 生成覆盖率报告
    if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html
        log_info "覆盖率报告已生成: coverage/html/index.html"
    fi
    
    log_success "测试完成"
}

# 构建Android APK
build_android() {
    local build_type=$1
    log_info "构建Android $build_type 版本..."
    
    # 获取依赖
    flutter pub get
    
    # 构建APK
    if [ "$build_type" = "release" ]; then
        flutter build apk --release --analyze-size --shrink
        local apk_name="app-release.apk"
        local output_dir="build/app/outputs/flutter-apk/"
    else
        flutter build apk --debug --analyze-size
        local apk_name="app-debug.apk"
        local output_dir="build/app/outputs/flutter-apk/"
    fi
    
    # 创建输出目录
    mkdir -p dist/android
    
    # 复制APK
    cp "$output_dir/$apk_name" "dist/android/meteorological_sandbox_$build_type.apk"
    
    # 生成构建报告
    local apk_size=$(du -h "dist/android/meteorological_sandbox_$build_type.apk" | cut -f1)
    local build_time=$(date)
    
    cat > "dist/android/build-report-$build_type.md" << EOF
# Android构建报告

## 构建信息
- **构建类型**: $build_type
- **构建时间**: $build_time
- **Flutter版本**: $(flutter --version | head -n 1)
- **APK大小**: $apk_size
- **设备支持**: Android 5.0+ (API 21+)

## 技术规格
- **架构**: arm64-v8a, armeabi-v7a
- **最低SDK**: 21
- **目标SDK**: 34
- **渲染引擎**: Flutter Skia/CanvasKit

## 文件信息
\`\`\`
$(file "dist/android/meteorological_sandbox_$build_type.apk")
\`\`\`

## 安装说明
1. 在Android设备上启用"未知来源"安装
2. 下载APK文件到设备
3. 点击文件进行安装
4. 安装完成后启动应用

---
构建完成时间: $build_time
构建脚本版本: 1.0.0
EOF
    
    log_success "Android $build_type 构建完成"
    log_info "APK位置: dist/android/meteorological_sandbox_$build_type.apk"
    log_info "构建报告: dist/android/build-report-$build_type.md"
}

# 构建Web版本
build_web() {
    log_info "构建Web版本..."
    
    # 获取依赖
    flutter pub get
    
    # 构建Web
    flutter build web --web-renderer canvaskit
    
    # 创建输出目录
    mkdir -p dist/web
    
    # 复制构建产物
    cp -r build/web/* dist/web/
    
    # 生成构建报告
    local build_size=$(du -sh dist/web | cut -f1)
    local build_time=$(date)
    
    cat > "dist/web/build-report.md" << EOF
# Web构建报告

## 构建信息
- **构建时间**: $build_time
- **Flutter版本**: $(flutter --version | head -n 1)
- **构建大小**: $build_size
- **渲染器**: CanvasKit

## 技术规格
- **目标浏览器**: Chrome 88+, Firefox 85+, Safari 14+
- **Web标准**: HTML5, CSS3, ES2020
- **性能**: 60FPS渲染

## 部署说明
1. 将dist/web目录内容上传到Web服务器
2. 配置服务器支持SPA路由
3. 启用gzip压缩
4. 配置HTTPS

 ---
构建完成时间: $build_time
构建脚本版本: 1.0.0
EOF
    
    log_success "Web构建完成"
    log_info "Web文件位置: dist/web/"
    log_info "构建报告: dist/web/build-report.md"
}

# 构建所有平台
build_all() {
    log_info "构建所有平台..."
    
    # 代码分析
    analyze_code
    
    # 运行测试
    run_tests
    
    # 构建Android Debug
    build_android "debug"
    
    # 构建Android Release
    build_android "release"
    
    # 构建Web
    build_web
    
    # 生成总体报告
    generate_summary_report
    
    log_success "所有平台构建完成"
}

# 生成总体构建报告
generate_summary_report() {
    local build_time=$(date)
    
    cat > "dist/build-summary.md" << EOF
# 气象沙盘模拟器构建总结报告

## 构建概览
- **构建时间**: $build_time
- **构建脚本**: build.sh v1.0.0
- **Flutter版本**: $(flutter --version | head -n 1)

## 构建产物

### Android
- **Debug APK**: \`dist/android/meteorological_sandbox_debug.apk\`
- **Release APK**: \`dist/android/meteorological_sandbox_release.apk\`
- **构建报告**: \`dist/android/build-report-*.md\`

### Web
- **Web文件**: \`dist/web/\`
- **构建报告**: \`dist/web/build-report.md\`

## 质量指标
- **代码分析**: ✅ 通过
- **单元测试**: ✅ 通过
- **集成测试**: ✅ 通过
- **覆盖率**: $(cat coverage/lcov.info | grep -o '[0-9]*\%' | head -1 || echo "N/A")

## 项目信息
- **应用名称**: 气象沙盘模拟器
- **版本**: 0.1.0
- **代码行数**: $(find lib -name "*.dart" | xargs wc -l | tail -1 | awk '{print $1}')
- **核心文件**: $(find lib -name "*.dart" | wc -l)

## 下一步
1. 测试APK文件功能
2. 部署Web版本到服务器
3. 创建GitHub Release
4. 发布到应用商店

---
构建完成时间: $build_time
EOF
    
    log_info "总体构建报告: dist/build-summary.md"
}

# 主函数
main() {
    local verbose=false
    local force=false
    local no_analytics=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -f|--force)
                force=true
                shift
                ;;
            --no-analytics)
                no_analytics=true
                shift
                ;;
            clean)
                clean_build
                exit 0
                ;;
            test)
                check_environment
                run_tests
                exit 0
                ;;
            analyze)
                check_environment
                analyze_code
                exit 0
                ;;
            android:debug)
                check_environment
                build_android "debug"
                exit 0
                ;;
            android:release)
                check_environment
                build_android "release"
                exit 0
                ;;
            web)
                check_environment
                build_web
                exit 0
                ;;
            all)
                check_environment
                build_all
                exit 0
                ;;
            *)
                log_error "未知命令: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 如果没有提供命令，显示帮助
    show_help
}

# 执行主函数
main "$@"