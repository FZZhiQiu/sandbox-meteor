#include "field_lerp.h"

#include <cstring>
#include <algorithm>

namespace sandbox_radar {

FieldLerp::FieldLerp() {
  // Constructor implementation
}

FieldLerp::~FieldLerp() {
  // Destructor implementation
}

void FieldLerp::InterpolateField(const float* field0, const float* field1, float* output, 
                                int nx, int ny, int nz, float alpha) {
  // Clamp alpha to [0, 1]
  float clamped_alpha = std::max(0.0f, std::min(1.0f, alpha));
  
  int total_points = nx * ny * nz;
  
  // Perform linear interpolation for each point in the field
  for (int i = 0; i < total_points; ++i) {
    output[i] = field0[i] + clamped_alpha * (field1[i] - field0[i]);
  }
}

void FieldLerp::InterpolateGrid(const float* grid0, const float* grid1, float* output_grid,
                               int nx, int ny, int nz, int nvars, float alpha) {
  // Clamp alpha to [0, 1]
  float clamped_alpha = std::max(0.0f, std::min(1.0f, alpha));
  
  int total_points_per_var = nx * ny * nz;
  int total_points = nvars * total_points_per_var;
  
  // Perform linear interpolation for each variable in the grid
  for (int var = 0; var < nvars; ++var) {
    const float* var0 = &grid0[var * total_points_per_var];
    const float* var1 = &grid1[var * total_points_per_var];
    float* out_var = &output_grid[var * total_points_per_var];
    
    for (int i = 0; i < total_points_per_var; ++i) {
      out_var[i] = var0[i] + clamped_alpha * (var1[i] - var0[i]);
    }
  }
}

void FieldLerp::ComputeInterpolationOnGPU(const float* grid0, const float* grid1, 
                                         float* output_grid, float alpha) {
  // In a real implementation, this would submit a compute shader to GPU
  // For now, we'll call the CPU version as a placeholder
  InterpolateGrid(grid0, grid1, output_grid, 
                  Grid::NX, Grid::NY, Grid::NZ, Grid::NVARS, alpha);
}

}  // namespace sandbox_radar