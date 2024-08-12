#include <am.h>
#include <stdio.h>
#include <ysyxsoc.h>
#define KEYEX_MASK 0x80
static bool is_down = true;
static bool is_extern = false;

#define MAP(c, f) c(f)

#define AM_SCANCODE(_) \
  _(ESCAPE, 0x76) _(F1, 0x05) _(F2, 0x06) _(F3, 0x04) _(F4, 0x0C) _(F5, 0x03) _(F6, 0x0B) _(F7, 0x83) _(F8, 0x0A) _(F9, 0x01) _(F10, 0x09) _(F11, 0x78) _(F12, 0x07) \
  _(GRAVE, 0x0E) _(1, 0x16) _(2, 0x1E) _(3, 0x26) _(4, 0x25) _(5, 0x2E) _(6, 0x36) _(7, 0x3D) _(8, 0x3E) _(9, 0x46) _(0, 0x45) _(MINUS, 0x4E) _(EQUALS, 0x55) _(BACKSPACE, 0x66) \
  _(TAB, 0x0D) _(Q, 0x15) _(W, 0x1D) _(E, 0x24) _(R, 0x2D) _(T, 0x2C) _(Y, 0x35) _(U, 0x3C) _(I, 0x43) _(O, 0x44) _(P, 0x4D) _(LEFTBRACKET, 0x54) _(RIGHTBRACKET, 0x5B) _(BACKSLASH, 0x5D) \
  _(CAPSLOCK, 0x58) _(A, 0x1C) _(S, 0x1B) _(D, 0x23) _(F, 0x2B) _(G, 0x34) _(H, 0x33) _(J, 0x3B) _(K, 0x42) _(L, 0x4B) _(SEMICOLON, 0x4C) _(APOSTROPHE, 0x52) _(RETURN, 0x5A) \
  _(LSHIFT, 0x12) _(Z, 0x1A) _(X, 0x22) _(C, 0x21) _(V, 0x2A) _(B, 0x32) _(N, 0x31) _(M, 0x3A) _(COMMA, 0x41) _(PERIOD, 0x49) _(SLASH, 0x4A) _(RSHIFT, 0x59) \
  _(LCTRL, 0x14) _(APPLICATION, 0xE0) _(LALT, 0x11) _(SPACE, 0x29) _(RALT, 0x91) _(RCTRL, 0x94) \
  _(UP, 0xF5) _(DOWN, 0xF2) _(LEFT, 0xEB) _(RIGHT, 0xF4) _(INSERT, 0xF0) _(DELETE, 0xF1) _(HOME, 0xEC) _(END, 0xE9) _(PAGEUP, 0xFD) _(PAGEDOWN, 0xFA)

#define AM_SCANCODE_MAP(a, b) AM_SCANCODE_ ## a = b,

enum {
  AM_SCAMCODE_NONE = 0,
  MAP(AM_SCANCODE, AM_SCANCODE_MAP)
};

#define AM_KEYMAP(k) keymap[AM_SCANCODE_ ## k] = AM_KEY_ ## k;

static uint32_t keymap[256] = {};
void init_keymap() {
  MAP(AM_KEYS, AM_KEYMAP)
}
void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  char code = inb(KBD_ADDR);
  if (code == 0xf0) {
    kbd->keycode = AM_KEY_NONE;
    is_down = false;
    return;
  }
  else if(code == 0xe0){
    kbd->keycode = AM_KEY_NONE;
    is_extern = true;
    return;
  }
  else if(code == 0){
    kbd->keycode = AM_KEY_NONE;
    return;
  }
  int code1 = is_extern ? (int)code | KEYEX_MASK : (int)code;
  // if(code!=0) printf("inl:%x", code);
  kbd->keydown = is_down;
  kbd->keycode = keymap[code1];
  is_down = true;
  is_extern = false;
}

void __am_uart_rx(AM_UART_RX_T *rx) { rx->data = getch(); }

void __am_uart_tx(AM_UART_TX_T *tx) { putch(tx->data); }
