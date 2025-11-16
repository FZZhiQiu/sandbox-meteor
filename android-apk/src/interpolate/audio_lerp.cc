#include "audio_lerp.h"

#include <algorithm>
#include <cmath>

namespace sandbox_radar {

AudioLerp::AudioLerp() 
    : prev_volume_(0.0f), curr_volume_(0.0f),
      prev_left_gain_(0.0f), prev_right_gain_(0.0f),
      curr_left_gain_(0.0f), curr_right_gain_(0.0f) {
  // Constructor implementation
}

AudioLerp::~AudioLerp() {
  // Destructor implementation
}

void AudioLerp::SetPreviousVolume(float volume) {
  prev_volume_ = volume;
}

void AudioLerp::SetCurrentVolume(float volume) {
  curr_volume_ = volume;
}

void AudioLerp::SetPreviousLeftGain(float gain) {
  prev_left_gain_ = gain;
}

void AudioLerp::SetPreviousRightGain(float gain) {
  prev_right_gain_ = gain;
}

void AudioLerp::SetCurrentLeftGain(float gain) {
  curr_left_gain_ = gain;
}

void AudioLerp::SetCurrentRightGain(float gain) {
  curr_right_gain_ = gain;
}

void AudioLerp::InterpolateAudio(float& volume, float& left_gain, float& right_gain, float alpha) {
  // Clamp alpha to [0, 1]
  float clamped_alpha = std::max(0.0f, std::min(1.0f, alpha));
  
  // Linear interpolation for each parameter
  volume = prev_volume_ + clamped_alpha * (curr_volume_ - prev_volume_);
  left_gain = prev_left_gain_ + clamped_alpha * (curr_left_gain_ - prev_left_gain_);
  right_gain = prev_right_gain_ + clamped_alpha * (curr_right_gain_ - prev_right_gain_);
}

void AudioLerp::ApplyRamp(std::vector<float>& buffer, float target_value, int samples) {
  if (buffer.empty() || samples <= 0) {
    return;
  }
  
  // Clamp samples to buffer size
  int actual_samples = std::min(samples, static_cast<int>(buffer.size()));
  
  // Get the starting value from the buffer
  float start_value = buffer[0];
  
  // Apply linear ramp from start_value to target_value
  for (int i = 0; i < actual_samples; ++i) {
    float alpha = static_cast<float>(i) / static_cast<float>(actual_samples - 1);
    buffer[i] = start_value + alpha * (target_value - start_value);
  }
}

}  // namespace sandbox_radar