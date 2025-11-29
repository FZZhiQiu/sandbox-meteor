#!/usr/bin/env python3
"""
开发辅助插件管理器
Author: FZQ团队
Version: 1.0.0
支持插件的下载、安装、配置和管理
"""

import os
import sys
import json
import urllib.request
import urllib.parse
import zipfile
import shutil
import subprocess
from pathlib import Path
from datetime import datetime

class DevPluginManager:
    """开发辅助插件管理器"""
    
    def __init__(self):
        self.version = "1.0.0"
        self.author = "FZQ团队"
        self.plugins_dir = Path("./dev_plugins")
        self.config_file = Path("./dev_plugins/config.json")
        self.plugins_dir.mkdir(exist_ok=True)
        
        # 插件大小限制设置
        self.max_total_size_gb = 2.0  # 2GB总限制
        self.max_total_size_bytes = int(self.max_total_size_gb * 1024 * 1024 * 1024)
        self.warning_threshold = 0.8   # 80%时警告
        
        # 插件仓库配置
        self.plugin_repos = {
            'official': 'https://github.com/FZZhiQiu/dev-plugins',
            'community': 'https://github.com/termux/dev-plugins',
            'custom': []
        }
        
        # 预定义插件列表
        self.available_plugins = {
            'code-formatter': {
                'name': '代码格式化工具',
                'description': '自动格式化Python、JavaScript、Dart等代码',
                'url': 'https://github.com/psf/black',
                'install_type': 'pip',
                'package_name': 'black',
                'category': '开发工具'
            },
            'linter': {
                'name': '代码检查工具',
                'description': '检查代码质量和潜在问题',
                'url': 'https://github.com/pylint-dev/pylint',
                'install_type': 'pip',
                'package_name': 'pylint',
                'category': '开发工具'
            },
            'auto-complete': {
                'name': '自动补全插件',
                'description': '智能代码补全和建议',
                'url': 'https://github.com/deepjoker/vim-code-completion',
                'install_type': 'git',
                'category': '编辑器增强'
            },
            'git-helper': {
                'name': 'Git辅助工具',
                'description': '简化Git操作的辅助脚本',
                'url': 'https://github.com/FZZhiQiu/git-helper',
                'install_type': 'script',
                'category': '版本控制'
            },
            'project-template': {
                'name': '项目模板生成器',
                'description': '快速创建各种项目模板',
                'url': 'https://github.com/FZZhiQiu/project-templates',
                'install_type': 'template',
                'category': '项目管理'
            },
            'meteorology-enhanced': {
                'name': '气象数据增强包',
                'description': '扩展气象数据处理功能',
                'url': 'https://github.com/FZZhiQiu/meteorology-enhanced',
                'install_type': 'package',
                'category': '专业工具'
            },
            'termux-shortcuts': {
                'name': 'Termux快捷键',
                'description': '自定义Termux快捷键和别名',
                'url': 'https://github.com/termux/termux-shortcuts',
                'install_type': 'config',
                'category': '系统优化'
            }
        }
        
        self.load_config()
        self.check_storage_space()
    
    def load_config(self):
        """加载配置文件"""
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r', encoding='utf-8') as f:
                    self.config = json.load(f)
            except Exception as e:
                print(f"❌ 配置文件加载失败: {e}")
                self.config = {}
        else:
            self.config = {
                'installed_plugins': {},
                'plugin_settings': {},
                'last_update': datetime.now().isoformat()
            }
            self.save_config()
    
    def save_config(self):
        """保存配置文件"""
        try:
            with open(self.config_file, 'w', encoding='utf-8') as f:
                json.dump(self.config, f, indent=2, ensure_ascii=False, default=str)
            return True
        except Exception as e:
            print(f"❌ 配置文件保存失败: {e}")
            return False
    
    def get_directory_size(self, directory):
        """获取目录大小"""
        total_size = 0
        try:
            for file_path in directory.rglob('*'):
                if file_path.is_file():
                    total_size += file_path.stat().st_size
        except Exception:
            pass
        return total_size
    
    def get_total_plugins_size(self):
        """获取插件总大小"""
        if not self.plugins_dir.exists():
            return 0
        return self.get_directory_size(self.plugins_dir)
    
    def format_size(self, size_bytes):
        """格式化大小显示"""
        if size_bytes < 1024:
            return f"{size_bytes} B"
        elif size_bytes < 1024 * 1024:
            return f"{size_bytes / 1024:.1f} KB"
        elif size_bytes < 1024 * 1024 * 1024:
            return f"{size_bytes / (1024 * 1024):.1f} MB"
        else:
            return f"{size_bytes / (1024 * 1024 * 1024):.2f} GB"
    
    def check_storage_space(self):
        """检查存储空间"""
        current_size = self.get_total_plugins_size()
        usage_ratio = current_size / self.max_total_size_bytes
        
        print(f"💾 插件存储空间: {self.format_size(current_size)} / {self.format_size(self.max_total_size_bytes)}")
        
        if usage_ratio >= self.warning_threshold:
            print(f"⚠️  存储空间使用率 {usage_ratio*100:.1f}%，接近限制")
        elif usage_ratio >= 0.95:
            print(f"❌ 存储空间即将用尽 ({usage_ratio*100:.1f}%)")
            return False
        
        return True
    
    def check_plugin_size_limit(self, estimated_size_bytes=0):
        """检查插件大小限制"""
        current_size = self.get_total_plugins_size()
        new_total = current_size + estimated_size_bytes
        
        if new_total > self.max_total_size_bytes:
            print(f"❌ 超过大小限制!")
            print(f"   当前: {self.format_size(current_size)}")
            print(f"   预计: {self.format_size(new_total)}")
            print(f"   限制: {self.format_size(self.max_total_size_bytes)}")
            return False
        
        usage_ratio = new_total / self.max_total_size_bytes
        if usage_ratio >= self.warning_threshold:
            print(f"⚠️  安装后将达到 {usage_ratio*100:.1f}% 存储空间")
        
        return True
    
    def list_available_plugins(self):
        """列出可用插件"""
        print("🔌 可用插件列表")
        print("="*50)
        
        # 显示存储空间状态
        current_size = self.get_total_plugins_size()
        usage_ratio = current_size / self.max_total_size_bytes
        print(f"💾 存储使用: {self.format_size(current_size)}/{self.format_size(self.max_total_size_bytes)} ({usage_ratio*100:.1f}%)")
        
        if usage_ratio >= self.warning_threshold:
            print("⚠️  存储空间接近限制!")
        print()
        
        categories = {}
        for plugin_id, plugin_info in self.available_plugins.items():
            category = plugin_info['category']
            if category not in categories:
                categories[category] = []
            categories[category].append((plugin_id, plugin_info))
        
        for category, plugins in categories.items():
            print(f"\n📂 {category}")
            print("-" * 30)
            for plugin_id, plugin_info in plugins:
                status = "✅ 已安装" if plugin_id in self.config['installed_plugins'] else "⬜ 未安装"
                print(f"  {plugin_id}: {plugin_info['name']}")
                print(f"    📝 {plugin_info['description']}")
                print(f"    📦 {plugin_info['install_type']} | {status}")
    
    def install_plugin(self, plugin_id):
        """安装插件"""
        if plugin_id not in self.available_plugins:
            print(f"❌ 插件不存在: {plugin_id}")
            return False
        
        if plugin_id in self.config['installed_plugins']:
            print(f"⚠️  插件已安装: {plugin_id}")
            return True
        
        plugin_info = self.available_plugins[plugin_id]
        print(f"🔌 安装插件: {plugin_info['name']}")
        
        # 检查大小限制（估算100MB）
        estimated_size = 100 * 1024 * 1024  # 100MB默认估算
        if not self.check_plugin_size_limit(estimated_size):
            return False
        
        success = False
        
        if plugin_info['install_type'] == 'pip':
            success = self.install_pip_plugin(plugin_id, plugin_info)
        elif plugin_info['install_type'] == 'git':
            success = self.install_git_plugin(plugin_id, plugin_info)
        elif plugin_info['install_type'] == 'script':
            success = self.install_script_plugin(plugin_id, plugin_info)
        elif plugin_info['install_type'] == 'template':
            success = self.install_template_plugin(plugin_id, plugin_info)
        elif plugin_info['install_type'] == 'package':
            success = self.install_package_plugin(plugin_id, plugin_info)
        elif plugin_info['install_type'] == 'config':
            success = self.install_config_plugin(plugin_id, plugin_info)
        else:
            print(f"❌ 不支持的安装类型: {plugin_info['install_type']}")
            return False
        
        if success:
            self.config['installed_plugins'][plugin_id] = {
                'name': plugin_info['name'],
                'install_time': datetime.now().isoformat(),
                'version': '1.0.0'
            }
            self.save_config()
            print(f"✅ 插件安装成功: {plugin_info['name']}")
        
        return success
    
    def install_pip_plugin(self, plugin_id, plugin_info):
        """安装pip插件"""
        try:
            package_name = plugin_info.get('package_name', plugin_id)
            print(f"📦 通过pip安装: {package_name}")
            
            # 检查包大小（先下载信息）
            try:
                cmd = ['pip', 'show', package_name]
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
                if result.returncode == 0:
                    # 解析包大小信息
                    for line in result.stdout.split('\n'):
                        if line.startswith('Size:'):
                            size_str = line.split(':')[1].strip()
                            if size_str:
                                # 解析大小字符串
                                if 'KB' in size_str:
                                    size_kb = float(size_str.replace('KB', '').strip())
                                    estimated_size = int(size_kb * 1024)
                                elif 'MB' in size_str:
                                    size_mb = float(size_str.replace('MB', '').strip())
                                    estimated_size = int(size_mb * 1024 * 1024)
                                else:
                                    estimated_size = 50 * 1024 * 1024  # 默认50MB
                                
                                if not self.check_plugin_size_limit(estimated_size):
                                    return False
                                break
            except Exception:
                # 如果无法获取大小，使用默认估算
                if not self.check_plugin_size_limit(50 * 1024 * 1024):
                    return False
            
            # 尝试使用国内镜像
            mirrors = [
                'https://pypi.tuna.tsinghua.edu.cn/simple',
                'https://mirrors.aliyun.com/pypi/simple/',
                'https://pypi.douban.com/simple/'
            ]
            
            for mirror in mirrors:
                try:
                    cmd = ['pip', 'install', '-i', mirror, package_name]
                    result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
                    if result.returncode == 0:
                        print(f"✅ 通过镜像安装成功: {mirror}")
                        return True
                except subprocess.TimeoutExpired:
                    print(f"⏰ 镜像超时: {mirror}")
                    continue
                except Exception as e:
                    print(f"❌ 镜像安装失败: {mirror} - {e}")
                    continue
            
            # 尝试官方源
            cmd = ['pip', 'install', package_name]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
            if result.returncode == 0:
                print("✅ 通过官方源安装成功")
                return True
            else:
                print(f"❌ 安装失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ pip安装失败: {e}")
            return False
    
    def install_git_plugin(self, plugin_id, plugin_info):
        """安装git插件"""
        try:
            plugin_dir = self.plugins_dir / plugin_id
            print(f"📥 克隆插件到: {plugin_dir}")
            
            if plugin_dir.exists():
                shutil.rmtree(plugin_dir)
            
            cmd = ['git', 'clone', plugin_info['url'], str(plugin_dir)]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
            
            if result.returncode == 0:
                # 创建启动脚本
                self.create_plugin_launcher(plugin_id, plugin_info, plugin_dir)
                return True
            else:
                print(f"❌ Git克隆失败: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ Git安装失败: {e}")
            return False
    
    def install_script_plugin(self, plugin_id, plugin_info):
        """安装脚本插件"""
        try:
            plugin_dir = self.plugins_dir / plugin_id
            plugin_dir.mkdir(exist_ok=True)
            
            # 下载脚本文件
            script_url = plugin_info['url']
            if script_url.endswith('.py'):
                script_path = plugin_dir / f"{plugin_id}.py"
            else:
                script_path = plugin_dir / f"{plugin_id}.sh"
            
            print(f"📥 下载脚本到: {script_path}")
            
            urllib.request.urlretrieve(script_url, script_path)
            
            # 设置执行权限
            os.chmod(script_path, 0o755)
            
            self.create_plugin_launcher(plugin_id, plugin_info, plugin_dir)
            return True
            
        except Exception as e:
            print(f"❌ 脚本安装失败: {e}")
            return False
    
    def install_template_plugin(self, plugin_id, plugin_info):
        """安装模板插件"""
        try:
            plugin_dir = self.plugins_dir / plugin_id
            plugin_dir.mkdir(exist_ok=True)
            
            # 创建模板目录结构
            templates_dir = plugin_dir / "templates"
            templates_dir.mkdir(exist_ok=True)
            
            # 创建示例模板
            self.create_sample_templates(templates_dir)
            
            self.create_plugin_launcher(plugin_id, plugin_info, plugin_dir)
            return True
            
        except Exception as e:
            print(f"❌ 模板安装失败: {e}")
            return False
    
    def install_package_plugin(self, plugin_id, plugin_info):
        """安装包插件"""
        try:
            plugin_dir = self.plugins_dir / plugin_id
            plugin_dir.mkdir(exist_ok=True)
            
            # 创建包结构
            package_dir = plugin_dir / plugin_id.replace('-', '_')
            package_dir.mkdir(exist_ok=True)
            
            # 创建__init__.py
            init_file = package_dir / "__init__.py"
            with open(init_file, 'w') as f:
                f.write(f'"""\n{plugin_info["name"]}\n{plugin_info["description"]}\n"""\n\n__version__ = "1.0.0"\n')
            
            self.create_plugin_launcher(plugin_id, plugin_info, plugin_dir)
            return True
            
        except Exception as e:
            print(f"❌ 包安装失败: {e}")
            return False
    
    def install_config_plugin(self, plugin_id, plugin_info):
        """安装配置插件"""
        try:
            plugin_dir = self.plugins_dir / plugin_id
            plugin_dir.mkdir(exist_ok=True)
            
            # 创建配置文件
            config_file = plugin_dir / f"{plugin_id}.conf"
            with open(config_file, 'w') as f:
                f.write(f"# {plugin_info['name']} 配置文件\n")
                f.write(f"# {plugin_info['description']}\n\n")
                f.write("# 在这里添加配置选项\n")
            
            self.create_plugin_launcher(plugin_id, plugin_info, plugin_dir)
            return True
            
        except Exception as e:
            print(f"❌ 配置安装失败: {e}")
            return False
    
    def create_plugin_launcher(self, plugin_id, plugin_info, plugin_dir):
        """创建插件启动器"""
        launcher_path = plugin_dir / "run.py"
        
        launcher_content = f'''#!/usr/bin/env python3
"""
{plugin_info['name']} 启动器
{plugin_info['description']}
"""

import os
import sys
import subprocess
from pathlib import Path

def main():
    plugin_dir = Path(__file__).parent
    print("🔌 启动插件: {plugin_info['name']}")
    
    # 根据插件类型执行不同的启动逻辑
    if plugin_info['install_type'] == 'git':
        # Git插件通常有自己的启动脚本
        main_script = plugin_dir / "main.py"
        if main_script.exists():
            subprocess.run([sys.executable, str(main_script)])
        else:
            print("📁 插件目录:", plugin_dir)
            print("💡 请查看插件文档了解使用方法")
    
    elif plugin_info['install_type'] == 'script':
        # 脚本插件
        script_file = plugin_dir / "{plugin_id}.py"
        if script_file.exists():
            subprocess.run([sys.executable, str(script_file)])
        else:
            script_file = plugin_dir / "{plugin_id}.sh"
            if script_file.exists():
                subprocess.run(["bash", str(script_file)])
    
    elif plugin_info['install_type'] == 'template':
        # 模板插件
        templates_dir = plugin_dir / "templates"
        if templates_dir.exists():
            print("📂 可用模板:")
            for template in templates_dir.glob("*"):
                if template.is_file():
                    print(f"  - {{template.name}}")
        else:
            print("📁 模板目录:", templates_dir)
    
    elif plugin_info['install_type'] == 'package':
        # 包插件
        print("📦 包插件已安装，可以在Python中导入使用")
        print(f"💡 import {plugin_id.replace('-', '_')}")
    
    elif plugin_info['install_type'] == 'config':
        # 配置插件
        config_file = plugin_dir / "{plugin_id}.conf"
        if config_file.exists():
            print("⚙️  配置文件:", config_file)
            print("💡 请编辑配置文件以自定义设置")
    
    else:
        print(f"❌ 未知插件类型: {{plugin_info['install_type']}}")

if __name__ == "__main__":
    main()
'''
        
        with open(launcher_path, 'w', encoding='utf-8') as f:
            f.write(launcher_content)
        
        os.chmod(launcher_path, 0o755)
    
    def create_sample_templates(self, templates_dir):
        """创建示例模板"""
        # Python项目模板
        python_template = templates_dir / "python_project"
        python_template.mkdir(exist_ok=True)
        
        with open(python_template / "main.py", 'w') as f:
            f.write('''#!/usr/bin/env python3
"""
Python项目模板
"""

def main():
    print("Hello, World!")

if __name__ == "__main__":
    main()
''')
        
        with open(python_template / "requirements.txt", 'w') as f:
            f.write("# 项目依赖\n")
        
        # Shell脚本模板
        shell_template = templates_dir / "shell_script"
        shell_template.mkdir(exist_ok=True)
        
        with open(shell_template / "script.sh", 'w') as f:
            f.write('''#!/bin/bash
# Shell脚本模板

echo "Hello, World!"
''')
        
        os.chmod(shell_template / "script.sh", 0o755)
    
    def uninstall_plugin(self, plugin_id):
        """卸载插件"""
        if plugin_id not in self.config['installed_plugins']:
            print(f"⚠️  插件未安装: {plugin_id}")
            return False
        
        plugin_info = self.available_plugins.get(plugin_id)
        if not plugin_info:
            print(f"❌ 插件信息不存在: {plugin_id}")
            return False
        
        print(f"🗑️  卸载插件: {plugin_info['name']}")
        
        success = False
        
        if plugin_info['install_type'] == 'pip':
            success = self.uninstall_pip_plugin(plugin_id, plugin_info)
        else:
            # 删除插件目录
            plugin_dir = self.plugins_dir / plugin_id
            if plugin_dir.exists():
                shutil.rmtree(plugin_dir)
                success = True
        
        if success:
            del self.config['installed_plugins'][plugin_id]
            self.save_config()
            print(f"✅ 插件卸载成功: {plugin_info['name']}")
        
        return success
    
    def uninstall_pip_plugin(self, plugin_id, plugin_info):
        """卸载pip插件"""
        try:
            package_name = plugin_info.get('package_name', plugin_id)
            cmd = ['pip', 'uninstall', '-y', package_name]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
            return result.returncode == 0
        except Exception as e:
            print(f"❌ pip卸载失败: {e}")
            return False
    
    def cleanup_storage(self):
        """清理存储空间"""
        print("🧹 清理插件存储空间")
        print("="*30)
        
        current_size = self.get_total_plugins_size()
        print(f"当前存储使用: {self.format_size(current_size)}")
        
        # 清理临时文件
        temp_dirs = []
        for item in self.plugins_dir.iterdir():
            if item.is_dir():
                # 检查是否是未完成安装的目录
                if not (item / "run.py").exists():
                    temp_dirs.append(item)
        
        if temp_dirs:
            print(f"🗑️  发现 {len(temp_dirs)} 个临时目录")
            for temp_dir in temp_dirs:
                try:
                    shutil.rmtree(temp_dir)
                    print(f"✅ 删除: {temp_dir.name}")
                except Exception as e:
                    print(f"❌ 删除失败: {temp_dir.name} - {e}")
        
        # 重新计算大小
        new_size = self.get_total_plugins_size()
        freed_space = current_size - new_size
        
        print(f"🧹 清理完成")
        print(f"释放空间: {self.format_size(freed_space)}")
        print(f"当前使用: {self.format_size(new_size)}")
    
    def run_plugin(self, plugin_id):
        """运行插件"""
        if plugin_id not in self.config['installed_plugins']:
            print(f"❌ 插件未安装: {plugin_id}")
            return False
        
        plugin_dir = self.plugins_dir / plugin_id
        launcher = plugin_dir / "run.py"
        
        if launcher.exists():
            try:
                subprocess.run([sys.executable, str(launcher)])
                return True
            except Exception as e:
                print(f"❌ 插件运行失败: {e}")
                return False
        else:
            print(f"❌ 插件启动器不存在: {launcher}")
            return False
    
    def update_plugins(self):
        """更新插件"""
        print("🔄 更新插件...")
        
        for plugin_id in list(self.config['installed_plugins'].keys()):
            if plugin_id in self.available_plugins:
                print(f"🔄 更新插件: {plugin_id}")
                self.uninstall_plugin(plugin_id)
                self.install_plugin(plugin_id)
            else:
                print(f"⚠️  插件已从列表中移除: {plugin_id}")
                self.uninstall_plugin(plugin_id)
        
        print("✅ 插件更新完成")
    
    def show_plugin_info(self, plugin_id):
        """显示插件信息"""
        if plugin_id not in self.available_plugins:
            print(f"❌ 插件不存在: {plugin_id}")
            return
        
        plugin_info = self.available_plugins[plugin_id]
        installed = plugin_id in self.config['installed_plugins']
        
        print(f"🔌 插件信息: {plugin_info['name']}")
        print("="*40)
        print(f"📝 描述: {plugin_info['description']}")
        print(f"🌐 URL: {plugin_info['url']}")
        print(f"📦 类型: {plugin_info['install_type']}")
        print(f"📂 分类: {plugin_info['category']}")
        print(f"📊 状态: {'✅ 已安装' if installed else '⬜ 未安装'}")
        
        if installed:
            install_info = self.config['installed_plugins'][plugin_id]
            print(f"📅 安装时间: {install_info['install_time']}")
            print(f"🔢 版本: {install_info['version']}")

def main():
    """主函数"""
    manager = DevPluginManager()
    
    print("🔌 开发辅助插件管理器")
    print(f"版本: {manager.version}")
    print(f"作者: {manager.author}")
    print("="*50)
    
    if len(sys.argv) < 2:
        print("📋 可用命令:")
        print("  list                    - 列出可用插件")
        print("  install <plugin_id>     - 安装插件")
        print("  uninstall <plugin_id>   - 卸载插件")
        print("  run <plugin_id>         - 运行插件")
        print("  info <plugin_id>        - 显示插件信息")
        print("  update                  - 更新所有插件")
        print("  status                  - 显示安装状态")
        print("  cleanup                 - 清理存储空间")
        print("  storage                 - 显示存储状态")
        return
    
    command = sys.argv[1]
    
    if command == "list":
        manager.list_available_plugins()
    elif command == "install" and len(sys.argv) > 2:
        manager.install_plugin(sys.argv[2])
    elif command == "uninstall" and len(sys.argv) > 2:
        manager.uninstall_plugin(sys.argv[2])
    elif command == "run" and len(sys.argv) > 2:
        manager.run_plugin(sys.argv[2])
    elif command == "info" and len(sys.argv) > 2:
        manager.show_plugin_info(sys.argv[2])
    elif command == "update":
        manager.update_plugins()
    elif command == "status":
        print("📊 插件安装状态")
        print("="*30)
        for plugin_id, info in manager.config['installed_plugins'].items():
            print(f"✅ {plugin_id}: {info['name']}")
    elif command == "cleanup":
        manager.cleanup_storage()
    elif command == "storage":
        manager.check_storage_space()
    else:
        print("❌ 无效命令或缺少参数")

if __name__ == "__main__":
    main()