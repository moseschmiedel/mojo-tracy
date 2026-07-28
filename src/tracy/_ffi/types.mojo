comptime MtString = UnsafePointer[UInt8, ImmUntrackedOrigin]


def string_to_mt_string(str: String) -> Tuple[MtString, UInt]:
    return {
        rebind[MtString](str.unsafe_ptr().as_imm()),
        UInt(str.byte_length()),
    }


def bool_to_i32(value: Bool) -> Int32:
    if value:
        return 1
    return 0
