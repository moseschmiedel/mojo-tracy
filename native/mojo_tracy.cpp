#include <chrono>
#include <client/tracy_rpmalloc.hpp>
#include <common/TracySystem.hpp>
#include <cstddef>
#include <cstdint>
#include <mutex>
#include <string>
#include <thread>
#include <unordered_set>

#include "tracy/Tracy.hpp"

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

using ZoneHandle = tracy::ScopedZone *;

uint64_t pack_zone_handle(ZoneHandle zone) {
  return reinterpret_cast<uint64_t>(zone);
}

ZoneHandle unpack_zone_handle(uint64_t handle) {
  return reinterpret_cast<ZoneHandle>(handle);
}

} // namespace

extern "C" {

MT_EXPORT void mt_tracy_set_thread_name(const char *name, size_t name_size) {
  auto owned_name = copy_string(name, name_size);
  tracy::SetThreadName(owned_name.c_str());
}

MT_EXPORT void mt_tracy_message(const char *text, size_t text_size,
                                uint32_t color, int32_t has_color) {
  if (text == nullptr && text_size != 0) {
    return;
  }

  if (has_color) {
    TracyMessageC(text, text_size, color);
  } else {
    TracyMessage(text, text_size);
  }
}

MT_EXPORT void mt_tracy_frame_mark() { FrameMark; }

MT_EXPORT void mt_tracy_frame_mark_named(const char *name, size_t name_size) {
  FrameMarkNamed(intern_string(name, name_size));
}

MT_EXPORT void mt_tracy_plot_f64(const char *name, size_t name_size,
                                 double value) {
  TracyPlot(intern_string(name, name_size), value);
}

MT_EXPORT void mt_tracy_plot_i64(const char *name, size_t name_size,
                                 int64_t value) {
  TracyPlot(intern_string(name, name_size), value);
}

MT_EXPORT uint64_t mt_tracy_zone_begin(const char *zone_name, size_t name_size,
                                       const char *function_name,
                                       size_t function_size,
                                       const char *file_name, size_t file_size,
                                       uint32_t line, uint32_t color,
                                       int32_t active) {
  if (zone_name == nullptr) {
    name_size = 0;
  }
  if (function_name == nullptr) {
    function_name = "";
    function_size = 0;
  }
  if (file_name == nullptr) {
    file_name = "";
    file_size = 0;
  }

  return pack_zone_handle(new tracy::ScopedZone(
      line, file_name, file_size, function_name, function_size,
      name_size == 0 ? nullptr : zone_name, name_size, color, TRACY_CALLSTACK,
      active != 0));
}

MT_EXPORT void mt_tracy_zone_end(uint64_t zone_handle) {
  delete unpack_zone_handle(zone_handle);
}

MT_EXPORT void mt_tracy_zone_text(uint64_t zone_handle, const char *text,
                                  size_t text_size) {
  auto *zone = unpack_zone_handle(zone_handle);
  if (zone == nullptr || (text == nullptr && text_size != 0)) {
    return;
  }
  zone->Text(text, text_size);
}

MT_EXPORT void mt_tracy_zone_value(uint64_t zone_handle, uint64_t value) {
  auto *zone = unpack_zone_handle(zone_handle);
  if (zone == nullptr) {
    return;
  }
  zone->Value(value);
}

MT_EXPORT int32_t mt_tracy_is_connected() { return TracyIsConnected ? 1 : 0; }

MT_EXPORT void mt_tracy_sleep_ms(uint32_t milliseconds) {
  std::this_thread::sleep_for(std::chrono::milliseconds(milliseconds));
}

} // extern "C"
