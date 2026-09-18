cmake_minimum_required(VERSION 3.11)

project(mojo_tracy LANGUAGES CXX)

include(GNUInstallDirs)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON) # generate `build/compile_commands.json` for clangd

include(FetchContent)

FetchContent_Declare(
    tracy
    GIT_REPOSITORY https://github.com/wolfpld/tracy.git
    GIT_TAG v0.14.1 # Change tracy version here!
    GIT_SHALLOW TRUE
    GIT_PROGRESS TRUE
)

set(TRACY_ENABLE ON CACHE BOOL "Enable Tracy profiling")
set(TRACY_ON_DEMAND ON CACHE BOOL "Use Tracy on-demand profiling")

# Tracy 0.14 turned TRACY_CALLSTACK from a boolean toggle into a numeric
# callstack capture depth (CACHE STRING). A build directory configured by an
# older version of this file cached it as CACHE BOOL; since a non-forcing
# set() to a differently-typed CACHE variable is a no-op, that stale `ON`
# would otherwise survive and leak into the TRACY_CALLSTACK preprocessor
# define, breaking the build. Drop the stale entry so it can be recreated
# with the correct type below.
if(DEFINED CACHE{TRACY_CALLSTACK})
    get_property(_mojo_tracy_callstack_type CACHE TRACY_CALLSTACK PROPERTY TYPE)
    if(NOT _mojo_tracy_callstack_type STREQUAL "STRING")
        unset(TRACY_CALLSTACK CACHE)
    endif()
    unset(_mojo_tracy_callstack_type)
endif()
set(TRACY_CALLSTACK "10" CACHE STRING "Callstack collection depth for tracy regions")

FetchContent_MakeAvailable(tracy)

option(MOJO_TRACY_BUILD_PROFILER "Add the Tracy profiler target from the fetched Tracy sources" OFF)
option(MOJO_TRACY_BUILD_CAPTURE "Add the Tracy capture target from the fetched Tracy sources" OFF)

# Both Tracy utility subprojects define common targets (for example,
# TracyServer and TracyGetOpt). Build them in separate CMake trees instead of
# allowing duplicate target definitions in a single build.
if(MOJO_TRACY_BUILD_PROFILER AND MOJO_TRACY_BUILD_CAPTURE)
    message(FATAL_ERROR
        "MOJO_TRACY_BUILD_PROFILER and MOJO_TRACY_BUILD_CAPTURE must be built "
        "in separate build directories."
    )
endif()

if(MOJO_TRACY_BUILD_PROFILER)
    add_subdirectory(
        "${tracy_SOURCE_DIR}/profiler"
        "${tracy_BINARY_DIR}/profiler"
        EXCLUDE_FROM_ALL
    )

    # Tracy (still true as of 0.14.1) uses fixed-width integer types without
    # including <cstdint>.
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        target_compile_options(tracy-profiler PRIVATE
            "$<$<COMPILE_LANGUAGE:CXX>:-include;cstdint>"
        )
    endif()
endif()

if(MOJO_TRACY_BUILD_CAPTURE)
    add_subdirectory(
        "${tracy_SOURCE_DIR}/capture"
        "${tracy_BINARY_DIR}/capture"
        EXCLUDE_FROM_ALL
    )

    # Tracy's server sources still use fixed-width integer types without
    # including <cstdint> in every translation unit.
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        target_compile_options(tracy-capture PRIVATE
            "$<$<COMPILE_LANGUAGE:CXX>:-include;cstdint>"
        )
    endif()
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
