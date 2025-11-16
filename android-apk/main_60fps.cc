#include <iostream>
#include <thread>
#include <chrono>
#include <memory>

#include "src/core/sim_loop.h"
#include "src/core/render_loop.h"
#include "src/interpolate/field_lerp.h"
#include "src/interpolate/agent_lerp.h"
#include "src/interpolate/audio_lerp.h"

int main() {
  std::cout << "Sandbox Radar - 60 FPS Demo" << std::endl;
  std::cout << "===========================" << std::endl;
  
  // Initialize the simulation loop (3s intervals)
  auto sim_loop = std::make_unique<sandbox_radar::SimLoop>();
  
  // Initialize the render loop (60 FPS) with reference to sim loop
  auto render_loop = std::make_unique<sandbox_radar::RenderLoop>(sim_loop.get());
  
  // Start both loops
  sim_loop->Start();
  render_loop->Start();
  
  std::cout << "Simulation and render loops started" << std::endl;
  std::cout << "Sim loop: 1/3 Hz (3s intervals)" << std::endl;
  std::cout << "Render loop: 60 FPS (16.67ms intervals)" << std::endl;
  
  // Let the loops run for a while to demonstrate the 60 FPS functionality
  std::this_thread::sleep_for(std::chrono::seconds(10));
  
  // Stop loops before exit
  render_loop->Stop();
  sim_loop->Stop();
  
  std::cout << "Demo completed successfully" << std::endl;
  
  return 0;
}