#include "minimap_eco_qv.h"
#include <cmath>
#include <algorithm>

void eco_qv_minimap(const EcoState& eco, uint8_t* out_qv) {
    // 确保输入有效
    if (!eco.state || !out_qv || eco.size < 64) {
        return;
    }
    
    // 目标尺寸 256x256
    const int target_size = 256;
    
    // 公式：qv_gen = max(0, EcoState[17]*0.01 - EcoState[7]*0.005) [g/kg/s]
    // 注意：由于EcoState是64维向量，我们使用EcoState[17]和EcoState[7]的值
    double base_qv_gen = std::max(0.0, eco.state[17] * 0.01 - eco.state[7] * 0.005);
    
    // 对于每个像素，应用相同的水汽生成率（在实际应用中，可能会根据位置调整）
    for (int i = 0; i < target_size * target_size; i++) {
        // 应用一些随机性来模拟空间变化
        double local_qv_gen = base_qv_gen * (0.8 + 0.4 * (static_cast<double>(i % 100) / 100.0));
        
        // 对数压缩：val = log10(qv_gen + 1e-6) * 50；clip 0-255
        double log_val = std::log10(local_qv_gen + 1e-6) * 50.0;
        uint8_t qv_quantized = static_cast<uint8_t>(std::max(0.0, std::min(255.0, log_val + 128.0)));
        
        out_qv[i] = qv_quantized;
    }
}