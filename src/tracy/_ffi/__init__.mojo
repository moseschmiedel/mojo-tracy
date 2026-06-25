from std.ffi import external_call
from .types import MtString

def mt_tracy_set_thread_name(name: MtString, name_size: UInt):
    external_call["mt_tracy_set_thread_name", NoneType, MtString, UInt](name, name_size)

def mt_tracy_message(text: MtString, text_size: UInt, color: UInt32, has_color: Int32):
    external_call["mt_tracy_message", NoneType, MtString, UInt, UInt32, Int32](
        text, text_size, color, has_color
    )

def mt_tracy_frame_mark():
    external_call["mt_tracy_frame_mark", NoneType]()

def mt_tracy_frame_mark_named(name: MtString, name_size: UInt):
    external_call["mt_tracy_frame_mark_named", NoneType, MtString, UInt](name, name_size)

def mt_tracy_plot_f64(name: MtString, name_size: UInt, value: Float64):
    external_call["mt_tracy_plot_f64", NoneType, MtString, UInt, Float64](
        name, name_size, value
    )

def mt_tracy_plot_i64(name: MtString, name_size: UInt, value: Int64):
    external_call["mt_tracy_plot_i64", NoneType, MtString, UInt, Int64](
        name, name_size, value
    )

def mt_tracy_zone_begin(
    zone_name: MtString,
    zone_name_size: UInt,
    function_name: MtString,
    function_name_size: UInt,
    file_name: MtString,
    file_name_size: UInt,
    line: UInt32,
    color: UInt32,
    active: Int32,
) -> UInt64:
    return external_call[
        "mt_tracy_zone_begin",
        UInt64,
        MtString,
        UInt,
        MtString,
        UInt,
        MtString,
        UInt,
        UInt32,
        UInt32,
        Int32,
    ](zone_name, zone_name_size, function_name, function_name_size, file_name, file_name_size, line, color, active)

def mt_tracy_zone_end(zone_handle: UInt64):
    external_call["mt_tracy_zone_end", NoneType, UInt64](zone_handle)

def mt_tracy_zone_text(zone_handle: UInt64, text: MtString, text_size: UInt):
    external_call["mt_tracy_zone_text", NoneType, UInt64, MtString, UInt](
        zone_handle, text, text_size
    )

def mt_tracy_zone_value(zone_handle: UInt64, value: UInt64):
    external_call["mt_tracy_zone_value", NoneType, UInt64, UInt64](zone_handle, value)

def mt_tracy_is_connected() -> Int32:
    return external_call["mt_tracy_is_connected", Int32]()

def mt_tracy_sleep_ms(milliseconds: UInt32):
    external_call["mt_tracy_sleep_ms", NoneType, UInt32](milliseconds)
