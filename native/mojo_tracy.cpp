#include <chrono>
#include <cstddef>
#include <cstdint>
#include <mutex>
#include <string>
#include <thread>
#include <unordered_set>

#include <tracy/TracyC.h>

#if defined(_WIN32)
#define MT_EXPORT __declspec(dllexport)
#else
#define MT_EXPORT __attribute__((visibility("default")))
#endif

namespace {

struct g_string_storage_t {
  std::mutex mutex;
  std::unordered_set<std::string> data;
};

static g_string_storage_t g_string_storage;

/**
 * Copies `size` amount of bytes from `data` into a `std::string`.
 *
 * @param data The buffer of bytes to copy from. Null-termination not needed.
 * @param size The amount of bytes to be copied from `data`.
 * @return The copied string as a std::string.
 */
std::string copy_string(const char *data, size_t size) {
  if (data == nullptr || size == 0) {
    return {};
  }
  return std::string(data, size);
}

/**
 * Internalizes `size` amount of bytes from `data` into a `std::string` stored
 * in the global string storage `g_string_storage`.
 */
const char *intern_string(const char *data, size_t size) {
  if (data == nullptr || size == 0) {
    return "";
  }

  std::lock_guard<std::mutex> lock(g_string_storage.mutex);
  auto result = g_string_storage.data.emplace(data, size);
  return result.first->c_str();
}

uint64_t pack_zone_context(TracyCZoneCtx ctx) {
  return (uint64_t(uint32_t(ctx.active)) << 32) | uint64_t(ctx.id);
}

TracyCZoneCtx unpack_zone_context(uint64_t handle) {
  TracyCZoneCtx ctx;
  ctx.id = uint32_t(handle & 0xFFFFFFFFu);
  ctx.active = int32_t(uint32_t(handle >> 32));
  return ctx;
}

} // namespace

extern "C" {

MT_EXPORT void mt_tracy_set_thread_name(const char *name, size_t name_size) {
  auto owned_name = copy_string(name, name_size);
  ___tracy_set_thread_name(owned_name.c_str());
}

MT_EXPORT void mt_tracy_message(const char *text, size_t text_size,
                                uint32_t color, int32_t has_color) {
  if (text == nullptr && text_size != 0) {
    return;
  }

  if (has_color) {
    ___tracy_emit_messageC(text, text_size, color, 0);
  } else {
    ___tracy_emit_message(text, text_size, 0);
  }
}

MT_EXPORT void mt_tracy_frame_mark() { ___tracy_emit_frame_mark(nullptr); }

MT_EXPORT void mt_tracy_frame_mark_named(const char *name, size_t name_size) {
  ___tracy_emit_frame_mark(intern_string(name, name_size));
}

MT_EXPORT void mt_tracy_plot_f64(const char *name, size_t name_size,
                                 double value) {
  ___tracy_emit_plot(intern_string(name, name_size), value);
}

MT_EXPORT void mt_tracy_plot_i64(const char *name, size_t name_size,
                                 int64_t value) {
  ___tracy_emit_plot_int(intern_string(name, name_size), value);
}

MT_EXPORT uint64_t mt_tracy_zone_begin(const char *zone_name, size_t name_size,
                                       const char *function_name,
                                       size_t function_size,
                                       const char *file_name, size_t file_size,
                                       uint32_t line, uint32_t color,
                                       int32_t active) {
  const auto *stable_zone_name =
      name_size == 0 ? nullptr : intern_string(zone_name, name_size);
  const auto *stable_function_name =
      intern_string(function_name, function_size);
  const auto *stable_file_name = intern_string(file_name, file_size);

  uint64_t source_location;
  if (stable_zone_name == nullptr) {
    source_location =
        ___tracy_alloc_srcloc(line, stable_file_name, file_size,
                              stable_function_name, function_size, color);
  } else {
    source_location = ___tracy_alloc_srcloc_name(
        line, stable_file_name, file_size, stable_function_name, function_size,
        stable_zone_name, name_size, color);
  }

  return pack_zone_context(
      ___tracy_emit_zone_begin_alloc_callstack(source_location, 0, active));
}

MT_EXPORT void mt_tracy_zone_end(uint64_t zone_handle) {
  ___tracy_emit_zone_end(unpack_zone_context(zone_handle));
}

MT_EXPORT void mt_tracy_zone_text(uint64_t zone_handle, const char *text,
                                  size_t text_size) {
  if (text == nullptr && text_size != 0) {
    return;
  }
  ___tracy_emit_zone_text(unpack_zone_context(zone_handle), text, text_size);
}

MT_EXPORT void mt_tracy_zone_value(uint64_t zone_handle, uint64_t value) {
  ___tracy_emit_zone_value(unpack_zone_context(zone_handle), value);
}

MT_EXPORT int32_t mt_tracy_is_connected() { return ___tracy_connected(); }

MT_EXPORT void mt_tracy_sleep_ms(uint32_t milliseconds) {
  std::this_thread::sleep_for(std::chrono::milliseconds(milliseconds));
}

} // extern "C"
