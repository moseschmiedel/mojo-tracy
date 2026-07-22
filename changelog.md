# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/2.0.0/),

## [Unreleased]

### Changed

- Updated to Mojo `1.0.0b3.dev2026072206` (>=1.0.0b3.dev2026072206,<2).

## [0.2.0] - 2026-06-29

### Added

- Mojo functions are now No-Ops when Tracy is not enabled (`TRACY_ENABLE` is not defined).

## [0.1.0] - 2026-06-29

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
