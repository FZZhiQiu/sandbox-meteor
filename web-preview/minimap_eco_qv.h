#ifndef MINIMAP_ECO_QV_H
#define MINIMAP_ECO_QV_H

#include <cstdint>

// EcoState 模拟结构 (简化版，用于接口定义)
struct EcoState {
    double* state;      // 生态状态向量
    int size;           // 向量大小
    
    EcoState() : state(nullptr), size(0) {}
    EcoState(double* s, int sz) : state(s), size(sz) {}
};

// 核心函数：更新生态水汽 MiniMap 数据
void eco_qv_minimap(const EcoState& eco, uint8_t* out_qv);

#endif // MINIMAP_ECO_QV_H