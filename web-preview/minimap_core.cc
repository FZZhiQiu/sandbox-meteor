#include "minimap_core.h"
#include <cmath>
#include <algorithm>

void minimap_update(const Grid3D& grid, uint8_t* layer_qc, uint8_t* layer_qr, uint8_t* layer_lt, uint8_t* layer_qv) {
    // 确保输入有效
    if (!grid.data || !layer_qc || !layer_qr || !layer_lt || !layer_qv) {
        return;
    }
    
    // 目标尺寸 256x256
    const int target_size = 256;
    
    // 计算从原始网格到目标尺寸的采样步长
    const int step_x = std::max(1, grid.nx / target_size);
    const int step_y = std::max(1, grid.ny / target_size);
    
    // 假设 z=0 为最低云水层
    const int k = 0; // 最低云水层索引
    
    // 遍历目标网格
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
            
            // 获取四个物理量：假设它们是连续存储的（qc, qr, lt, qv）
            // 在实际应用中，这四个量可能是分开的网格
            float qc_val = grid.data[idx];                     // 云水
            float qr_val = grid.data[idx + grid.nx*grid.ny];   // 雨水
            float lt_val = grid.data[idx + 2*grid.nx*grid.ny]; // 闪电
            float qv_val = grid.data[idx + 3*grid.nx*grid.ny]; // 水汽
            
            // 对数压缩 + 量化到 0-255
            // qc: 云水 (对数压缩)
            float qc_log = std::log10(std::abs(qc_val) + 1e-6f) * 50.0f;
            uint8_t qc_quantized = static_cast<uint8_t>(std::max(0.0f, std::min(255.0f, qc_log + 128.0f)));
            
            // qr: 雨水 (对数压缩)
            float qr_log = std::log10(std::abs(qr_val) + 1e-6f) * 50.0f;
            uint8_t qr_quantized = static_cast<uint8_t>(std::max(0.0f, std::min(255.0f, qr_log + 128.0f)));
            
            // lt: 闪电密度 (4x4x1 盒子的计数)
            float lt_count = 0.0f;
            for (int dz = 0; dz < 1 && k < grid.nz; dz++) {
                for (int dy = 0; dy < 4 && gy + dy < grid.ny; dy++) {
                    for (int dx = 0; dx < 4 && gx + dx < grid.nx; dx++) {
                        int lightning_idx = ((k + dz) * grid.nx * grid.ny) + ((gy + dy) * grid.nx) + (gx + dx);
                        if (lightning_idx < grid.nx * grid.ny * grid.nz) {
                            lt_count += std::max(0.0f, grid.data[lightning_idx]);
                        }
                    }
                }
            }
            float lt_log = std::log10(lt_count + 1.0f) * 30.0f;
            uint8_t lt_quantized = static_cast<uint8_t>(std::max(0.0f, std::min(255.0f, lt_log)));
            
            // qv: 水汽 (对数压缩)
            float qv_log = std::log10(std::abs(qv_val) + 1e-6f) * 50.0f;
            uint8_t qv_quantized = static_cast<uint8_t>(std::max(0.0f, std::min(255.0f, qv_log + 128.0f)));
            
            // 存储到输出层
            int output_idx = ty * target_size + tx;
            layer_qc[output_idx] = qc_quantized;
            layer_qr[output_idx] = qr_quantized;
            layer_lt[output_idx] = lt_quantized;
            layer_qv[output_idx] = qv_quantized;
        }
    }
}