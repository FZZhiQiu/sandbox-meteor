cmake_minimum_required(VERSION 3.22.1)
project(sandbox_meteor)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -ffast-math -DNDEBUG")

option(ENABLE_60FPS "Enable 60 FPS interpolation" ON)

# 添加源码
add_library(
    sandbox_radar
    SHARED
    jni_interface.cc
    radiation.cc
    volcano.cc
    src/core/render_loop.cc
    src/core/sim_loop.cc
    src/interpolate/agent_lerp.cc
    src/interpolate/audio_lerp.cc
    src/interpolate/field_lerp.cc
)

# 包含头文件路径
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/app/src/main/cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../sandbox-radar
    ${CMAKE_CURRENT_SOURCE_DIR}/../sandbox-radar/lib
    ${CMAKE_CURRENT_SOURCE_DIR}/../sandbox-radar/src
    ${CMAKE_CURRENT_SOURCE_DIR}/../sandbox-radar/src/core
    ${CMAKE_CURRENT_SOURCE_DIR}/../sandbox-radar/src/interpolate
)

# 链接 Android NDK 提供的库
target_link_libraries(
    sandbox_radar
    log        # Android log
    android    # Android system API
)

# 主可执行文件（如果需要）
add_executable(sandbox_meteor
    main_60fps.cc
)

# 链接库到主可执行文件
target_link_libraries(sandbox_meteor
    sandbox_radar
)