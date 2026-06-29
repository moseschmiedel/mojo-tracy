# mojo-tracy

Mojo bindings for the [Tracy](https://github.com/wolfpld/tracy) profiler.

`mojo-tracy` provides a small Mojo module plus a native C++ shim around Tracy's client API. It supports CPU zones, messages, frame marks, plots, thread names, connection status, and a simple sleep helper for examples/tests.

## Features

- Scoped CPU zones with Mojo `with` support
- Optional function-name reflection via `Zone().scoped[function]()`
- Zone text and numeric values
- Tracy messages, optionally colored
- Frame marks, including named frames
- Numeric plots (`Float64` and `Int64`)
- Thread names and profiler connection checks
- CMake build that fetches Tracy `v0.13.1`
- Optional Tracy profiler build target

## Requirements

- [Pixi](https://pixi.sh/) for the provided development tasks
- CMake and a C++17 compiler
- Mojo `1.0.0b3.dev2026062206` as pinned in `pixi.toml`

## Quick start

Build the native Tracy shim:

```bash
pixi run build-native
```

Run the included example:

```bash
pixi run example
```

The example waits up to five seconds for a Tracy profiler connection, emits zones/messages/plots for a short loop, and then exits.

To build the Tracy profiler from the fetched Tracy sources:

```bash
pixi run build-profiler
```

Then launch the generated profiler binary from the CMake build tree, connect to the running example, and capture the trace.

## Using mojo-tracy in your own project

Add `mojo-tracy` to your project's `pixi.toml` dependencies alongside Mojo:

```toml
[dependencies]
mojo = "==1.0.0b3.dev2026062206"
mojo-tracy = ">=0.2.0"
```

Then import the Mojo module as usual:

```mojo
from tracy import Zone, frame_mark, message
```

Your executable must also link against the native `mojotracy` library provided by the package and define the `TRACY_ENABLED` compiler variable. For example:

```bash
pixi run mojo run \
  -Xlinker -lmojotracy \
  -DTRACY_ENABLED \
  main.mojo
```

If your linker does not automatically search the Pixi environment library directory, pass it explicitly:

```bash
pixi run mojo run \
  -Xlinker -L"$CONDA_PREFIX/lib" \
  -Xlinker -lmojotracy \
  main.mojo
```

When `mojo-tracy` is installed as a Pixi dependency, the Tracy UI is installed into the Pixi environment too. Start it with:

```bash
pixi run tracy-profiler
```

## Using the module from source

Import from `src` and link against the native `mojotracy` library:

```bash
mojo run \
  -I src \
  -Xlinker -Lbuild \
  -Xlinker -lmojotracy \
  examples/basic.mojo
```

On macOS, make sure the dynamic loader can find `libmojotracy`, for example:

```bash
DYLD_LIBRARY_PATH=build mojo run -I src -Xlinker -Lbuild -Xlinker -lmojotracy examples/basic.mojo
```

## Example

```mojo
from tracy import Zone, frame_mark, message, plot, set_thread_name


def work(i: Int):
    with Zone().scoped[work]() as zone:
        zone.text("doing work")
        zone.value(UInt64(i))
        message("inside work")


def main():
    set_thread_name("main")

    var i = 0
    while i < 10:
        work(i)
        plot("counter", Int64(i))
        frame_mark()
        i += 1
```

You can also name zones manually:

```mojo
with Zone(function_name="load data", color=0x44AAFF):
    message("loading")
```

## Public API

```mojo
set_thread_name(name: String)
message(text: String, color: Optional[UInt32] = None)
frame_mark()
frame_mark(name: String)
plot(name: String, value: Float64)
plot(name: String, value: Int64)
is_connected() -> Bool
sleep_ms(milliseconds: UInt32)
wait_for_connection(timeout_ms: UInt32 = 5000, poll_ms: UInt32 = 100) -> Bool
```

`Zone` supports:

- `with Zone(...)` for a scoped Tracy zone
- `Zone().scoped[function]()` to use Mojo reflection for the function name
- `zone.text(text: String)` to attach text to the active zone
- `zone.value(value: UInt64)` to attach a numeric value to the active zone
- `zone.end()` for manual early termination

## License

MIT. See [`LICENSE`](LICENSE).
