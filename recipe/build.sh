#!/usr/bin/env bash
set -euxo pipefail

# Configure and build libmojotracy and the Tracy profiler using CMake
if [[ "${target_platform}" == osx-* ]]; then
    # The conda Clang package installs a versioned LTO plugin in lib/, while
    # Apple ld looks for the unversioned plugin below Clang's resource dir.
    lto_library=""
    for candidate in "${BUILD_PREFIX}"/lib/libLTO.*.dylib; do
        if [[ -f "${candidate}" ]]; then
            lto_library="${candidate}"
            break
        fi
    done
    if [[ -n "${lto_library}" ]]; then
        clang_resource_dir="$(${BUILD_PREFIX}/bin/${CC} -print-resource-dir)"
        mkdir -p "${clang_resource_dir}/lib"
        ln -sf "${lto_library}" "${clang_resource_dir}/lib/libLTO.dylib"
    fi
fi

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

# Tracy's profiler and capture CMake projects both define server targets with
# the same names, so build capture in a separate CMake tree. Reuse the Tracy
# checkout populated above to avoid fetching it a second time.
cmake ${CMAKE_ARGS} \
      -S "${SRC_DIR}" \
      -B build-capture \
      -DCMAKE_BUILD_TYPE=Release \
      -DMOJO_TRACY_BUILD_CAPTURE=ON \
      "-DFETCHCONTENT_SOURCE_DIR_TRACY=${SRC_DIR}/build/_deps/tracy-src" \
      "-DCMAKE_INSTALL_PREFIX=${PREFIX}"
cmake --build build-capture --config Release --target tracy-capture
install -m 755 build-capture/_deps/tracy-build/capture/tracy-capture "${PREFIX}/bin/tracy-capture"

# Precompile the Tracy Mojo module
mojo precompile src/tracy -o ${PREFIX}/lib/mojo/tracy.mojoc
