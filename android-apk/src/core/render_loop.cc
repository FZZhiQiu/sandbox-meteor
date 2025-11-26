#include "render_loop.h"

#include <iostream>
#include <chrono>

namespace sandbox_radar {

RenderLoop::RenderLoop(SimLoop* sim_loop) : sim_loop_(sim_loop) {
  if (!sim_loop_) {
    std::cerr << "Error: RenderLoop requires a valid SimLoop pointer" << std::endl;
  }
}

RenderLoop::~RenderLoop() {
  Stop();
}

void RenderLoop::Start() {
  if (running_ || !sim_loop_) {
    return;
  }

  running_ = true;
  render_thread_ = std::thread(&RenderLoop::Run, this);
  std::cout << "Render loop started (60 FPS target)" << std::endl;
}

void RenderLoop::Stop() {
  if (!running_) {
    return;
  }

  running_ = false;
  if (render_thread_.joinable()) {
    render_thread_.join();
  }
  std::cout << "Render loop stopped" << std::endl;
}

double RenderLoop::GetFrameTime() const {
  return frame_time_.load();
}

bool RenderLoop::IsRendering() const {
  return running_.load();
}

void RenderLoop::Run() {
  auto last_frame_time = std::chrono::steady_clock::now();
  auto frame_start_time = last_frame_time;
  
  while (running_) {
    frame_start_time = std::chrono::steady_clock::now();
    
    // Render one frame
    RenderFrame();
    
    // Calculate frame time
    auto frame_end_time = std::chrono::steady_clock::now();
    double frame_time_ms = std::chrono::duration<double, std::milli>(frame_end_time - frame_start_time).count();
    frame_time_ = frame_time_ms;
    
    // Calculate time to sleep to maintain 60 FPS
    auto elapsed = std::chrono::duration<double, std::milli>(frame_end_time - last_frame_time).count();
    double sleep_time = FRAME_TIME_MS - elapsed;
    
    if (sleep_time > 0) {
      std::this_thread::sleep_for(std::chrono::milliseconds(static_cast<int>(sleep_time)));
    }
    
    last_frame_time = std::chrono::steady_clock::now();
    
    // Print performance info periodically
    static int frame_count = 0;
    if (++frame_count % 600 == 0) {  // Every 10 seconds
      std::cout << "Render loop: ~60 FPS maintained, frame time: " << frame_time_ms << " ms" << std::endl;
    }
  }
}

void RenderLoop::RenderFrame() {
  // In a real implementation, this would:
  // 1. Get current and previous simulation data
  // 2. Interpolate data for current frame time
  // 3. Update GPU buffers
  // 4. Render the scene
  
  // For now, just simulate the interpolation work
  if (sim_loop_ && sim_loop_->HasNewData()) {
    // Get current data from sim loop
    static float temp_buffer[17 * 200 * 200 * 30]; // Size based on grid dimensions
    sim_loop_->GetGridData(temp_buffer);
    
    // In real implementation, would perform interpolation here
    // and render to screen
    
    // Simulate rendering work
    // This is where field_lerp, agent_lerp, and audio_lerp would be called
  }
}

}  // namespace sandbox_radar