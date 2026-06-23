cmake_minimum_required(VERSION 3.20)

project(mojo_tracy LANGUAGES CXX)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON) # generate `build/compile_commands.json` for clangd

option(TRACY_ENABLE " " ON)
option(TRACY_ON_DEMAND " " ON)
add_subdirectory(tracy)

add_library(mojotracy SHARED
    native/mojo_tracy.cpp
)

target_compile_features(mojotracy PRIVATE cxx_std_17)
target_include_directories(mojotracy PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/tracy/public"
)
target_link_libraries(mojotracy PUBLIC Tracy::TracyClient)

set_target_properties(mojotracy PROPERTIES
    OUTPUT_NAME mojotracy
)
