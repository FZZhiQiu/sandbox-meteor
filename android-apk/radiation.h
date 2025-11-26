#ifndef SANDBOX_RADAR_LIB_RADIATION_H_
#define SANDBOX_RADAR_LIB_RADIATION_H_

#include "lib/grid.h"
#include "lib/chemistry.h"

#include <vector>

namespace sandbox_radar {

// RRTMG辐射传输模块类
class Radiation {
 public:
  Radiation();
  ~Radiation();

  // 初始化辐射模块
  void Initialize(int nx, int ny, int nz);

  // 更新辐射状态
  void Update(float dt, const float* temperature, const float* pressure,
              const float* humidity, const Chemistry& chemistry);

  // 计算短波辐射（太阳辐射）
  void ComputeShortwaveRadiation(const float* temperature, const float* humidity,
                                const Chemistry& chemistry, float solar_constant);

  // 计算长波辐射（地球辐射）
  void ComputeLongwaveRadiation(const float* temperature, const float* humidity,
                               const Chemistry& chemistry);

  // 计算辐射通量
  void ComputeRadiativeFluxes();

  // 获取向上长波辐射
  const std::vector<float>& GetUpwardLWFlux() const { return upward_lw_flux_; }

  // 获取向下长波辐射
  const std::vector<float>& GetDownwardLWFlux() const { return downward_lw_flux_; }

  // 获取向上短波辐射
  const std::vector<float>& GetUpwardSWFlux() const { return upward_sw_flux_; }

  // 获取向下短波辐射
  const std::vector<float>& GetDownwardSWFlux() const { return downward_sw_flux_; }

  // 获取净辐射通量
  const std::vector<float>& GetNetFlux() const { return net_flux_; }

  // 获取辐射加热率
  const std::vector<float>& GetHeatingRate() const { return heating_rate_; }

  // 设置辐射参数
  void SetRadiationParameters();

 private:
  // 辐射通量场 (3D)
  std::vector<float> upward_lw_flux_;    // 向上长波辐射通量
  std::vector<float> downward_lw_flux_;  // 向下长波辐射通量
  std::vector<float> upward_sw_flux_;    // 向上短波辐射通量
  std::vector<float> downward_sw_flux_;  // 向下短波辐射通量
  std::vector<float> net_flux_;          // 净辐射通量
  std::vector<float> heating_rate_;      // 辐射加热率
  std::vector<float> optical_depth_;     // 光学厚度
  std::vector<float> transmissivity_;    // 透射率

  // 网格尺寸
  int nx_, ny_, nz_;

  // 物理参数
  static constexpr float STEFAN_BOLTZMANN = 5.67e-8f;      // 斯特藩-玻尔兹曼常数 (W/m²/K⁴)
  static constexpr float SOLAR_CONSTANT = 1361.0f;         // 太阳常数 (W/m²)
  static constexpr float PLANCK_C1 = 3.74177e-16f;         // 普朗克第一辐射常数
  static constexpr float PLANCK_C2 = 1.43878e-2f;          // 普朗克第二辐射常数
  static constexpr float AVOGADRO = 6.02214076e23f;        // 阿伏伽德罗常数
  static constexpr float GAS_CONSTANT = 8.314462618f;      // 气体常数

  // CO₂辐射参数
  static constexpr float CO2_ABSORPTION = 0.042f;          // CO₂吸收系数
  static constexpr float CO2_BAND_CENTERS[5] = {2.7f, 4.3f, 9.4f, 10.4f, 15.0f}; // CO₂吸收带中心 (μm)
  static constexpr float CO2_BAND_STRENGTHS[5] = {0.1f, 0.8f, 0.05f, 0.03f, 0.9f}; // CO₂吸收带强度

  // H2O辐射参数
  static constexpr float H2O_ABSORPTION = 0.025f;          // H2O吸收系数
  static constexpr float H2O_BAND_CENTERS[4] = {1.38f, 1.87f, 2.7f, 6.3f}; // H2O吸收带中心 (μm)
  static constexpr float H2O_BAND_STRENGTHS[4] = {0.5f, 0.4f, 0.7f, 0.8f}; // H2O吸收带强度

  // O3辐射参数
  static constexpr float O3_ABSORPTION = 0.085f;           // O3吸收系数
  static constexpr float O3_BAND_CENTERS[3] = {9.6f, 14.0f, 5.4f}; // O3吸收带中心 (μm)
  static constexpr float O3_BAND_STRENGTHS[3] = {0.9f, 0.1f, 0.3f}; // O3吸收带强度

  // 气溶胶辐射参数
  static constexpr float AEROSOL_EXTINCTION = 0.01f;       // 气溶胶消光系数
  static constexpr float AEROSOL_SINGLE_SCATTER = 0.85f;   // 气溶胶单次散射反照率
};

}  // namespace sandbox_radar

#endif  // SANDBOX_RADAR_LIB_RADIATION_H_