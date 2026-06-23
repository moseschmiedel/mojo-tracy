#include <cstddef>
#include <cstdint>
#include <mutex>
#include <string>
#include <unordered_set>

#include <tracy/TracyC.h>

#if defined(_WIN32)
#define MT_EXPORT __declspec(dllexport)
#else
#define MT_EXPORT __attribute__((visibility("default")))
#endif

namespace {

std::mutex g_strings_mutex;
std::unordered_set<std::string> g_strings;

std::string copy_string(const void* data, size_t size)
{
    if (data == nullptr || size == 0) {
        return {};
    }
    return std::string(static_cast<const char*>(data), size);
}

const char* intern_string(const void* data, size_t size)
{
    if (data == nullptr || size == 0) {
        return "";
    }

    std::lock_guard<std::mutex> lock(g_strings_mutex);
    auto result = g_strings.emplace(static_cast<const char*>(data), size);
    return result.first->c_str();
}

uint64_t pack_zone_context(TracyCZoneCtx ctx)
{
    return (uint64_t(uint32_t(ctx.active)) << 32) | uint64_t(ctx.id);
}

TracyCZoneCtx unpack_zone_context(uint64_t handle)
{
    TracyCZoneCtx ctx;
    ctx.id = uint32_t(handle & 0xFFFFFFFFu);
    ctx.active = int32_t(uint32_t(handle >> 32));
    return ctx;
}

} // namespace

extern "C" {

MT_EXPORT void mt_tracy_set_thread_name(const void* name, size_t name_size)
{
    auto owned_name = copy_string(name, name_size);
    ___tracy_set_thread_name(owned_name.c_str());
}

MT_EXPORT void mt_tracy_message(const void* text, size_t text_size, uint32_t color, int32_t has_color)
{
    if (text == nullptr && text_size != 0) {
        return;
    }

    const auto* bytes = static_cast<const char*>(text);
    if (has_color) {
        ___tracy_emit_messageC(bytes, text_size, color, 0);
    } else {
        ___tracy_emit_message(bytes, text_size, 0);
    }
}

MT_EXPORT void mt_tracy_frame_mark()
{
    ___tracy_emit_frame_mark(nullptr);
}

MT_EXPORT void mt_tracy_frame_mark_named(const void* name, size_t name_size)
{
    ___tracy_emit_frame_mark(intern_string(name, name_size));
}

MT_EXPORT void mt_tracy_plot_f64(const void* name, size_t name_size, double value)
{
    ___tracy_emit_plot(intern_string(name, name_size), value);
}

MT_EXPORT void mt_tracy_plot_i64(const void* name, size_t name_size, int64_t value)
{
    ___tracy_emit_plot_int(intern_string(name, name_size), value);
}

MT_EXPORT uint64_t mt_tracy_zone_begin(
    const void* name,
    size_t name_size,
    const void* function,
    size_t function_size,
    const void* file,
    size_t file_size,
    uint32_t line,
    uint32_t color,
    int32_t active)
{
    const auto* stable_name = name_size == 0 ? nullptr : intern_string(name, name_size);
    const auto* stable_function = intern_string(function, function_size);
    const auto* stable_file = intern_string(file, file_size);

    uint64_t source_location;
    if (stable_name == nullptr) {
        source_location = ___tracy_alloc_srcloc(
            line, stable_file, file_size, stable_function, function_size, color);
    } else {
        source_location = ___tracy_alloc_srcloc_name(
            line, stable_file, file_size, stable_function, function_size, stable_name, name_size, color);
    }

    return pack_zone_context(___tracy_emit_zone_begin_alloc_callstack(source_location, 0, active));
}

MT_EXPORT void mt_tracy_zone_end(uint64_t zone_handle)
{
    ___tracy_emit_zone_end(unpack_zone_context(zone_handle));
}

MT_EXPORT void mt_tracy_zone_text(uint64_t zone_handle, const void* text, size_t text_size)
{
    if (text == nullptr && text_size != 0) {
        return;
    }
    ___tracy_emit_zone_text(unpack_zone_context(zone_handle), static_cast<const char*>(text), text_size);
}

MT_EXPORT void mt_tracy_zone_value(uint64_t zone_handle, uint64_t value)
{
    ___tracy_emit_zone_value(unpack_zone_context(zone_handle), value);
}

MT_EXPORT int32_t mt_tracy_is_connected()
{
    return ___tracy_connected();
}

} // extern "C"
