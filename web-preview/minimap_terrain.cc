#include "minimap_terrain.h"
#include <cmath>
#include <algorithm>

void terrain_minimap(const Grid3D& grid, uint8_t* out_terrain) {
    // 确保输入有效
    if (!grid.data || !out_terrain) {
        return;
    }
    
    // 目标尺寸 256x256
    const int target_size = 256;
    
    // 计算从原始网格到目标尺寸的采样步长
    const int step_x = std::max(1, grid.nx / target_size);
    const int step_y = std::max(1, grid.ny / target_size);
    
    // 假设地形数据在 z=0 层
    const int k = 0; // 地形层索引
    
    // 遏历目标网格
    for (int ty = 0; ty < target_size; ty++) {
        for (int tx = 0; tx < target_size; tx++) {
            // 在原始网格中的对应位置
            int gx = tx * step_x;
            int gy = ty * step_y;
            
            // 确保不越界
            gx = std::min(gx, grid.nx - 1);
            gy = std::min(gy, grid.ny - 1);
            
            // 计算原始网格中的索引
            int idx = (k * grid.nx * grid.ny) + (gy * grid.nx) + gx;
            
            // 检查索引是否有效
            if (idx >= grid.nx * grid.ny * grid.nz) {
                continue;
            }
            
            // 获取地形值（假设 1=陆地，0=海洋）
            float terrain_val = grid.data[idx];
            
            // 陆地：固定浅绿 #8FBC8F (143)，海洋：固定浅蓝 #87CEEB (135)
            uint8_t terrain_color = (terrain_val > 0.5f) ? 143 : 135;  // 用143代表陆地，135代表海洋
            
            // 存储到输出层
            int output_idx = ty * target_size + tx;
            out_terrain[output_idx] = terrain_color;
        }
    }
}