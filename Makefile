# Raylib dynamic linking flags
RAYLIB_LIBS := -dynamic-linker /lib64/ld-linux-x86-64.so.2 -L./raylib/ -lc -lraylib -lm

build: rect_bounce get_keycode sprintf_float

rect_bounce: rect_bounce.asm
	fasm rect_bounce.asm rect_bounce.o
	ld -o rect_bounce rect_bounce.o $(RAYLIB_LIBS)

get_keycode: get_keycode.asm
	fasm get_keycode.asm get_keycode.o
	ld -o get_keycode get_keycode.o $(RAYLIB_LIBS)

sprintf_float: sprintf_float.asm
	fasm sprintf_float.asm sprintf_float.o
	ld -o sprintf_float sprintf_float.o $(RAYLIB_LIBS)

clean:
	rm -f rect_bounce rect_bounce.o \
				sprintf_float sprintf_float.o \
				get_keycode get_keycode.o
