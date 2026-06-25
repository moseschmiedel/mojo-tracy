cmake_minimum_required(VERSION 3.11)

project(mojo_tracy LANGUAGES CXX)

include(GNUInstallDirs)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON) # generate `build/compile_commands.json` for clangd

include(FetchContent)

FetchContent_Declare(
    tracy
    GIT_REPOSITORY https://github.com/wolfpld/tracy.git
    GIT_TAG v0.13.1 # Change tracy version here!
    GIT_SHALLOW TRUE
    GIT_PROGRESS TRUE
)

set(TRACY_ENABLE ON CACHE BOOL "Enable Tracy profiling")
set(TRACY_ON_DEMAND ON CACHE BOOL "Use Tracy on-demand profiling")
set(TRACY_CALLSTACK ON CACHE BOOL "Enforce callstack collection for tracy regions")

FetchContent_MakeAvailable(tracy)

option(MOJO_TRACY_BUILD_PROFILER "Add the Tracy profiler target from the fetched Tracy sources" OFF)

if(MOJO_TRACY_BUILD_PROFILER)
    add_subdirectory(
        "${tracy_SOURCE_DIR}/profiler"
        "${tracy_BINARY_DIR}/profiler"
        EXCLUDE_FROM_ALL
    )
endif()

add_library(mojotracy SHARED
    native/mojo_tracy.cpp
)

target_compile_features(mojotracy PRIVATE cxx_std_17)
target_link_libraries(mojotracy PUBLIC TracyClient)

set_target_properties(mojotracy PROPERTIES
    OUTPUT_NAME mojotracy
)

install(TARGETS mojotracy
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
)
