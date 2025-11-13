
SRC = game.asm
OBJ = game.o
BIN = game

# Raylib dynamic linking flags
RAYLIB_LIBS := -dynamic-linker /lib64/ld-linux-x86-64.so.2 -L./raylib/ -lc -lraylib -lm

$(BIN): $(SRC)
	fasm $(SRC) $(OBJ)
	ld -o $(BIN) $(OBJ) $(RAYLIB_LIBS)

run: $(BIN)
	./$(BIN)

clean:
	rm -f $(OBJ) $(BIN)
