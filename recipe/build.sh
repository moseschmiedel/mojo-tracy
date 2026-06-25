#!/usr/bin/env bash
set -euxo pipefail

# Configure and build libmojotracy and the Tracy profiler using CMake
cmake ${CMAKE_ARGS} \
      -S ${SRC_DIR} \
      -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DMOJO_TRACY_BUILD_PROFILER=ON \
      -DCMAKE_INSTALL_PREFIX=${PREFIX}
cmake --build build --config Release --target install
cmake --build build --config Release --target tracy-profiler

mkdir -p "${PREFIX}/bin"
install -m 755 build/_deps/tracy-build/profiler/tracy-profiler "${PREFIX}/bin/tracy-profiler"

# Precompile the Tracy Mojo module
mojo precompile src/tracy -o ${PREFIX}/lib/mojo/tracy.mojoc
