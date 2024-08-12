#ifdef CONFIG_DEVICE

#include <device.h>
#include <cstdint>
#include <chrono>
#include <SDL2/SDL.h>
auto time_begin = std::chrono::system_clock::now();
uint64_t get_time()
{
  auto now = std::chrono::system_clock::now();
  return (std::chrono::duration_cast<std::chrono::microseconds>(now.time_since_epoch() - time_begin.time_since_epoch())).count();

}

void device_updata()
{
  static uint64_t last = 0;
  uint64_t now = get_time();
  if (now - last < 1000000 / TIMER_HZ) {
    return;
  }
  last = now;
#ifdef CONFIG_VGA
  vga_update_screen();
#endif

  SDL_Event event;
  while (SDL_PollEvent(&event)) {
    switch (event.type) {
      case SDL_QUIT:
        exit(0);
        break;
      default: break;
    }
  }
}

void sdl_clear_event_queue() {
  SDL_Event event;
  while (SDL_PollEvent(&event));
}

#endif
