#ifdef CONFIG_DEVICE

#include <cstdint>
#include <cstring>
#include <cstdlib>
#include <device.h>

static uint32_t screen_width() {
  return WIDTH;
}

static uint32_t screen_height() {
  return HEIGHT;
}

static uint32_t screen_size() {
  return screen_width() * screen_height() * sizeof(uint32_t);
}

void *vmem = NULL;
int write_sync = 0;

#include <SDL2/SDL.h>

static SDL_Renderer *renderer = NULL;
static SDL_Texture *texture = NULL;

static void init_screen() {
  SDL_Window *window = NULL;
  char title[128];
  sprintf(title, "riscve-npc");
  SDL_Init(SDL_INIT_VIDEO);
  SDL_CreateWindowAndRenderer(
      WIDTH,
      HEIGHT,
      0, &window, &renderer);
  SDL_SetWindowTitle(window, title);
  texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888,
      SDL_TEXTUREACCESS_STATIC, WIDTH, HEIGHT);
  SDL_RenderPresent(renderer);
}

static inline void update_screen() {
  SDL_UpdateTexture(texture, NULL, vmem, WIDTH * sizeof(uint32_t));
  SDL_RenderClear(renderer);
  SDL_RenderCopy(renderer, texture, NULL, NULL);
  SDL_RenderPresent(renderer);
}
void vga_update_screen() {
  if(write_sync == 1){
    update_screen();
  }
  // TODO: call `update_screen()` when the sync register is non-zero,
  // then zero out the sync register
}

void init_vga() {
  
  vmem = malloc(screen_size());
  init_screen();
  memset(vmem, 0, screen_size());
}
#endif
