#include <am.h>
#include <ysyxsoc.h>

void __am_gpu_init() {
  /*
  int i;
  int w = inw(VGACTL_ADDR + 2);  // TODO: get the correct width
  int h = inw(VGACTL_ADDR);  // TODO: get the correct height
  uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;
  for (i = 0; i < w * h; i ++) fb[i] = i;
  outl(SYNC_ADDR, 1);*/
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = 640, .height = 480,
    .vmemsz = 0
  };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
    int w = ctl->w;
    int h = ctl->h;
    int x = ctl->x;
    int y = ctl->y;

   uint32_t fw = 640;
    for(int i = y; i < h + y; i++){
      for(int j = x; j < w + x; j++){
        outl(FB_ADDR+(i*fw+j)*4, ((uint32_t*)(ctl->pixels))[(i-y)*w+j-x]);
      }
    }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
