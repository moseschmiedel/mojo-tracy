comptime MtString = UnsafePointer[UInt8, ImmutUntrackedOrigin]

def string_to_mt_string(str: String) -> Tuple[MtString, UInt]:
    return {
        rebind[MtString](str.unsafe_ptr().as_immutable()),
        UInt(str.byte_length())
    }
