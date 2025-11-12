
format ELF64
section '.note.GNU-stack'
section '.data' writeable
; misc stuffs
color_red:   dd 0xFF0000FF
color_blue:  dd 0xFF00FF00
color_black: dd 0xFF181818
title:       db 'Raylib SIMD Demo',0,0
msg_flag:    db 'Flag START',0,0
; 
; SEGMENTFAULT :: 
; add 0 after the last string field then align 8 
; to avoid crashing when accessing SIMD data right after a db value.
; Tend to misalign 2-byte.
;
; SIMD DATA  
align 8
position :
dd 100.0
dd 100.0
dd 100.0 
dd 100.0 
velocity :
dd -200.0
dd -300.0
dd 300.0 
dd 400.0 
border :
dd 0.0
dd 0.0
dd 0.0 
dd 0.0
size :
dd 200.0
dd 200.0
dd 100.0 
dd 100.0 
zero :
dd 0.0
dd 0.0
dd 0.0 
dd 0.0 
minus_one :
dd -1.0
dd -1.0
dd -1.0 
dd -1.0
one :
dd 1.0
dd 1.0
dd 1.0 
dd 1.0 

section '.text' executable
public _start
extrn _exit
extrn printf
extrn InitWindow
extrn SetTargetFPS
extrn WindowShouldClose
extrn BeginDrawing
extrn ClearBackground
extrn GetScreenWidth
extrn GetScreenHeight
extrn GetFrameTime
extrn DrawRectangle
extrn DrawRectangleV
extrn EndDrawing
extrn CloseWindow

_start:
  mov edi, msg_flag
  call printf
    
  mov rdi, 800
  mov rsi, 600 
  mov rdx, title
  call InitWindow
    
_loop_frame:
  call WindowShouldClose
  test rax, rax
  jnz .over
  call BeginDrawing

  mov rdi, [color_black]
  call ClearBackground

  call GetScreenWidth
  mov [border],   eax
  mov [border+8], eax
  
  call GetScreenHeight
  mov [border+4],  eax
  mov [border+12], eax

  movaps   xmm0,   [border]; SIMD: move 4,8,16 aligned-pack-single float -> MMX register.
  cvtdq2ps xmm0,    xmm0   ; SIMD: Convert 4,8,16 packed doubleword integers -> single-precision floating-point values.
  movaps  [border], xmm0

  ;; next position
  call GetFrameTime
  shufps xmm0, xmm0, 0    ; SIMD: select a single-precision floating-point value of an input quadruplet & move -> dest.
  mulps  xmm0, [velocity] ; SIMD: multiply & move to dest.
  addps  xmm0, [position] ; SIMD: add.

  ;; draw 
  movq xmm0, [position]   ; SIMD: move a quadword between MMX register.
  movq xmm1, [size]
  mov rdi,   [color_red]
  call DrawRectangleV

  call EndDrawing
  jmp _loop_frame
    
.over:
  call CloseWindow
  xor rdi,rdi
  call _exit

