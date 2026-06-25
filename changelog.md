# Changelog

All notable changes to this project will be documented in this file.

## 0.1.0 - 2026-06-25

### Added

- Added Mojo bindings for Tracy CPU zones, messages, frames, plots, thread names, connection status, and sleep helpers.
- Added a `tracy` Mojo module with the `Zone` API and scoped function-name reflection support.
- Added native C++ Tracy shim library build support through CMake.
- Added Tracy profiler build support through the `build-profiler` Pixi task.
- Added a rattler-build recipe, package task, smoke test, and MIT license for packaging.

### Changed

- Renamed the public Mojo import from `mojo_tracy` to `tracy`.
- Replaced the manual Tracy checkout script with CMake `FetchContent` for Tracy `v0.13.1`.
- Pinned Mojo tooling to `1.0.0b3.dev2026062206` for the package recipe.
