# AGENTS.md

Guidance for LLM coding agents working in this repository.

## Project overview

`mojo-tracy` provides Mojo bindings for the Tracy profiler.

Main components:

- `src/tracy/` - public Mojo API and FFI declarations
- `native/mojo_tracy.cpp` - C++ shim around Tracy's client API
- `examples/basic.mojo` - example program used for manual validation
- `recipe/` - rattler-build package recipe and smoke test
- `CMakeLists.txt` - native build; fetches Tracy via CMake `FetchContent`
- `pixi.toml` - development tasks and pinned Mojo toolchain

## Development environment

Use Pixi tasks when possible:

```bash
pixi run build-native
pixi run example
pixi run build-profiler
pixi run package
```

The workspace currently targets `osx-arm64` and pins Mojo in `pixi.toml`. Do not casually update the Mojo version; if you do, update all matching pins in packaging files and note it in `changelog.md`.

## Build and validation checklist

For most changes:

1. Run `pixi run build-native`.
2. If Mojo API or examples changed, run `pixi run example`.
3. If packaging changed, run `pixi run package`.
4. If profiler packaging or CMake profiler options changed, run `pixi run build-profiler`.

When running programs from source, remember that Mojo code must link against the native library:

```bash
mojo run -I src -Xlinker -Lbuild -Xlinker -lmojotracy examples/basic.mojo
```

On macOS, dynamic loading may require:

```bash
DYLD_LIBRARY_PATH=build mojo run -I src -Xlinker -Lbuild -Xlinker -lmojotracy examples/basic.mojo
```

## Mojo code guidelines

- Keep the public API in `src/tracy/__init__.mojo` small and idiomatic.
- Keep low-level FFI declarations in `src/tracy/_ffi/`.
- If an exported C++ function is added, update both:
  - `native/mojo_tracy.cpp`
  - `src/tracy/_ffi/__init__.mojo`
- Preserve exact ABI names for `external_call[...]` entries.
- Prefer safe, simple Mojo wrappers over exposing FFI details to users.
- Ensure examples import from `tracy`, not internal modules.

## Native C++ guidelines

- Tracy is fetched by CMake; do not vendor Tracy sources into this repository.
- Keep exported functions inside `extern "C"` and mark them with `MT_EXPORT`.
- Use stable primitive ABI types for Mojo FFI (`uint64_t`, `uint32_t`, `int32_t`, `size_t`, pointers).
- Be careful with string lifetimes. Named Tracy objects may require interned/static strings; use the existing string storage pattern where needed.
- Keep the library target name as `mojotracy` unless intentionally making a breaking change.

## Packaging guidelines

If package metadata changes, keep these files consistent:

- `pixi.toml`
- `recipe/recipe.yaml`
- `changelog.md`
- `README.md` if user-facing behavior changes

The conda package is expected to include:

- `libmojotracy`
- precompiled `lib/mojo/tracy.mojoc`
- `bin/tracy-profiler`

The package smoke test in `recipe/smoke_test.sh` should remain minimal and should verify import, linking, zones, messages, and frame marks.

## Documentation guidelines

- Update `README.md` for user-facing API, build, installation, or packaging changes.
- Update `changelog.md` for notable changes.
- Mention that downstream users must link against `mojotracy` when using the Mojo module.
- Mention that `tracy-profiler` can be run with `pixi run tracy-profiler` when installed as a Pixi dependency.

## Repository hygiene

- Do not commit generated build outputs (`build/`, `output/`, `.pixi/`).
- Avoid broad rewrites unless necessary.
- Prefer focused, reviewable changes.
- Keep examples short and runnable.
- Do not introduce new dependencies without a clear reason.

## Commit messages

Follow Conventional Commits for commit messages:

```text
<type>(optional scope): <description>
```

Common types include `feat`, `fix`, `docs`, `refactor`, `test`, `build`, and `chore`.

Examples:

```text
docs: add downstream usage instructions
fix(ffi): preserve Tracy string lifetimes
build(recipe): install tracy-profiler in package
```
