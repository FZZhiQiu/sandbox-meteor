#!/bin/bash

# 气象数据处理脚本示例

# 检查参数
if [ $# -eq 0 ]; then
    echo "使用方法: $0 <数据文件>"
    exit 1
fi

data_file=$1

# 检查文件是否存在
if [ ! -f "$data_file" ]; then
    echo "错误: 文件 $data_file 不存在"
    exit 1
fi

# 处理气象数据
echo "正在处理气象数据: $data_file"
temp=$(grep "温度" "$data_file" | tail -1 | cut -d',' -f2)
humidity=$(grep "湿度" "$data_file" | tail -1 | cut -d',' -f2)

echo "温度: $temp°C"
echo "湿度: $humidity%"