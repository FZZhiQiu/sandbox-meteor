#!/bin/bash
# 气象监控脚本 - 使用 ShellCheck 验证

set -e

# 配置
API_URL="http://localhost:3000/weather"
DB_PATH="meteorological_data.db"
LOG_FILE="meteo_monitor.log"
ALERT_THRESHOLD_TEMP=35
ALERT_THRESHOLD_HUMID=80

# 日志函数
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 检查 API 状态
check_api_status() {
    log_message "🔍 检查 API 状态..."
    
    if curl -s "$API_URL" > /dev/null; then
        log_message "✅ API 服务正常"
        return 0
    else
        log_message "❌ API 服务异常"
        return 1
    fi
}

# 获取气象数据
get_weather_data() {
    log_message "📡 获取气象数据..."
    
    local data
    data=$(curl -s "$API_URL" | jq -c '.')
    
    if [[ -n "$data" ]]; then
        # 提取数值，避免 bc 计算问题
        local temp=$(echo "$data" | jq -r '.temperature')
        local humidity=$(echo "$data" | jq -r '.humidity')
        local pressure=$(echo "$data" | jq -r '.pressure')
        local wind=$(echo "$data" | jq -r '.windSpeed')
        local time=$(echo "$data" | jq -r '.timestamp')
        
        echo "temp=$temp humidity=$humidity pressure=$pressure wind=$wind time=$time"
        return 0
    else
        log_message "❌ 获取数据失败"
        return 1
    fi
}

# 检查气象警报
check_weather_alerts() {
    local temp="$1"
    local humidity="$2"
    
    log_message "⚠️  检查气象警报..."
    
    # 使用 gawk 进行数值比较
    if gawk "BEGIN {exit ($temp > $ALERT_THRESHOLD_TEMP)}" <<< "$temp" > /dev/null; then
        log_message "🔥 高温警报: ${temp}°C (阈值: ${ALERT_THRESHOLD_TEMP}°C)"
    fi
    
    if gawk "BEGIN {exit ($humidity > $ALERT_THRESHOLD_HUMID)}" <<< "$humidity" > /dev/null; then
        log_message "💧 高湿警报: ${humidity}% (阈值: ${ALERT_THRESHOLD_HUMID}%)"
    fi
    
    if gawk "BEGIN {exit ($temp < 10)}" <<< "$temp" > /dev/null; then
        log_message "❄️ 低温警报: ${temp}°C"
    fi
}

# 数据库查询
query_database() {
    log_message "🗄️ 查询数据库统计..."
    
    sqlite3 "$DB_PATH" "
        SELECT 
            COUNT(*) as total,
            ROUND(AVG(temperature), 2) as avg_temp,
            ROUND(MIN(temperature), 2) as min_temp,
            ROUND(MAX(temperature), 2) as max_temp,
            ROUND(AVG(humidity), 2) as avg_humidity
        FROM weather_data 
        WHERE timestamp > datetime('now', '-1 hour')
    " 2>/dev/null | while IFS='|' read -r total avg_temp min_temp max_temp avg_humidity; do
        if [[ -n "$total" ]]; then
            log_message "📊 过去1小时统计: $total 条记录"
            log_message "🌡️ 温度: 平均 ${avg_temp}°C, 范围 ${min_temp}°C - ${max_temp}°C"
            log_message "💧 湿度: 平均 ${avg_humidity}%"
        fi
    done
}

# 系统资源监控
check_system_resources() {
    log_message "💻 检查系统资源..."
    
    # CPU 和内存使用情况
    local cpu_usage mem_usage
    cpu_usage=$(top -bn1 | grep "CPU:" | awk '{print $2}' | sed 's/%//')
    mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100}')
    
    log_message "🖥️  CPU 使用率: ${cpu_usage}%"
    log_message "💾 内存使用率: ${mem_usage}%"
    
    # PM2 进程状态
    if pm2 list | grep -q "meteo-server.*online"; then
        log_message "🚀 气象服务器运行正常"
    else
        log_message "⚠️  气象服务器状态异常"
    fi
}

# 主监控循环
main() {
    log_message "🌤️ 气象监控系统启动"
    
    while true; do
        log_message "=================================="
        
        # 检查 API 状态
        if ! check_api_status; then
            sleep 30
            continue
        fi
        
        # 获取和处理数据
        local weather_data
        weather_data=$(get_weather_data)
        
        if [[ $? -eq 0 ]]; then
            # 解析数据
            eval "$weather_data"
            
            # 检查警报
            check_weather_alerts "$temp" "$humidity"
            
            # 查询数据库
            query_database
        fi
        
        # 检查系统资源
        check_system_resources
        
        log_message "💤 下次检查: 5分钟后"
        sleep 300  # 5分钟间隔
    done
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi