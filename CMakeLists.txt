cmake_minimum_required(VERSION 3.22.1)
project(sandbox_meteor)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -ffast-math -DNDEBUG")

option(ENABLE_60FPS "Enable 60 FPS interpolation" ON)

# 查找所有源文件
file(GLOB_RECURSE LIB_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/../sandbox-radar/lib/*.cc"
    "${CMAKE_CURRENT_SOURCE_DIR}/../sandbox-radar/lib/**/*.cc"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/core/*.cc"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/interpolate/*.cc"
)

# 创建共享库
add_library(sandbox_radar SHARED
    ${LIB_SOURCES}
    jni_interface.cc
    radiation.cc  # 添加新的辐射模块
    volcano.cc    # 添加新的火山模块
)

# 包含头文件目录
target_include_directories(sandbox_radar PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/../sandbox-radar"
    "${CMAKE_CURRENT_SOURCE_DIR}/../sandbox-radar/lib"
    "${CMAKE_CURRENT_SOURCE_DIR}"
)

# 链接库
target_link_libraries(sandbox_radar
    # 添加所需的库
)

# 主可执行文件
add_executable(sandbox_meteor
    main_60fps.cc
)

# 链接库到主可执行文件
target_link_libraries(sandbox_meteor
    sandbox_radar
)