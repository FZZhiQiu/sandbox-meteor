#!/usr/bin/env python3
"""
项目模板生成器 启动器
快速创建各种项目模板
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

def main():
    plugin_dir = Path(__file__).parent
    print("🔌 启动插件: 项目模板生成器")
    
    # 模板插件逻辑
    templates_dir = plugin_dir / "templates"
    if templates_dir.exists():
        print("📂 可用模板:")
        templates = list(templates_dir.glob("*"))
        for i, template in enumerate(templates, 1):
            if template.is_dir():
                print(f"  {i}. {template.name}")
        
        if templates:
            try:
                choice = input("\n选择模板编号 (回车跳过): ").strip()
                if choice and choice.isdigit():
                    template_index = int(choice) - 1
                    if 0 <= template_index < len(templates):
                        selected_template = templates[template_index]
                        project_name = input("输入项目名称: ").strip()
                        if project_name:
                            create_project_from_template(selected_template, project_name)
            except (EOFError, KeyboardInterrupt):
                print("\n👋 退出")
    else:
        print("📁 模板目录:", templates_dir)

def create_project_from_template(template_dir, project_name):
    """从模板创建项目"""
    try:
        target_dir = Path.cwd() / project_name
        if target_dir.exists():
            print(f"⚠️  目录已存在: {target_dir}")
            return
        
        print(f"📁 创建项目: {target_dir}")
        shutil.copytree(template_dir, target_dir)
        
        # 更新项目名称相关的文件内容
        for file_path in target_dir.rglob("*"):
            if file_path.is_file():
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # 替换模板占位符
                    content = content.replace("{{PROJECT_NAME}}", project_name)
                    content = content.replace("{{project_name}}", project_name.lower())
                    
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                except Exception:
                    pass  # 跳过二进制文件
        
        print(f"✅ 项目创建成功: {project_name}")
        print(f"📁 位置: {target_dir}")
        
    except Exception as e:
        print(f"❌ 项目创建失败: {e}")

if __name__ == "__main__":
    main()