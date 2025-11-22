format ELF64
section '.note.GNU-stack'
section '.data' writeable
; misc stuffs
color_red:    dd 0xFF0000FF
color_blue:   dd 0xFF00FF00
color_white:  dd 0xFFFFFFFF
color_black:  dd 0xFF181818
title:        db 'Raylib SIMD Demo',0,0
msg_flag:     db 'Flag START',0,0
msg_buffer:   rb 128
msg_position: db 'position: %f  %f',0,0 ; %f will use double while %.2f will use float.
; 
; SEGMENTFAULT :: 
; add 0 after the last string field then align 8 
; to avoid crashing when accessing SIMD data right after a db value.
; Tend to misalign 2-byte.
;
; SIMD DATA  
align 8
inverted_vector : 
dd 0.0 
dd 0.0 
dd 0.0 
dd 0.0 
boundary_check :
dd 0.0 
dd 0.0 
dd 0.0 
dd 0.0 
next_position : 
dd 0.0 
dd 0.0 
dd 0.0 
dd 0.0 
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
public compute_next_position
; Check Screen Bound 
public cmp_rect_zero
public cmp_rect_border
public orps_xmm1_xmm2
public converted_bitmasks_to_float32
public mul_xmm1_minus_one
public vector_result
;; Update position + vector
public updated_position
public updated_vector
;; variables
public boundary_check
public inverted_vector
public next_position
extrn _exit
extrn printf
extrn sprintf
extrn InitWindow
extrn SetTargetFPS
extrn WindowShouldClose
extrn BeginDrawing
extrn ClearBackground
extrn GetScreenWidth
extrn GetScreenHeight
extrn GetFrameTime
extrn DrawText
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

  ;; next position :
  call GetFrameTime 
  shufps xmm0, xmm0, 0x00 ; SIMD: 0x00, 0x55, 0xAA, 0xFF => (1..), (2..), (3..), (4..)
  mulps  xmm0, [velocity] ; SIMD: multiply & move to dest.
  addps  xmm0, [position] ; SIMD: p' = p + v * dt 
  movaps [next_position], xmm0 ; our new middle-reg for clarity 
compute_next_position:
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

  mulps    xmm1, [minus_one]      ; invert pack -> negative pack
  movaps [inverted_vector], xmm1  
mul_xmm1_minus_one:

movaps   xmm2, [one]          ; xmm2 = [1.0, 1.0, 1.0, 1.0]
subps    xmm2, xmm1           ; xmm2 = [one] - [inverted_vector]
movaps  [boundary_check], xmm2; [boundary_check] = xmm2
; => we got sides that didn't collide (x1=0,y1=1,x2=1,y2=1) 
vector_result:
  
  ;; Update position :
  ;; 
  ;; * This take use of SSE/SIMD + bitmask-trick to avoid jumping 
  ;; to each conditional check, instead, it combined boundary_check
  ;; conditions -> to offset new poistion each x/y side depends on 
  ;; if the Rectangle collided with or not ?
  ;; 
  ;; Box -> collided w/ bounds -> ignore the new x:y position completely 
  ;; whenever ( Box < 0 || > screen ) then invert velocity by multiplying 
  ;; with [minus_one] vector.
  ;; 
  ;; What tricky here is how author use bitmask-trick to do so, instead of
  ;; any conditional jump : so [1,1,0,0] * [120,120,0,0] -> new [120,120..]
  ;; while [0,0,0,0] * [120,120..] -> ignore new position & preserved old one :
  ;; [position] = [1,1...] * [120,120..] + [0,0..] * [100,100...] 
  ;;            = [120,120...] => which is the accepted [new_position].
  ;;
  ;; This is why we need both [boundary_check] && [inverted_vector] :
  ;; - they always offset each other as the same to conditions.
  ;; - [boundary_check] allow [new_position] value 
  ;; - [inverted_vector] allow old [position] value 
  ;; - if one is allowed, the other is totally ingorned.
  ;; => no need for conditional jump, great for SIMD effeciency.
  ;;
  movaps xmm4, [next_position]
  mulps  xmm4, [boundary_check] ; [next_position] *= [boundary_check]                
  movaps xmm3, [position]      
  mulps  xmm3, [inverted_vector]; [position] *= [inverted_vector]
  addps  xmm3, xmm4             ; it offset new/old position by boundary-check :
  movaps [position], xmm3       ; p'' = [next_position] + [position]
updated_position:

;; update velocity : 
;; because computation always need to be done with register.
  subps  xmm2, [inverted_vector] ; x2 = [boundary_check] - [inverted_vector]
  movaps xmm3, [velocity]
  mulps  xmm2, xmm3
  movaps [velocity], xmm2        ; [next_velocity] = x2 * [velocity]
updated_vector:

  
  ;; Format Text  
  movss xmm0, [position]      ; 1st arg : posX
  movss xmm1, [position + 4]  ; 2nd arg : posY
  cvtss2sd xmm0, xmm0         ; convert float -> double 
  cvtss2sd xmm1, xmm1

  mov rdi, msg_buffer   ; outbuf
  mov rsi, msg_position ; const char*
  ; xmm0 = 1st arg 
  ; xmm1 = 2nd arg 
  call sprintf

  ;; Draw Text
  mov rdi, msg_buffer
  mov rsi, 100          ; posX
  mov rdx, 100          ; posY
  mov rcx, 20           ; font-size
  mov r8, [color_white] ; color
  call DrawText

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

