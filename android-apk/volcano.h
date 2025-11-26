#ifndef SANDBOX_RADAR_LIB_VOLCANO_H_
#define SANDBOX_RADAR_LIB_VOLCANO_H_

#include "lib/grid.h"
#include "lib/chemistry.h"

#include <vector>
#include <string>

namespace sandbox_radar {

// 火山喷发点结构
struct Volcano {
  std::string name;
  float latitude;    // 纬度
  float longitude;   // 经度
  float elevation;   // 海拔高度 (m)
  float so2_emission_rate;  // SO₂排放率 (kg/s)
  float ash_emission_rate; // 火山灰排放率 (kg/s)
  bool is_active;    // 是否活跃
  int grid_x, grid_y, grid_z; // 网格坐标
};

// 火山模块类
class VolcanoModule {
 public:
  VolcanoModule();
  ~VolcanoModule();

  // 初始化火山模块
  void Initialize(int nx, int ny, int nz);

  // 更新火山活动
  void Update(float dt, Chemistry& chemistry, float* temperature, float* pressure);

  // 添加火山
  void AddVolcano(const std::string& name, float lat, float lon, float elevation,
                  float so2_rate, float ash_rate);

  // 激活火山喷发
  void ActivateEruption(const std::string& name, float duration, float intensity);

  // 计算SO₂输送
  void ComputeSO2Transport(float dt, const float* wind_u, const float* wind_v, 
                          const float* wind_w, const float* temperature, 
                          const float* pressure);

  // 计算火山灰输送
  void ComputeAshTransport(float dt, const float* wind_u, const float* wind_v, 
                          const float* wind_w, const float* temperature, 
                          const float* pressure);

  // 计算气溶胶光学特性
  void ComputeAerosolOptics();

  // 获取火山列表
  const std::vector<Volcano>& GetVolcanoes() const { return volcanoes_; }

  // 获取SO₂浓度
  const std::vector<float>& GetSO2Concentration() const { return so2_concentration_; }

  // 获取火山灰浓度
  const std::vector<float>& GetAshConcentration() const { return ash_concentration_; }

  // 获取气溶胶光学厚度
  const std::vector<float>& GetAerosolOpticalDepth() const { return aerosol_optical_depth_; }

 private:
  // 火山列表
  std::vector<Volcano> volcanoes_;

  // 火山物质浓度场 (3D)
  std::vector<float> so2_concentration_;
  std::vector<float> ash_concentration_;
  std::vector<float> aerosol_optical_depth_;

  // 网格尺寸
  int nx_, ny_, nz_;

  // 物理参数
  static constexpr float SO2_MOLAR_MASS = 64.066f;        // g/mol
  static constexpr float SO2_DIFFUSION = 0.12f;           // m²/s
  static constexpr float ASH_DIFFUSION = 0.05f;           // m²/s
  static constexpr float ASH_DENSITY = 2650.0f;           // kg/m³ (典型火山灰密度)
  static constexpr float SO2_LIFETIME = 7.0f;             // 天 (SO₂在大气中的寿命)

  // 喷发参数
  float current_eruption_time_;
  std::string active_volcano_name_;
};

}  // namespace sandbox_radar

#endif  // SANDBOX_RADAR_LIB_VOLCANO_H_