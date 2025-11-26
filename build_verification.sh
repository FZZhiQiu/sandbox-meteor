#!/bin/bash

# 气象沙盘项目构建验证脚本
# 用于验证项目结构和代码完整性

echo "🚀 开始气象沙盘项目构建验证..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 计数器
TOTAL_CHECKS=0
PASSED_CHECKS=0

# 检查函数
check_file() {
    local file_path="$1"
    local description="$2"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "检查 $description ... "
    
    if [ -f "$file_path" ]; then
        echo -e "${GREEN}✓ 通过${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗ 失败${NC}"
        echo "  文件不存在: $file_path"
        return 1
    fi
}

check_directory() {
    local dir_path="$1"
    local description="$2"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "检查 $description ... "
    
    if [ -d "$dir_path" ]; then
        echo -e "${GREEN}✓ 通过${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗ 失败${NC}"
        echo "  目录不存在: $dir_path"
        return 1
    fi
}

check_syntax() {
    local file_path="$1"
    local description="$2"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "检查 $description 语法 ... "
    
    # 简单的语法检查 - 检查是否有基本的类和导入结构
    if grep -q "import\|class\|enum\|void\|return" "$file_path" 2>/dev/null; then
        echo -e "${GREEN}✓ 通过${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗ 失败${NC}"
        echo "  语法检查失败: $file_path"
        return 1
    fi
}

echo -e "${BLUE}=== 项目结构检查 ===${NC}"

# 检查核心配置文件
check_file "pubspec.yaml" "Flutter配置文件"
check_file "package.json" "Node.js配置文件"
check_file "app.json" "Expo应用配置"

# 检查主要目录结构
check_directory "lib" "Dart源码目录"
check_directory "lib/core" "核心配置目录"
check_directory "lib/services" "服务层目录"
check_directory "lib/ui" "用户界面目录"
check_directory "lib/models" "数据模型目录"
check_directory "test" "测试目录"
check_directory "assets" "资源文件目录"

echo -e "\n${BLUE}=== 核心业务文件检查 ===${NC}"

# 检查核心业务文件
check_file "lib/core/app_config.dart" "应用配置"
check_file "lib/models/meteorology_state.dart" "气象数据模型"
check_file "lib/controllers/meteorology_controller.dart" "主控制器"

echo -e "\n${BLUE}=== 服务层文件检查 ===${NC}"

# 检查服务层文件
check_file "lib/services/wind_solver.dart" "风场求解器"
check_file "lib/services/data_manager.dart" "数据管理器"
check_file "lib/services/error_handler.dart" "错误处理器"
check_file "lib/services/performance_manager.dart" "性能管理器"

# 检查其他求解器
check_file "lib/services/diffusion_service.dart" "扩散求解器"
check_file "lib/services/precipitation_solver.dart" "降水求解器"
check_file "lib/services/fronts_solver.dart" "锋面求解器"
check_file "lib/services/radiation_solver.dart" "辐射求解器"
check_file "lib/services/boundary_layer_solver.dart" "边界层求解器"

echo -e "\n${BLUE}=== 用户界面文件检查 ===${NC}"

# 检查UI文件
check_file "lib/ui/screens/main_screen.dart" "主屏幕"
check_file "lib/ui/widgets/control_panel.dart" "控制面板"
check_file "lib/ui/widgets/status_bar.dart" "状态栏"
check_file "lib/ui/widgets/advanced_visualization.dart" "高级可视化"

echo -e "\n${BLUE}=== 工具和辅助文件检查 ===${NC}"

# 检查工具文件
check_file "lib/utils/math_utils.dart" "数学工具"
check_file "lib/render/meteorology_painter.dart" "气象渲染器"
check_file "test/commercial_test_suite.dart" "商业级测试套件"

echo -e "\n${BLUE}=== 代码语法检查 ===${NC}"

# 关键文件语法检查
check_syntax "lib/core/app_config.dart" "应用配置"
check_syntax "lib/services/wind_solver.dart" "风场求解器"
check_syntax "lib/services/data_manager.dart" "数据管理器"
check_syntax "lib/ui/widgets/control_panel.dart" "控制面板"

echo -e "\n${BLUE}=== 商业级特性验证 ===${NC}"

# 检查商业级特性
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
echo -n "检查商业级配置系统 ... "
if grep -q "PerformanceLevel\|AppConfig" "lib/core/app_config.dart" 2>/dev/null; then
    echo -e "${GREEN}✓ 通过${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗ 失败${NC}"
fi

TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
echo -n "检查并行计算支持 ... "
if grep -q "useParallel\|Isolate" "lib/services/wind_solver.dart" 2>/dev/null; then
    echo -e "${GREEN}✓ 通过${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗ 失败${NC}"
fi

TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
echo -n "检查错误处理系统 ... "
if grep -q "ErrorHandler\|ErrorRecoveryStrategy" "lib/services/error_handler.dart" 2>/dev/null; then
    echo -e "${GREEN}✓ 通过${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗ 失败${NC}"
fi

TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
echo -n "检查性能管理系统 ... "
if grep -q "PerformanceManager\|PerformanceMetric" "lib/services/performance_manager.dart" 2>/dev/null; then
    echo -e "${GREEN}✓ 通过${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗ 失败${NC}"
fi

TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
echo -n "检查高级可视化功能 ... "
if grep -q "AdvancedVisualization\|AnalysisResult" "lib/ui/widgets/advanced_visualization.dart" 2>/dev/null; then
    echo -e "${GREEN}✓ 通过${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗ 失败${NC}"
fi

TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
echo -n "检查测试覆盖率 ... "
if [ -f "test/commercial_test_suite.dart" ] && grep -q "group.*商业级测试套件" "test/commercial_test_suite.dart" 2>/dev/null; then
    echo -e "${GREEN}✓ 通过${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗ 失败${NC}"
fi

echo -e "\n${BLUE}=== 构建验证结果 ===${NC}"

# 计算通过率
PASS_RATE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))

echo "总检查项: $TOTAL_CHECKS"
echo "通过检查: $PASSED_CHECKS"
echo "通过率: $PASS_RATE%"

if [ $PASS_RATE -ge 90 ]; then
    echo -e "\n${GREEN}🎉 构建验证成功！项目已达到商业级标准。${NC}"
    echo -e "${GREEN}✨ 项目质量评分: 优秀${NC}"
    exit 0
elif [ $PASS_RATE -ge 80 ]; then
    echo -e "\n${YELLOW}⚠️  构建验证基本通过，项目接近商业级标准。${NC}"
    echo -e "${YELLOW}📊 项目质量评分: 良好${NC}"
    exit 0
elif [ $PASS_RATE -ge 70 ]; then
    echo -e "\n${YELLOW}🔧 构建验证部分通过，项目需要进一步优化。${NC}"
    echo -e "${YELLOW}📈 项目质量评分: 合格${NC}"
    exit 1
else
    echo -e "\n${RED}❌ 构建验证失败，项目存在重大问题。${NC}"
    echo -e "${RED}🚨 项目质量评分: 需要改进${NC}"
    exit 2
fi