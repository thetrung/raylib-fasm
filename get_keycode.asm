format ELF64
section '.note.GNU-stack'
section '.data' writable
;; DATA 
title: db "Get KeyCode in Raylib/Fasm", 0xA, 0x0
msg_none: db "Empty here.", 0xA, 0
msg_buffer: rb 64
msg_pressed: db "Pressed keycode %d (skip %d frames)", 0xA,0
;; COLOR
color_black: dd 0xFF181818
color_white: dd 0xFFFFFFFF
;; FRAME 
FRAMERATE equ 120
frame_skip: dd 0      ; instead of sleep.
SKIP_DURATION equ 60  ; 1 seconds
;; KEY 
key_pressed: dd 0

;; SIMD
align 8
;;
section '.text' executable
;; ENTRY 
public _start
extrn _exit
;; DEBUG
;;public _skip
;; LIB64
extrn sprintf
;;WINDOW
extrn InitWindow
extrn CloseWindow
extrn SetTargetFPS
extrn WindowShouldClose
extrn ClearBackground
extrn BeginDrawing
extrn DrawText
extrn EndDrawing
;; INPUT
extrn GetKeyPressed

macro draw_text content {
  ;; Text 
  ;xor rax, rax            ;clear return reg 
  mov rdi, content        ;*text
  mov rsi, 100            ;posX
  mov rdx, 50             ;posY
  mov rcx, 20             ;font-size
  mov r8,  [color_white]  ;color
  call DrawText
}

_start:
  mov rdi, 800
  mov rsi, 600
  mov rdx, title
  call InitWindow

;; FPS 
  mov rdi, FRAMERATE
  call SetTargetFPS

_main_loop:
  call WindowShouldClose
  test eax, eax 
  jnz _end

_render:
  call BeginDrawing

;;Background 
  mov rdi, [color_black]
  call ClearBackground

;;Frame Skip :          ; stay inside Begin/EndDrawing() to work.
  mov eax, [frame_skip] ; eax = 32bit, dd = 4-bytes, db = 1-byte.
  test eax, eax         ; frame_skip == 0 ? 
  jz _get_key           ; continue !

_skip:
  dec eax               
  mov [frame_skip], eax ; frame_skip--
  jmp _format_key

_get_key: 
  call GetKeyPressed     ; Check Key
  mov [key_pressed], eax ; save the value.
  test eax, eax
  jnz _enable_skip

_empty_buffer:
  draw_text msg_none
  jmp _end_render
  
_enable_skip: 
  mov eax, SKIP_DURATION
  mov [frame_skip], eax

  _format_key:          ;format int -> msg 
  mov edi, msg_buffer   ;outbuf
  mov esi, msg_pressed  ;const char*
  mov edx, [key_pressed];arg0: keycode
  mov ecx, [frame_skip] ;arg1: frame_skip
  call sprintf

_draw_msg:
  draw_text msg_buffer

_end_render:
  call EndDrawing
  jmp _main_loop

_end:
  call CloseWindow
  xor rdi, rdi
  call _exit
