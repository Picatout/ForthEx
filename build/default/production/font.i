# 1 "font.c"
# 1 "/home/jacques/MPLABXProjects/ForthEx.X//"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "font.c"

# 1 "font.h" 1
# 3 "font.c" 2

const unsigned char font[(101)*(8)]={
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x20,0x20,0x20,0x20,0x20,0x00,0x20,0x00,
0x50,0x50,0x50,0x00,0x00,0x00,0x00,0x00,
0x50,0x50,0xF8,0x50,0xF8,0x50,0x50,0x00,
0x20,0x78,0xA0,0x70,0x28,0xF0,0x20,0x00,
0xC0,0xC8,0x10,0x20,0x40,0x98,0x18,0x00,
0x60,0x90,0xA0,0x40,0xA8,0x90,0x68,0x00,
0x60,0x20,0x40,0x00,0x00,0x00,0x00,0x00,
0x10,0x20,0x40,0x40,0x40,0x20,0x10,0x00,
0x40,0x20,0x10,0x10,0x10,0x20,0x40,0x00,
0x00,0x20,0xA8,0x70,0xA8,0x20,0x00,0x00,
0x00,0x20,0x20,0xF8,0x20,0x20,0x00,0x00,
0x00,0x00,0x00,0x00,0x60,0x20,0x40,0x00,
0x00,0x00,0x00,0xF0,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x60,0x60,0x00,
0x00,0x08,0x10,0x20,0x40,0x80,0x00,0x00,
0x70,0x88,0x98,0xA8,0xC8,0x88,0x70,0x00,
0x20,0x60,0x20,0x20,0x20,0x20,0xF8,0x00,
0x70,0x88,0x10,0x20,0x40,0x80,0xF8,0x00,
0xF0,0x08,0x08,0xF0,0x08,0x08,0xF0,0x00,
0x10,0x30,0x50,0x90,0xF8,0x10,0x10,0x00,
0xF8,0x80,0x80,0xF0,0x08,0x08,0xF0,0x00,
0x30,0x40,0x80,0xF0,0x88,0x88,0x70,0x00,
0xF8,0x08,0x10,0x20,0x40,0x40,0x40,0x00,
0x70,0x88,0x88,0x70,0x88,0x88,0x70,0x00,
0x70,0x88,0x88,0x70,0x08,0x08,0x70,0x00,
0x00,0x60,0x60,0x00,0x60,0x60,0x00,0x00,
0x00,0x60,0x60,0x00,0x60,0x20,0x40,0x00,
0x10,0x20,0x40,0x80,0x40,0x20,0x10,0x00,
0x00,0x00,0xF8,0x00,0xF8,0x00,0x00,0x00,
0x40,0x20,0x10,0x08,0x10,0x20,0x40,0x00,
0x70,0x88,0x08,0x10,0x20,0x00,0x20,0x00,
0x70,0x88,0x08,0x68,0xA8,0xA8,0x70,0x00,
0x70,0x88,0x88,0xF8,0x88,0x88,0x88,0x00,
0xF0,0x88,0x88,0xF0,0x88,0x88,0xF0,0x00,
0x78,0x80,0x80,0x80,0x80,0x80,0x78,0x00,
0xF0,0x88,0x88,0x88,0x88,0x88,0xF0,0x00,
0xF8,0x80,0x80,0xF8,0x80,0x80,0xF8,0x00,
0xF8,0x80,0x80,0xF8,0x80,0x80,0x80,0x00,
0x78,0x80,0x80,0xB0,0x88,0x88,0x70,0x00,
0x88,0x88,0x88,0xF8,0x88,0x88,0x88,0x00,
0x70,0x20,0x20,0x20,0x20,0x20,0x70,0x00,
0x78,0x08,0x08,0x08,0x08,0x90,0x60,0x00,
0x88,0x90,0xA0,0xC0,0xA0,0x90,0x88,0x00,
0x80,0x80,0x80,0x80,0x80,0x80,0xF8,0x00,
0x88,0xD8,0xA8,0x88,0x88,0x88,0x88,0x00,
0x88,0x88,0xC8,0xA8,0x98,0x88,0x88,0x00,
0x70,0x88,0x88,0x88,0x88,0x88,0x70,0x00,
0xF0,0x88,0x88,0xF0,0x80,0x80,0x80,0x00,
0x70,0x88,0x88,0x88,0xA8,0x98,0x78,0x00,
0xF0,0x88,0x88,0xF0,0xA0,0x90,0x88,0x00,
0x78,0x80,0x80,0x70,0x08,0x08,0xF0,0x00,
0xF8,0x20,0x20,0x20,0x20,0x20,0x20,0x00,
0x88,0x88,0x88,0x88,0x88,0x88,0x70,0x00,
0x88,0x88,0x88,0x88,0x88,0x50,0x20,0x00,
0x88,0x88,0x88,0xA8,0xA8,0xD8,0x88,0x00,
0x88,0x88,0x50,0x20,0x50,0x88,0x88,0x00,
0x88,0x88,0x88,0x50,0x20,0x20,0x20,0x00,
0xF8,0x10,0x20,0x40,0x80,0x80,0xF8,0x00,
0x60,0x40,0x40,0x40,0x40,0x40,0x60,0x00,
0x00,0x80,0x40,0x20,0x10,0x08,0x00,0x00,
0x18,0x08,0x08,0x08,0x08,0x08,0x18,0x00,
0x20,0x50,0x88,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xF8,
0x40,0x20,0x10,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x70,0x08,0x78,0x88,0x78,0x00,
0x80,0x80,0x80,0xB0,0xC8,0x88,0xF0,0x00,
0x00,0x00,0x70,0x80,0x80,0x88,0x70,0x00,
0x08,0x08,0x08,0x68,0x98,0x88,0x78,0x00,
0x00,0x00,0x70,0x88,0xF8,0x80,0x70,0x00,
0x30,0x48,0x40,0xE0,0x40,0x40,0x40,0x00,
0x00,0x00,0x78,0x88,0x88,0x78,0x08,0x70,
0x80,0x80,0xB0,0xC8,0x88,0x88,0x88,0x00,
0x00,0x20,0x00,0x20,0x20,0x20,0x20,0x00,
0x10,0x00,0x30,0x10,0x10,0x90,0x60,0x00,
0x80,0x80,0x90,0xA0,0xC0,0xA0,0x90,0x00,
0x60,0x20,0x20,0x20,0x20,0x20,0x70,0x00,
0x00,0x00,0xD0,0xA8,0xA8,0x88,0x88,0x00,
0x00,0x00,0xB0,0xC8,0x88,0x88,0x88,0x00,
0x00,0x00,0x70,0x88,0x88,0x88,0x70,0x00,
0x00,0x00,0xF0,0x88,0x88,0xF0,0x80,0x80,
0x00,0x00,0x68,0x90,0x90,0xB0,0x50,0x18,
0x00,0x00,0xB0,0xC8,0x80,0x80,0x80,0x00,
0x00,0x00,0x70,0x80,0x70,0x08,0xF0,0x00,
0x40,0x40,0xE0,0x40,0x40,0x48,0x30,0x00,
0x00,0x00,0x88,0x88,0x88,0x98,0x68,0x00,
0x00,0x00,0x88,0x88,0x88,0x50,0x20,0x00,
0x00,0x00,0x88,0x88,0xA8,0xA8,0x50,0x00,
0x00,0x00,0x88,0x50,0x20,0x50,0x88,0x00,
0x00,0x00,0x88,0x88,0x88,0x78,0x08,0x70,
0x00,0x00,0xF8,0x10,0x20,0x40,0xF8,0x00,
0x20,0x40,0x40,0x80,0x40,0x40,0x20,0x00,
0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x00,
0x40,0x20,0x20,0x10,0x20,0x20,0x40,0x00,
0x00,0x00,0x40,0xA8,0x10,0x00,0x00,0x00,
0xFC,0xFC,0xFC,0xFC,0xFC,0xFC,0xFC,0xFC,
0x40,0x20,0x10,0xF8,0x10,0x20,0x40,0x00,
0x10,0x20,0x40,0xF8,0x40,0x20,0x10,0x00,
0x20,0x70,0xA8,0x20,0x20,0x20,0x00,0x00,
0x00,0x20,0x20,0x20,0xA8,0x70,0x20,0x00,
0x00,0x70,0xF8,0xF8,0xF8,0x70,0x00,0x00,
};
