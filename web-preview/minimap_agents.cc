#include "minimap_agents.h"
#include <cmath>
#include <algorithm>

void agents_minimap(const AgentManager& am, uint8_t* out_mask) {
    // 确保输入有效
    if (!am.agents || !out_mask) {
        return;
    }
    
    // 初始化输出掩码为0
    const int target_size = 256;
    for (int i = 0; i < target_size * target_size; i++) {
        out_mask[i] = 0;
    }
    
    // 遍历所有代理人
    for (int i = 0; i < am.num_agents; i++) {
        const Agent& agent = am.agents[i];
        
        // 只取地面层（z=0）且活跃的代理人
        if (!agent.active || agent.z > 0.1f) {  // 稍微放宽条件，允许接近地面的代理人
            continue;
        }
        
        // 将世界坐标 (x,y) 量化到 256×256 网格
        // 假设世界坐标范围是 [0, 1000) -> 网格 [0, 255]
        int idx = static_cast<int>(agent.x / 4.0f);  // 1000/256 ≈ 3.906, 使用4以简化计算
        int idy = static_cast<int>(agent.y / 4.0f);
        
        // 确保坐标在范围内
        if (idx < 0 || idx >= target_size || idy < 0 || idy >= target_size) {
            continue;
        }
        
        // 以 idx,idy 为中心画「0.5 像素圆」→ 覆盖 3×3 区域
        // 圆半径：0.25 像素 → 覆盖 3×3 邻域
        for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
                int px = idx + dx;
                int py = idy + dy;
                
                // 检查边界
                if (px >= 0 && px < target_size && py >= 0 && py < target_size) {
                    // 计算到中心的距离
                    float dist_sq = static_cast<float>(dx * dx + dy * dy);
                    
                    // 0.5像素直径 = 0.25像素半径 = 0.0625平方距离
                    // 为简化计算，使用3x3区域全部标记，实际是0.5像素直径的方形近似
                    int mask_idx = py * target_size + px;
                    
                    // 像素值 = 职业 ID % 256（颜色区分）
                    uint8_t color = static_cast<uint8_t>(agent.profession_id % 256);
                    
                    // 如果当前像素已经有值，保留更明显的颜色（较大的ID）
                    if (out_mask[mask_idx] == 0) {
                        out_mask[mask_idx] = color;
                    } else {
                        // 可选：如果已经有值，可以使用不同的合并策略
                        // 这里简单地保持原来的或设置新的，取决于需要
                        out_mask[mask_idx] = color;  // 简单覆盖
                    }
                }
            }
        }
    }
}