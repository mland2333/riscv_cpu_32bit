#ifdef CONFIG_DEVICE

#include <cstdint>
#include <cstring>
#include <cstdlib>
#include <device.h>

//#define SCREEN_W (MUXDEF(CONFIG_VGA_SIZE_800x600, 800, 400))
//#define SCREEN_H (MUXDEF(CONFIG_VGA_SIZE_800x600, 600, 300))

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
//static uint32_t *vgactl_port_base = NULL;

/*#ifdef CONFIG_VGA_SHOW_SCREEN
#ifndef CONFIG_TARGET_AM*/
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
/*#else
static void init_screen() {}

static inline void update_screen() {
  io_write(AM_GPU_FBDRAW, 0, 0, vmem, screen_width(), screen_height(), true);
}
#endif
#endif*/

void vga_update_screen() {
  if(write_sync == 1){
    update_screen();
  }
  // TODO: call `update_screen()` when the sync register is non-zero,
  // then zero out the sync register
}

void init_vga() {
  //vgactl_port_base = (uint32_t *)malloc(8);
  //vgactl_port_base[0] = (screen_width() << 16) | screen_height();
/*#ifdef CONFIG_HAS_PORT_IO
  add_pio_map ("vgactl", CONFIG_VGA_CTL_PORT, vgactl_port_base, 8, NULL);
#else
  add_mmio_map("vgactl", CONFIG_VGA_CTL_MMIO, vgactl_port_base, 8, NULL);
#endif*/

  vmem = malloc(screen_size());
  //add_mmio_map("vmem", CONFIG_FB_ADDR, vmem, screen_size(), NULL);
  init_screen();
  memset(vmem, 0, screen_size());
}
#endif
