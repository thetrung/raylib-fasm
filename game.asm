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
public loop_frame
public got_border
public cmp_rect_zero
public cmp_rect_border
public orps_xmm1_xmm2
public converted_bitmasks_to_float32
public mul_xmm1_minus_one
public new_position
public vector_result
public neg_position_xmm3
public mul_xmm4_xmm2
public updated_position
public updated_vector

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

loop_frame:
  call WindowShouldClose
  test rax, rax
  jnz over
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
got_border:

  ;; next position :      ; p' = p + v * dt
  call GetFrameTime 
  shufps xmm0, xmm0, 0    ; SIMD: select a single-precision floating-point value of an input quadruplet & move -> dest.
  mulps  xmm0, [velocity] ; SIMD: multiply & move to dest.
  addps  xmm0, [position] ; SIMD: add.
new_position:
  ;; check collision by comparing new position with [zero] & [border]
  ;; => store results in xmm1 & xmm2 :
  ;;
  ;; * cmp*ps instruction will return [bitmasks] instead of float32
  ;; => explains why we need to convert result -> float32 to compute further.
  ;; * cvtdq2ps : will convert bitmasks in XMM Regs -> float32 again 
  ;;
  movaps  xmm1, xmm0      ; SIMD: move new position from xmm0 -> xmm1
  cmpltps xmm1, [zero]    ; SIMD: Rect < Zero ? 0xFFFFFFFF : 0x00000000
cmp_rect_zero:

  movaps   xmm2, xmm0     ; SIMD: move-a-pack-of-precision-single
  addps    xmm2, [size]   ; SIMD: xmm2 = position + box-size 
  cmpnltps xmm2, [border] ; SIMD: Rect > screen ? xmm2 = ? 0xFFFFFFFF : 0x00000000
cmp_rect_border:

  orps     xmm1, xmm2        ; boundary-check (off-screen < 0 || > border) 
orps_xmm1_xmm2:

  cvtdq2ps xmm1, xmm1        ; convert bitmasks in xmm1 -> float32 again.
converted_bitmasks_to_float32:

  mulps    xmm1, [minus_one] ; invert pack -> negative pack 
mul_xmm1_minus_one:

movaps   xmm2, [one]      ; xmm2 = [1.0, 1.0, 1.0, 1.0]
subps    xmm2, xmm1       ; xmm2 -= xmm1
; => we got sides that didn't collide (x1=0,y1=1,x2=1,y2=1) 
vector_result:
  
  ;; update position 
  movaps xmm3, [position] ; xmm3 = moving amount 
  mulps  xmm3, xmm1       ; xmm3 *= xmm1 (as negative bits) 
                          ; (move toward sides - that didn't touch screen yet)
neg_position_xmm3:

  movaps xmm4, xmm0       ; xmm4 = new moving amount 
  mulps  xmm4, xmm2       ; xmm4 *= xmm2 (all inverted movable sides) 
mul_xmm4_xmm2:

  addps  xmm3, xmm4       ; xmm3 += xmm4
  movaps [position], xmm3 ; 
updated_position:

;; update velocity
  subps xmm2, xmm1
  movaps xmm3, [velocity]
  mulps xmm2, xmm3 
  movaps [velocity], xmm2
updated_vector:

  ;; render Rect #1
  movq xmm0, [position]   ; SIMD: move a quadword between MMX register.
  movq xmm1, [size]
  mov rdi,   [color_red]
  call DrawRectangleV

  ;; render Rect #2
  movq xmm0, [position + 8]
  movq xmm1, [size + 8]
  mov rdi,   [color_blue]
  call DrawRectangleV

  call EndDrawing
  jmp loop_frame
    
over:
  call CloseWindow
  xor rdi,rdi
  call _exit

