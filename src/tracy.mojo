@extern("mt_tracy_set_thread_name")
def _mt_tracy_set_thread_name(name: UnsafePointer[UInt8, ImmutAnyOrigin], name_size: UInt) abi("C") -> None:
    ...

@extern("mt_tracy_message")
def _mt_tracy_message(text: UnsafePointer[UInt8, ImmutAnyOrigin], text_size: UInt, color: UInt32, has_color: Int32) abi("C") -> None:
    ...

@extern("mt_tracy_frame_mark")
def _mt_tracy_frame_mark() abi("C") -> None:
    ...

@extern("mt_tracy_frame_mark_named")
def _mt_tracy_frame_mark_named(name: UnsafePointer[UInt8, ImmutAnyOrigin], name_size: UInt) abi("C") -> None:
    ...

@extern("mt_tracy_plot_f64")
def _mt_tracy_plot_f64(name: UnsafePointer[UInt8, ImmutAnyOrigin], name_size: UInt, value: Float64) abi("C") -> None:
    ...

@extern("mt_tracy_plot_i64")
def _mt_tracy_plot_i64(name: UnsafePointer[UInt8, ImmutAnyOrigin], name_size: UInt, value: Int64) abi("C") -> None:
    ...

@extern("mt_tracy_zone_begin")
def _mt_tracy_zone_begin(
    name: UnsafePointer[UInt8, ImmutAnyOrigin],
    name_size: UInt,
    function: UnsafePointer[UInt8, ImmutAnyOrigin],
    function_size: UInt,
    file: UnsafePointer[UInt8, ImmutAnyOrigin],
    file_size: UInt,
    line: UInt32,
    color: UInt32,
    active: Int32,
) abi("C") -> UInt64:
    ...

@extern("mt_tracy_zone_end")
def _mt_tracy_zone_end(zone_handle: UInt64) abi("C") -> None:
    ...

@extern("mt_tracy_zone_text")
def _mt_tracy_zone_text(zone_handle: UInt64, text: UnsafePointer[UInt8, ImmutAnyOrigin], text_size: UInt) abi("C") -> None:
    ...

@extern("mt_tracy_zone_value")
def _mt_tracy_zone_value(zone_handle: UInt64, value: UInt64) abi("C") -> None:
    ...

@extern("mt_tracy_is_connected")
def _mt_tracy_is_connected() abi("C") -> Int32:
    ...

def _bool_to_i32(value: Bool) -> Int32:
    if value:
        return 1
    return 0

def set_thread_name(name: String):
    var bytes = name.as_bytes()
    _mt_tracy_set_thread_name(bytes.unsafe_ptr().as_unsafe_any_origin(), UInt(name.byte_length()))

def message(text: String, color: Optional[UInt32] = None):
    var bytes = text.as_bytes()
    if color:
        _mt_tracy_message(bytes.unsafe_ptr().as_unsafe_any_origin(), UInt(text.byte_length()), color.value(), 1)
    else:
        _mt_tracy_message(bytes.unsafe_ptr().as_unsafe_any_origin(), UInt(text.byte_length()), 0, 0)

def frame_mark():
    _mt_tracy_frame_mark()

def frame_mark(name: String):
    var bytes = name.as_bytes()
    _mt_tracy_frame_mark_named(bytes.unsafe_ptr().as_unsafe_any_origin(), UInt(name.byte_length()))

def plot(name: String, value: Float64):
    var bytes = name.as_bytes()
    _mt_tracy_plot_f64(bytes.unsafe_ptr().as_unsafe_any_origin(), UInt(name.byte_length()), value)

def plot_i64(name: String, value: Int64):
    var bytes = name.as_bytes()
    _mt_tracy_plot_i64(bytes.unsafe_ptr().as_unsafe_any_origin(), UInt(name.byte_length()), value)

def is_connected() -> Bool:
    return _mt_tracy_is_connected() != 0

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
        var function: String = "mojo",
        var file: String = "mojo",
        line: UInt32 = 0,
    ):
        self.name = name^
        self.function = function^
        self.file = file^
        self.line = line
        self.color = color
        self.active = active
        self.handle = 0
        self.entered = False

    def __enter__(mut self):
        if self.entered:
            return

        var name_bytes = self.name.as_bytes()
        var function_bytes = self.function.as_bytes()
        var file_bytes = self.file.as_bytes()
        self.handle = _mt_tracy_zone_begin(
            name_bytes.unsafe_ptr().as_unsafe_any_origin(),
            UInt(self.name.byte_length()),
            function_bytes.unsafe_ptr().as_unsafe_any_origin(),
            UInt(self.function.byte_length()),
            file_bytes.unsafe_ptr().as_unsafe_any_origin(),
            UInt(self.file.byte_length()),
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

        var bytes = text.as_bytes()
        _mt_tracy_zone_text(self.handle, bytes.unsafe_ptr().as_unsafe_any_origin(), UInt(text.byte_length()))

    def value(mut self, value: UInt64):
        if not self.entered:
            return

        _mt_tracy_zone_value(self.handle, value)
