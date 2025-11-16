#include "sim_loop.h"
#include "lib/meteor_core.h"  // Include the actual header

#include <iostream>
#include <cstring>
#include <algorithm>

namespace sandbox_radar {

SimLoop::SimLoop() : meteor_core_(nullptr) {
  // Initialize the meteorological core
  meteor_core_ = new MeteorCore();
  meteor_core_->Initialize();
  
  // Initialize grid data arrays
  std::memset(current_grid_data_, 0, sizeof(current_grid_data_));
  std::memset(previous_grid_data_, 0, sizeof(previous_grid_data_));
}

SimLoop::~SimLoop() {
  Stop();
  if (meteor_core_) {
    delete meteor_core_;
  }
}

void SimLoop::Start() {
  if (running_) {
    return;
  }

  running_ = true;
  sim_thread_ = std::thread(&SimLoop::Run, this);
  std::cout << "Simulation loop started (3s interval)" << std::endl;
}

void SimLoop::Stop() {
  if (!running_) {
    return;
  }

  running_ = false;
  if (sim_thread_.joinable()) {
    sim_thread_.join();
  }
  std::cout << "Simulation loop stopped" << std::endl;
}

double SimLoop::GetSimTime() const {
  return sim_time_.load();
}

void SimLoop::GetGridData(float* output_data) const {
  std::lock_guard<std::mutex> lock(grid_mutex_);
  std::memcpy(output_data, current_grid_data_, sizeof(current_grid_data_));
}

bool SimLoop::HasNewData() const {
  return new_data_available_;
}

void SimLoop::Run() {
  // Copy initial data
  {
    std::lock_guard<std::mutex> lock(grid_mutex_);
    // In a real implementation, we would copy data from the meteorological core
    // For now, we'll just initialize with some dummy data
    for (int i = 0; i < GRID_SIZE; ++i) {
      current_grid_data_[i] = static_cast<float>(i % 1000) / 1000.0f;
    }
    new_data_available_ = true;
  }
  data_cv_.notify_all();

  while (running_) {
    // Sleep for 3 seconds
    std::this_thread::sleep_for(std::chrono::seconds(3));
    
    if (!running_) break;

    // Perform one simulation step
    auto start = std::chrono::high_resolution_clock::now();
    
    // In a real implementation, we would call meteor_core_->Step()
    // For now, we'll simulate the step by updating data
    {
      std::lock_guard<std::mutex> lock(grid_mutex_);
      // Swap previous and current data
      std::swap(previous_grid_data_, current_grid_data_);
      
      // Update current data (simplified simulation)
      for (int i = 0; i < GRID_SIZE; ++i) {
        current_grid_data_[i] = previous_grid_data_[i] + 0.01f;
        // Keep values bounded
        if (current_grid_data_[i] > 1.0f) {
          current_grid_data_[i] = 0.0f;
        }
      }
      
      new_data_available_ = true;
    }
    
    // Update simulation time
    sim_time_.store(sim_time_.load() + 3.0);
    
    // Notify waiting threads that new data is available
    data_cv_.notify_all();
    
    auto end = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
    std::cout << "Simulation step completed in " << duration.count() << " ms" << std::endl;
  }
}

}  // namespace sandbox_radar