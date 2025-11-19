#include "minimap_core.h"
#include <cstdint>

// Emscripten 占位宏，允许在没有 Emscripten 的情况下编译
#ifndef EMSCRIPTEN
#define EMSCRIPTEN_KEEPALIVE
#else
#include <emscripten.h>
#endif

extern "C" {
    // 暴露给 JavaScript 的函数
    EMSCRIPTEN_KEEPALIVE
    void minimap_update_wrapper(
        float* grid_data, 
        int nx, int ny, int nz,
        uint8_t* layer_qc, 
        uint8_t* layer_qr, 
        uint8_t* layer_lt, 
        uint8_t* layer_qv
    ) {
        // 创建 Grid3D 对象
        Grid3D grid(grid_data, nx, ny, nz);
        
        // 调用核心更新函数
        minimap_update(grid, layer_qc, layer_qr, layer_lt, layer_qv);
    }
    
    // 为 JavaScript 提供直接的内存地址操作
    EMSCRIPTEN_KEEPALIVE
    void call_minimap_update(
        float* grid_ptr,
        uint8_t* layer_qc_ptr,
        uint8_t* layer_qr_ptr,
        uint8_t* layer_lt_ptr,
        uint8_t* layer_qv_ptr
    ) {
        // 假设网格是 1000x1000x50 (标准气象网格尺寸)
        // 但只使用前 256x256x1 部分
        Grid3D grid(grid_ptr, 1000, 1000, 50); 
        
        // 调用核心更新函数
        minimap_update(grid, layer_qc_ptr, layer_qr_ptr, layer_lt_ptr, layer_qv_ptr);
    }
}