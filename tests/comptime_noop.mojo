# Guards against a regression where Tracy's FFI calls were reachable from
# Mojo's comptime interpreter.
#
# Zone and the other module-level functions in `tracy` call into Tracy's C
# library via `external_call`. If one of those functions gets pulled into a
# compile-time evaluation - for example because a caller's result is forced
# into a comptime/parameter value - the compiler used to try to *interpret*
# the external_call and fail with:
#
#   unable to interpret call to unknown external function
#
# Every FFI call site is now guarded with `__is_run_in_comptime_interpreter`
# so it no-ops instead of failing compilation. There is no runtime assertion
# here: the test *is* that this file compiles and runs at all. Binding
# `_run_all_tracy_calls` to a module-level `comptime` value forces Mojo to
# evaluate it through the comptime interpreter rather than emitting it as
# ordinary runtime code.
#
# Run with:
#   pixi run test-comptime

from tracy import (
    Zone,
    frame_mark,
    is_connected,
    message,
    plot,
    set_thread_name,
    sleep_ms,
    wait_for_connection,
)


def _run_all_tracy_calls() -> Bool:
    set_thread_name("comptime test")
    message("comptime message")
    message("comptime message with color", color=UInt32(0xFF0000))

    frame_mark()
    frame_mark("comptime frame")

    plot("comptime.float", Float64(1))
    plot("comptime.int", Int64(1))

    _ = is_connected()
    _ = wait_for_connection(timeout_ms=1, poll_ms=1)
    sleep_ms(1)

    with Zone("comptime zone"):
        pass

    var zone = Zone("comptime zone 2")
    zone.__enter__()
    zone.text("zone text")
    zone.value(1)
    zone.end()

    return True


comptime _comptime_result = _run_all_tracy_calls()


def main():
    if not _comptime_result:
        print("FAIL: comptime tracy calls returned an unexpected result")
        return
    print("PASS: tracy calls no-op correctly under the comptime interpreter")
