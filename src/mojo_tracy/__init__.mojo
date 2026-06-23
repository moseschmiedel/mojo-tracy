from std.reflection import call_location, reflect_fn
from .ffi_types import string_to_mt_string, bool_to_i32
from . import _tracy_ffi

def set_thread_name(name: String):
    var mt_string, mt_string_length = string_to_mt_string(name)
    _tracy_ffi.mt_tracy_set_thread_name(mt_string, mt_string_length)

def message(text: String, color: Optional[UInt32] = None):
    var mt_string, mt_string_length = string_to_mt_string(text)
    if color:
        _tracy_ffi.mt_tracy_message(mt_string, mt_string_length, color.value(), 1)
    else:
        _tracy_ffi.mt_tracy_message(mt_string, mt_string_length, 0, 0)

def frame_mark():
    _tracy_ffi.mt_tracy_frame_mark()

def frame_mark(name: String):
    var mt_string, mt_string_length = string_to_mt_string(name)
    _tracy_ffi.mt_tracy_frame_mark_named(mt_string, mt_string_length)

def plot(name: String, value: Float64):
    var mt_string, mt_string_length = string_to_mt_string(name)
    _tracy_ffi.mt_tracy_plot_f64(mt_string, mt_string_length, value)

def plot(name: String, value: Int64):
    var mt_string, mt_string_length = string_to_mt_string(name)
    _tracy_ffi.mt_tracy_plot_i64(mt_string, mt_string_length, value)

def is_connected() -> Bool:
    return _tracy_ffi.mt_tracy_is_connected() != 0

def sleep_ms(milliseconds: UInt32):
    _tracy_ffi.mt_tracy_sleep_ms(milliseconds)

def wait_for_connection(timeout_ms: UInt32 = 5000, poll_ms: UInt32 = 100) -> Bool:
    var waited: UInt32 = 0
    while waited < timeout_ms:
        if is_connected():
            return True

        sleep_ms(poll_ms)
        waited += poll_ms

    return is_connected()

struct FunctionZone[func_type: AnyType, //, func: func_type](Movable):
    var function: String
    var file: String
    var line: UInt32
    var color: UInt32
    var active: Bool
    var handle: UInt64
    var entered: Bool

    @always_inline
    def __init__(
        out self,
        color: UInt32 = 0,
        active: Bool = True,
    ):
        self.function = reflect_fn[Self.func].linkage_name()

        var loc = call_location()
        self.file = String(loc.file_name())
        self.line = UInt32(loc.line())
        self.color = color
        self.active = active
        self.handle = 0
        self.entered = False

    def __enter__(mut self):
        if self.entered:
            return

        var function_string, function_string_length = string_to_mt_string(self.function)
        var file_string, file_string_length = string_to_mt_string(self.file)
        self.handle = _tracy_ffi.mt_tracy_zone_begin(
            function_string,
            0,
            function_string,
            function_string_length,
            file_string,
            file_string_length,
            self.line,
            self.color,
            bool_to_i32(self.active),
        )
        self.entered = True

    def __exit__(mut self):
        self.end()

    def __del__(deinit self):
        self.end()

    def end(mut self):
        if not self.entered:
            return

        _tracy_ffi.mt_tracy_zone_end(self.handle)
        self.handle = 0
        self.entered = False

    def text(mut self, text: String):
        if not self.entered:
            return

        var mt_string, mt_string_length = string_to_mt_string(text)
        _tracy_ffi.mt_tracy_zone_text(self.handle, mt_string, mt_string_length)

    def value(mut self, value: UInt64):
        if not self.entered:
            return

        _tracy_ffi.mt_tracy_zone_value(self.handle, value)
