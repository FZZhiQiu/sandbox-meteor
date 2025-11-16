#include "lib/radiation.h"

#include <cmath>
#include <algorithm>

namespace sandbox_radar {

Radiation::Radiation() : nx_(0), ny_(0), nz_(0) {
}

Radiation::~Radiation() {
}

void Radiation::Initialize(int nx, int ny, int nz) {
    nx_ = nx;
    ny_ = ny;
    nz_ = nz;
    
    int total_points = nx * ny * nz;
    
    // 初始化辐射通量场 (3D)
    upward_lw_flux_.resize(total_points, 0.0f);
    downward_lw_flux_.resize(total_points, 0.0f);
    upward_sw_flux_.resize(total_points, 0.0f);
    downward_sw_flux_.resize(total_points, 0.0f);
    net_flux_.resize(total_points, 0.0f);
    heating_rate_.resize(total_points, 0.0f);
    optical_depth_.resize(total_points, 0.0f);
    transmissivity_.resize(total_points, 0.0f);
    
    // 设置辐射参数
    SetRadiationParameters();
}

void Radiation::Update(float dt, const float* temperature, const float* pressure,
                      const float* humidity, const Chemistry& chemistry) {
    // 使用当前大气状态更新辐射计算
    const std::vector<float>& co2_data = chemistry.GetCO2Data();
    const std::vector<float>& h2o_data = chemistry.GetCO2Data(); // 使用CO2数据作为占位符
    const std::vector<float>& o3_data = chemistry.GetOzoneData();
    const std::vector<float>& aerosol_data = chemistry.GetAerosolData();
    
    // 计算短波辐射（太阳辐射）
    ComputeShortwaveRadiation(temperature, humidity, chemistry, SOLAR_CONSTANT);
    
    // 计算长波辐射（地球辐射）
    ComputeLongwaveRadiation(temperature, humidity, chemistry);
    
    // 计算净辐射通量
    ComputeRadiativeFluxes();
    
    // 计算辐射加热率
    for (int k = 0; k < nz_; k++) {
        for (int j = 0; j < ny_; j++) {
            for (int i = 0; i < nx_; i++) {
                int idx = k * nx_ * ny_ + j * nx_ + i;
                
                // 计算辐射加热率 (简化)
                // 加热率 = 净辐射通量 / 大气热容量
                float air_density = pressure[idx] / (287.0f * temperature[idx]); // 理想气体定律
                float heat_capacity = 1005.0f; // 空气比热容 J/(kg*K)
                float heat_capacity_per_volume = air_density * heat_capacity;
                
                if (heat_capacity_per_volume > 0.0f) {
                    heating_rate_[idx] = net_flux_[idx] / heat_capacity_per_volume;
                } else {
                    heating_rate_[idx] = 0.0f;
                }
            }
        }
    }
}

void Radiation::ComputeShortwaveRadiation(const float* temperature, const float* humidity,
                                         const Chemistry& chemistry, float solar_constant) {
    const std::vector<float>& co2_data = chemistry.GetCO2Data();
    const std::vector<float>& o3_data = chemistry.GetOzoneData();
    const std::vector<float>& aerosol_data = chemistry.GetAerosolData();
    
    // 简化的短波辐射计算
    for (int k = 0; k < nz_; k++) {
        for (int j = 0; j < ny_; j++) {
            for (int i = 0; i < nx_; i++) {
                int idx = k * nx_ * ny_ + j * nx_ + i;
                
                // 计算天顶角的简化模型 (纬度和时间效应)
                float lat_factor = 1.0f - std::abs((float)j / (ny_ - 1) - 0.5f) * 2.0f;
                float day_factor = 0.5f + 0.5f * lat_factor; // 简化的日变化
                
                // 初始太阳辐射
                float top_radiation = solar_constant * day_factor;
                
                // 计算各成分的光学厚度
                float co2_optical = CO2_ABSORPTION * co2_data[idx] * 1e-6f; // ppm转换为比例
                float h2o_optical = H2O_ABSORPTION * humidity[idx];
                float o3_optical = O3_ABSORPTION * o3_data[idx] * 1e-9f; // ppb转换为比例
                float aerosol_optical = AEROSOL_EXTINCTION * aerosol_data[idx] * 1e-6f; // μg/m³转换
                
                // 总光学厚度
                float total_optical = co2_optical + h2o_optical + o3_optical + aerosol_optical;
                
                // 计算透射率 (比尔-朗伯定律)
                float transmissivity = std::exp(-total_optical);
                
                // 向下的短波辐射
                downward_sw_flux_[idx] = top_radiation * transmissivity;
                
                // 向上的短波辐射 (简化为反射)
                float surface_albedo = 0.1f + 0.05f * k / nz_; // 简化的地表反照率
                upward_sw_flux_[idx] = downward_sw_flux_[idx] * surface_albedo;
            }
        }
    }
}

void Radiation::ComputeLongwaveRadiation(const float* temperature, const float* humidity,
                                        const Chemistry& chemistry) {
    const std::vector<float>& co2_data = chemistry.GetCO2Data();
    const std::vector<float>& o3_data = chemistry.GetOzoneData();
    const std::vector<float>& aerosol_data = chemistry.GetAerosolData();
    
    // 长波辐射计算 (热辐射)
    for (int k = 0; k < nz_; k++) {
        for (int j = 0; j < ny_; j++) {
            for (int i = 0; i < nx_; i++) {
                int idx = k * nx_ * ny_ + j * nx_ + i;
                
                // 黑体辐射 (斯特藩-玻尔兹曼定律)
                float blackbody_radiation = STEFAN_BOLTZMANN * std::pow(temperature[idx], 4.0f);
                
                // 计算各成分的发射率
                float co2_emission = 1.0f - std::exp(-CO2_ABSORPTION * co2_data[idx] * 1e-6f);
                float h2o_emission = 1.0f - std::exp(-H2O_ABSORPTION * humidity[idx]);
                float o3_emission = 1.0f - std::exp(-O3_ABSORPTION * o3_data[idx] * 1e-9f);
                
                // 总发射率
                float total_emission = std::min(1.0f, co2_emission + h2o_emission + o3_emission);
                
                // 向上的长波辐射
                upward_lw_flux_[idx] = blackbody_radiation * total_emission;
                
                // 向下的长波辐射 (来自上层大气的辐射)
                if (k < nz_ - 1) {
                    int upper_idx = (k + 1) * nx_ * ny_ + j * nx_ + i;
                    float upper_temp = temperature[upper_idx];
                    float upper_blackbody = STEFAN_BOLTZMANN * std::pow(upper_temp, 4.0f);
                    downward_lw_flux_[idx] = upper_blackbody * total_emission * 0.5f; // 简化
                } else {
                    downward_lw_flux_[idx] = 0.0f; // 顶部边界
                }
            }
        }
    }
}

void Radiation::ComputeRadiativeFluxes() {
    // 计算净辐射通量
    for (int i = 0; i < net_flux_.size(); i++) {
        net_flux_[i] = (upward_lw_flux_[i] - downward_lw_flux_[i]) + 
                       (upward_sw_flux_[i] - downward_sw_flux_[i]);
    }
}

void Radiation::SetRadiationParameters() {
    // 设置初始辐射参数
    for (int k = 0; k < nz_; k++) {
        for (int j = 0; j < ny_; j++) {
            for (int i = 0; i < nx_; i++) {
                int idx = k * nx_ * ny_ + j * nx_ + i;
                
                // 初始辐射通量 (平衡状态)
                upward_lw_flux_[idx] = 240.0f; // 平均向上长波辐射
                downward_lw_flux_[idx] = 340.0f; // 平均向下长波辐射
                upward_sw_flux_[idx] = 100.0f; // 平均向上短波辐射（反射）
                downward_sw_flux_[idx] = 340.0f; // 平均向下短波辐射（太阳）
                net_flux_[idx] = -100.0f; // 净辐射（通常为负，因为向上辐射多）
            }
        }
    }
}

}  // namespace sandbox_radar