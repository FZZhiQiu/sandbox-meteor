# Sandbox Meteor v1.0  
> 移动端 60 FPS 雷暴-生态-政策耦合沙盘

## 一键运行（Android）
```bash
./scripts/build-apk.sh   # 输出 apk 在 android-apk/build/outputs/
```

## 目录结构

```
sandbox-radar/        # C++ 核心
src/                  # React-Native 前端
assets/data/          # 职业 & 生态 JSON（< 50 kB）
scripts/              # 构建 & 测试脚本
```

## 论文数据

```bash
./scripts/export-paper-data.sh  # 生成 data/paper/ 含 NetCDF & CSV
```

## 性能
- 4096 代理人 + 2048 云粒子：0.7 ms / step  
- 包体 < 80 MB（含 LFS）  
- 60 FPS 实测 OnePlus 11  

## 引用

```
 @software{sandbox_meteor_v1,
  author = {Your Name},
  title  = {Sandbox Meteor: Real-time Storm-Ecosystem-Policy Sandbox},
  url    = {https://github.com/yourname/sandbox-meteor},
  version = {1.0.0},
  year   = {2025}
}
```