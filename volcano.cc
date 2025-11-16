#include "lib/volcano.h"

#include <cmath>
#include <algorithm>
#include <iostream>

namespace sandbox_radar {

VolcanoModule::VolcanoModule() : nx_(0), ny_(0), nz_(0), 
                                current_eruption_time_(0.0f),
                                active_volcano_name_("") {
}

VolcanoModule::~VolcanoModule() {
}

void VolcanoModule::Initialize(int nx, int ny, int nz) {
    nx_ = nx;
    ny_ = ny;
    nz_ = nz;
    
    int total_points = nx * ny * nz;
    
    // 初始化火山物质浓度场 (3D)
    so2_concentration_.resize(total_points, 0.0f);
    ash_concentration_.resize(total_points, 0.0f);
    aerosol_optical_depth_.resize(total_points, 0.0f);
    
    // 添加一些默认的火山
    AddVolcano("基拉韦厄火山", 19.421f, -155.287f, 1222.0f, 1000.0f, 5000.0f);
    AddVolcano("埃特纳火山", 37.751f, 14.993f, 3329.0f, 500.0f, 3000.0f);
    AddVolcano("维苏威火山", 40.821f, 14.426f, 1281.0f, 200.0f, 1000.0f);
    AddVolcano("富士山", 35.3606f, 138.7274f, 3776.0f, 0.0f, 0.0f); // 休眠火山
}

void VolcanoModule::Update(float dt, Chemistry& chemistry, float* temperature, float* pressure) {
    // 如果有活跃的喷发，添加SO₂和火山灰
    if (!active_volcano_name_.empty() && current_eruption_time_ > 0.0f) {
        for (auto& volcano : volcanoes_) {
            if (volcano.name == active_volcano_name_ && volcano.is_active) {
                // 计算喷发点在网格中的位置
                if (volcano.grid_x >= 0 && volcano.grid_x < nx_ &&
                    volcano.grid_y >= 0 && volcano.grid_y < ny_ &&
                    volcano.grid_z >= 0 && volcano.grid_z < nz_) {
                    
                    int idx = volcano.grid_z * nx_ * ny_ + volcano.grid_y * nx_ + volcano.grid_x;
                    
                    // 添加SO₂到化学模块
                    // 注意：这里简化处理，实际应该更复杂
                    std::vector<float>& co2_data = const_cast<std::vector<float>&>(chemistry.GetCO2Data());
                    if (idx < co2_data.size()) {
                        co2_data[idx] += volcano.so2_emission_rate * dt / 1000.0f; // 简化转换
                    }
                    
                    // 添加SO₂到本地浓度场
                    if (idx < so2_concentration_.size()) {
                        so2_concentration_[idx] += volcano.so2_emission_rate * dt;
                    }
                    
                    // 添加火山灰到本地浓度场
                    if (idx < ash_concentration_.size()) {
                        ash_concentration_[idx] += volcano.ash_emission_rate * dt;
                    }
                }
            }
        }
        
        // 减少喷发时间
        current_eruption_time_ -= dt;
        if (current_eruption_time_ <= 0.0f) {
            active_volcano_name_ = "";
        }
    }
    
    // 计算气溶胶光学特性
    ComputeAerosolOptics();
}

void VolcanoModule::AddVolcano(const std::string& name, float lat, float lon, float elevation,
                               float so2_rate, float ash_rate) {
    Volcano volcano;
    volcano.name = name;
    volcano.latitude = lat;
    volcano.longitude = lon;
    volcano.elevation = elevation;
    volcano.so2_emission_rate = so2_rate;
    volcano.ash_emission_rate = ash_rate;
    volcano.is_active = (so2_rate > 0.0f || ash_rate > 0.0f);
    
    // 将经纬度转换为网格坐标 (简化)
    // 假设网格覆盖全球，经度-180到180，纬度-90到90
    volcano.grid_x = static_cast<int>((lon + 180.0f) / 360.0f * (nx_ - 1));
    volcano.grid_y = static_cast<int>((lat + 90.0f) / 180.0f * (ny_ - 1));
    volcano.grid_z = std::min(nz_ - 1, static_cast<int>(elevation / 1000.0f)); // 简化高度转换
    
    // 确保网格坐标在有效范围内
    volcano.grid_x = std::max(0, std::min(nx_ - 1, volcano.grid_x));
    volcano.grid_y = std::max(0, std::min(ny_ - 1, volcano.grid_y));
    volcano.grid_z = std::max(0, std::min(nz_ - 1, volcano.grid_z));
    
    volcanoes_.push_back(volcano);
}

void VolcanoModule::ActivateEruption(const std::string& name, float duration, float intensity) {
    for (auto& volcano : volcanoes_) {
        if (volcano.name == name) {
            volcano.is_active = true;
            active_volcano_name_ = name;
            current_eruption_time_ = duration;
            
            // 调整排放率
            volcano.so2_emission_rate *= intensity;
            volcano.ash_emission_rate *= intensity;
            break;
        }
    }
}

void VolcanoModule::ComputeAerosolOptics() {
    // 计算气溶胶光学厚度 (简化)
    for (int i = 0; i < aerosol_optical_depth_.size(); i++) {
        // 气溶胶光学厚度与SO₂和火山灰浓度相关
        aerosol_optical_depth_[i] = 0.1f * (so2_concentration_[i] + ash_concentration_[i] * 0.01f);
        
        // 确保非负
        aerosol_optical_depth_[i] = std::max(0.0f, aerosol_optical_depth_[i]);
    }
}

}  // namespace sandbox_radar