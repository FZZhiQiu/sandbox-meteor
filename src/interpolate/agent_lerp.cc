#include "agent_lerp.h"

#include <algorithm>
#include <cstring>
#include <cmath>

namespace sandbox_radar {

// Helper function for vector linear interpolation
Vec3 AgentLerp::LerpVec3(const Vec3& a, const Vec3& b, float t) {
  return Vec3(
    a.x + t * (b.x - a.x),
    a.y + t * (b.y - a.y),
    a.z + t * (b.z - a.z)
  );
}

// Helper function for quaternion spherical linear interpolation
Quat AgentLerp::SlerpQuat(const Quat& a, const Quat& b, float t) {
  // Calculate dot product
  float dot = a.w * b.w + a.x * b.x + a.y * b.y + a.z * b.z;
  
  // Ensure we take the shortest path
  Quat b_temp = b;
  if (dot < 0.0f) {
    dot = -dot;
    b_temp.w = -b.w;
    b_temp.x = -b.x;
    b_temp.y = -b.y;
    b_temp.z = -b.z;
  }
  
  // If quaternions are very close, use linear interpolation
  if (dot > 0.9995f) {
    Quat result;
    result.w = a.w + t * (b_temp.w - a.w);
    result.x = a.x + t * (b_temp.x - a.x);
    result.y = a.y + t * (b_temp.y - a.y);
    result.z = a.z + t * (b_temp.z - a.z);
    
    // Normalize result
    float norm = std::sqrt(result.w * result.w + result.x * result.x + 
                          result.y * result.y + result.z * result.z);
    if (norm > 0.0f) {
      result.w /= norm;
      result.x /= norm;
      result.y /= norm;
      result.z /= norm;
    }
    
    return result;
  }
  
  // Calculate spherical linear interpolation
  float theta_0 = std::acos(std::abs(dot));  // Angle between input vectors
  float sin_theta_0 = std::sin(theta_0);     // Sin of angle
  float theta = theta_0 * t;                 // Interpolated angle
  float sin_theta = std::sin(theta);
  float s0 = std::cos(theta) - dot * sin_theta / sin_theta_0;  // Weight of a
  float s1 = sin_theta / sin_theta_0;                          // Weight of b
  
  return Quat(
    s0 * a.w + s1 * b_temp.w,
    s0 * a.x + s1 * b_temp.x,
    s0 * a.y + s1 * b_temp.y,
    s0 * a.z + s1 * b_temp.z
  );
}

AgentLerp::AgentLerp() : agent_count_(0) {
  prev_states_.reserve(MAX_AGENTS);
  curr_states_.reserve(MAX_AGENTS);
}

AgentLerp::~AgentLerp() {
  // Destructor implementation
}

void AgentLerp::SetAgentCount(int count) {
  agent_count_ = std::min(count, MAX_AGENTS);
  prev_states_.resize(agent_count_);
  curr_states_.resize(agent_count_);
}

int AgentLerp::GetAgentCount() const {
  return agent_count_;
}

void AgentLerp::SetPreviousStates(const std::vector<AgentState>& prev_states) {
  size_t copy_count = std::min(prev_states.size(), static_cast<size_t>(MAX_AGENTS));
  prev_states_.assign(prev_states.begin(), prev_states.begin() + copy_count);
  agent_count_ = static_cast<int>(copy_count);
}

void AgentLerp::SetCurrentStates(const std::vector<AgentState>& curr_states) {
  size_t copy_count = std::min(curr_states.size(), static_cast<size_t>(MAX_AGENTS));
  curr_states_.assign(curr_states.begin(), curr_states.begin() + copy_count);
  agent_count_ = static_cast<int>(copy_count);
}

void AgentLerp::InterpolateStates(std::vector<AgentState>& output_states, float alpha) {
  // Clamp alpha to [0, 1]
  float clamped_alpha = std::max(0.0f, std::min(1.0f, alpha));
  
  output_states.resize(agent_count_);
  
  // Perform linear interpolation for each agent
  for (int i = 0; i < agent_count_; ++i) {
    // Linear interpolation for position
    output_states[i].position = LerpVec3(prev_states_[i].position, curr_states_[i].position, clamped_alpha);
    
    // Spherical linear interpolation for rotation
    output_states[i].rotation = SlerpQuat(prev_states_[i].rotation, curr_states_[i].rotation, clamped_alpha);
    
    // Linear interpolation for scale
    output_states[i].scale = prev_states_[i].scale + clamped_alpha * (curr_states_[i].scale - prev_states_[i].scale);
    
    // Copy ID
    output_states[i].id = prev_states_[i].id;
  }
}

void AgentLerp::InterpolateStatesSIMD(std::vector<AgentState>& output_states, float alpha) {
  // In a real implementation, this would use SIMD instructions for optimization
  // For now, we'll call the regular interpolation method
  InterpolateStates(output_states, alpha);
}

}  // namespace sandbox_radar