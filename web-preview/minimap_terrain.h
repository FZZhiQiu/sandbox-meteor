#ifndef MINIMAP_TERRAIN_H
#define MINIMAP_TERRAIN_H

#include <cstdint>

// Grid3D 模拟结构 (简化版，用于接口定义)
struct Grid3D {
    float* data;      // 3D 数据指针
    int nx, ny, nz;   // 网格尺寸
    float dx, dy, dz; // 网格间距
    
    Grid3D() : data(nullptr), nx(0), ny(0), nz(0), dx(1.0f), dy(1.0f), dz(1.0f) {}
    Grid3D(float* d, int x, int y, int z) : data(d), nx(x), ny(y), nz(z), dx(1.0f), dy(1.0f), dz(1.0f) {}
};

// 核心函数：更新地形 MiniMap 数据
void terrain_minimap(const Grid3D& grid, uint8_t* out_terrain);

#endif // MINIMAP_TERRAIN_H