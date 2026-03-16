format ELF64
include 'linux64a.inc'
section '.note.GNU-stack'
section '.data' writable
;; DATA 
title      db "convert & sprintf float in Raylib/Fasm", 0xA, 0x0
msg_none   db "Empty here.", 0xA, 0
msg_buffer rb 64
msg_fmt    db "x = %.2f",0xA,\ 
              "y = %.2f",0xA,\
              "z = %.2f",0xA,\
              "w = %.2f",0xA,0x0
;; COLOR
color_black dd 0xFF181818
color_white dd 0xFFFFFFFF
;; FRAME 
FRAMERATE     equ 120
SKIP_DURATION equ 60  ; 1 seconds
frame_skip    dd 0      ; instead of sleep.
key_pressed   dd 0

;; SIMD
align 8
simd_data:
dd 100.0
dd 1.0
dd 0.0
dd 111.1
;;
section '.text' executable
;; ENTRY 
public _start
extrn _exit
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
;; MACRO 
macro draw_text content {
  invoke DrawText, content, 100, 50, 20, qword [color_white]
}
;; ENTRY
_start:
  invoke InitWindow, 800, 400, title
  invoke SetTargetFPS, FRAMERATE

_main_loop:
  call WindowShouldClose
  test eax, eax 
  jnz _end

_render:
  call BeginDrawing

;;Background 
  invoke ClearBackground, qword [color_black]

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
  cvtss2sd xmm0, [simd_data]
  cvtss2sd xmm1, [simd_data+4]
  cvtss2sd xmm2, [simd_data+8]
  cvtss2sd xmm3, [simd_data+12]
  invoke sprintf, msg_buffer, msg_fmt

_draw_msg:
  draw_text msg_buffer

_end_render:
  call EndDrawing
  jmp _main_loop

_end:
  call CloseWindow
  xor rdi, rdi
  call _exit
