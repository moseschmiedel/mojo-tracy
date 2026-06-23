from std.ffi import external_call
from ffi_types import MtString, string_to_mt_string

def _mt_tracy_set_thread_name(name: MtString, name_size: UInt):
    external_call["mt_tracy_set_thread_name", NoneType, MtString, UInt](name, name_size)

def _mt_tracy_message(text: MtString, text_size: UInt, color: UInt32, has_color: Int32):
    external_call["mt_tracy_message", NoneType, MtString, UInt, UInt32, Int32](
        text, text_size, color, has_color
    )

def _mt_tracy_frame_mark():
    external_call["mt_tracy_frame_mark", NoneType]()

def _mt_tracy_frame_mark_named(name: MtString, name_size: UInt):
    external_call["mt_tracy_frame_mark_named", NoneType, MtString, UInt](name, name_size)

def _mt_tracy_plot_f64(name: MtString, name_size: UInt, value: Float64):
    external_call["mt_tracy_plot_f64", NoneType, MtString, UInt, Float64](
        name, name_size, value
    )

def _mt_tracy_plot_i64(name: MtString, name_size: UInt, value: Int64):
    external_call["mt_tracy_plot_i64", NoneType, MtString, UInt, Int64](
        name, name_size, value
    )

def _mt_tracy_zone_begin(
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

def _mt_tracy_zone_end(zone_handle: UInt64):
    external_call["mt_tracy_zone_end", NoneType, UInt64](zone_handle)

def _mt_tracy_zone_text(zone_handle: UInt64, text: MtString, text_size: UInt):
    external_call["mt_tracy_zone_text", NoneType, UInt64, MtString, UInt](
        zone_handle, text, text_size
    )

def _mt_tracy_zone_value(zone_handle: UInt64, value: UInt64):
    external_call["mt_tracy_zone_value", NoneType, UInt64, UInt64](zone_handle, value)

def _mt_tracy_is_connected() -> Int32:
    return external_call["mt_tracy_is_connected", Int32]()

def _mt_tracy_sleep_ms(milliseconds: UInt32):
    external_call["mt_tracy_sleep_ms", NoneType, UInt32](milliseconds)

def _bool_to_i32(value: Bool) -> Int32:
    if value:
        return 1
    return 0

def set_thread_name(name: String):
    var mt_string, mt_string_length = string_to_mt_string(name)
    _mt_tracy_set_thread_name(mt_string, mt_string_length)

def message(text: String, color: Optional[UInt32] = None):
    var mt_string, mt_string_length = string_to_mt_string(text)
    if color:
        _mt_tracy_message(mt_string, mt_string_length, color.value(), 1)
    else:
        _mt_tracy_message(mt_string, mt_string_length, 0, 0)

def frame_mark():
    _mt_tracy_frame_mark()

def frame_mark(name: String):
    var mt_string, mt_string_length = string_to_mt_string(name)
    _mt_tracy_frame_mark_named(mt_string, mt_string_length)

def plot(name: String, value: Float64):
    var mt_string, mt_string_length = string_to_mt_string(name)
    _mt_tracy_plot_f64(mt_string, mt_string_length, value)

def plot_i64(name: String, value: Int64):
    var mt_string, mt_string_length = string_to_mt_string(name)
    _mt_tracy_plot_i64(mt_string, mt_string_length, value)

def is_connected() -> Bool:
    return _mt_tracy_is_connected() != 0

def sleep_ms(milliseconds: UInt32):
    _mt_tracy_sleep_ms(milliseconds)

def wait_for_connection(timeout_ms: UInt32 = 5000, poll_ms: UInt32 = 100) -> Bool:
    var waited: UInt32 = 0
    while waited < timeout_ms:
        if is_connected():
            return True

        sleep_ms(poll_ms)
        waited += poll_ms

    return is_connected()

struct Zone(Movable):
    var name: String
    var function: String
    var file: String
    var line: UInt32
    var color: UInt32
    var active: Bool
    var handle: UInt64
    var entered: Bool

    def __init__(
        out self,
        var name: String,
        color: UInt32 = 0,
        active: Bool = True,
        var function_name: String = "mojo",
        var file: String = "mojo",
        line: UInt32 = 0,
    ):
        self.name = name^
        self.function = function_name^
        self.file = file^
        self.line = line
        self.color = color
        self.active = active
        self.handle = 0
        self.entered = False

    def __enter__(mut self):
        if self.entered:
            return

        var name_string, name_string_length = string_to_mt_string(self.name)
        var function_string, function_string_length = string_to_mt_string(self.function)
        var file_string, file_string_length = string_to_mt_string(self.file)
        self.handle = _mt_tracy_zone_begin(
            name_string,
            name_string_length,
            function_string,
            function_string_length,
            file_string,
            file_string_length,
            self.line,
            self.color,
            _bool_to_i32(self.active),
        )
        self.entered = True

    def __exit__(mut self):
        self.end()

    def __del__(deinit self):
        if self.entered:
            _mt_tracy_zone_end(self.handle)

    def end(mut self):
        if not self.entered:
            return

        _mt_tracy_zone_end(self.handle)
        self.handle = 0
        self.entered = False

    def text(mut self, text: String):
        if not self.entered:
            return

        var mt_string, mt_string_length = string_to_mt_string(text)
        _mt_tracy_zone_text(self.handle, mt_string, mt_string_length)

    def value(mut self, value: UInt64):
        if not self.entered:
            return

        _mt_tracy_zone_value(self.handle, value)

struct FunctionZone(Movable):
    var function: String
    var file: String
    var line: UInt32
    var color: UInt32
    var active: Bool
    var handle: UInt64
    var entered: Bool

    def __init__(
        out self,
        var function_name: String,
        color: UInt32 = 0,
        active: Bool = True,
        var file: String = "mojo",
        line: UInt32 = 0,
    ):
        self.function = function_name^
        self.file = file^
        self.line = line
        self.color = color
        self.active = active
        self.handle = 0
        self.entered = False

    def __enter__(mut self):
        if self.entered:
            return

        var function_string, function_string_length = string_to_mt_string(self.function)
        var file_string, file_string_length = string_to_mt_string(self.file)
        self.handle = _mt_tracy_zone_begin(
            function_string,
            0,
            function_string,
            function_string_length,
            file_string,
            file_string_length,
            self.line,
            self.color,
            _bool_to_i32(self.active),
        )
        self.entered = True

    def __exit__(mut self):
        self.end()

    def __del__(deinit self):
        if self.entered:
            _mt_tracy_zone_end(self.handle)

    def end(mut self):
        if not self.entered:
            return

        _mt_tracy_zone_end(self.handle)
        self.handle = 0
        self.entered = False

    def text(mut self, text: String):
        if not self.entered:
            return

        var mt_string, mt_string_length = string_to_mt_string(text)
        _mt_tracy_zone_text(self.handle, mt_string, mt_string_length)

    def value(mut self, value: UInt64):
        if not self.entered:
            return

        _mt_tracy_zone_value(self.handle, value)
