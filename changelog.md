# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/2.0.0/),

## [Unreleased]

## [1.0.1] - 2026-09-01

### Fixed

- Tracy FFI calls no longer fail compilation when pulled into Mojo's comptime interpreter (e.g. via a caller's function result being forced into a comptime/parameter value); `Zone` and the other module-level FFI-calling functions now no-op instead of raising "unable to interpret call to unknown external function".

## [1.0.0] - 2026-08-19

### Changed

- Updated to Mojo `1.0.0` (>=1.0.0,<2).

## [0.7.1] - 2026-08-06

### Fixed

- Linker error of `tracy-profiler` under macOS: `libLTO.dylib not found`.

## [0.7.0] - 2026-08-06

### Changed

- Updated to Mojo `1.1.0.dev2026080606` (>=1.1.0.dev2026080606,<2).

## [0.6.0] - 2026-08-04

### Changed

- Updated to Mojo `1.0.0b3.dev2026080406` (>=1.0.0b3.dev2026080406,<2).

## [0.5.0] - 2026-08-03

### Changed

- Updated to Mojo `1.0.0b3.dev2026072806` (>=1.0.0b3.dev2026072806,<2).

## [0.4.0] - 2026-07-28

### Changed

- Updated to Mojo `1.0.0b3.dev2026072806` (>=1.0.0b3.dev2026072806,<2).

## [0.3.0] - 2026-07-22

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
