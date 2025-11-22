# Raylib dynamic linking flags
RAYLIB_LIBS := -dynamic-linker /lib64/ld-linux-x86-64.so.2 -L./raylib/ -lc -lraylib -lm

rect_bounce: rect_bounce.asm
	fasm rect_bounce.asm rect_bounce.o
	ld -o rect_bounce rect_bounce.o $(RAYLIB_LIBS)

get_keycode: get_keycode.asm
	fasm get_keycode.asm get_keycode.o
	ld -o get_keycode get_keycode.o $(RAYLIB_LIBS)

clean:
	rm -f rect_bounce rect_bounce.o \
				get_keycode get_keycode.o
