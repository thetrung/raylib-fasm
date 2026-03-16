# Raylib on FASM
A playground exclusively on raylib/fasm.

### Note 
16.03.2026 - when I come back to FASM after a long rest (like 3 months), I actually have to relearn everything I have known about this Assembler & specially about x86-64 Register/Instruction usage to improve further through its native macros system (invoke/simd) to understand clearly how everything actually work. Which made my new code in `playground-fasm` much better to read/write with new macros even on minimal `libX11/GL`.   

And so, coming back to this early codebase to refactor a little bit more, I realized how bad it is to misunderstand me (by over-complicated things) when I first-come to write FASM. Mostly about how each register type require its own instruction/correct size to work with, while mixing with how to invoke c-function on Linux in a good way that never cause `SEGFAULT` by correct stack alignment. Which also explain how struct alignment actually work to measure its size when doing malloc/free.

The point is, Assembly Language itself isn't that complicated, but OS & ABI calling convention make it seem. X86-64 CPU surely contribute to the complex mix but not much, indeed a lot of its instructions are very high-level, data-oriented style and easier to use than whatever high-level language are lying to us.

So no matter what every high level source code are writing, they eventually will be compiled down into data-oriented assembly for both CPU/GPU to decode, batch, buffer & execute on top of certain memory layout it have.

I will archive this repo after this commit as simple guide on how to debug FASM + Raylib intro, but that's it. Just a terrible thing to start with.

#### rect_bounce 
A more detailed analysis into how SIMD + Bitmask work for non-jumping condition trick : boundary-check on all screen sides + offset new (or preserve old) position by combined bitmasks result.

#### get_keycode
Which initially was drag-drop demo but then I realize Wayland doesn't support drag-drop like X11 for raylib. So eventually turn this into get_keycode demo to understand flow & arrange code block more effectively. Also :

How to skip frame properly in Raylib ?

Because swap-buffer will be called whenever you update your both frames in buffer or not.. Which took me 5Hrs to debug what was wrong then realized it was the buffer showing old frame, LMAO xD.

#### sprintf_float
One problem I realize while dealing with floating-point number on Raylib is: how we properly move, convert, display, format it properly in FASM. And turnout, it should be just as simple as `cvtss2sd xmm0, [simd_data]` then call `sprintf` with your format string as usual. This example is to demostrate that without crashing.

`movss` to move a single scalar from SSE->SSE registers.
`movaps` to move aligned packed (of 4 in SSE) single precision values at once.
`movq/movdq` for normal register <- SSE register depends on size.
`shufps` if you want mass-move data from one XMM to another..

### 1. Compile

    make

cleanup :

    make clean

### 2. Debug with GDB 

    gdb game

- public every symbol you want to debug values on registers or memory:

      public updated_position

- add breakpoint (with condition or not) during `gdb > run` :

      b *updated_position if $xmm0[0].v4_float != 0.0

- check all breakpoints with :

      info breakpoints

- delete each breakpoint :

      delete 1 ;=> remove breakpoint #1.

- get value inside registers or symbol address :

      p $xmm0.v4_float ;=> show value in pack of float 

### 3. Dependencies 
More details about used libraries in the `Makefile` but only linux lib64 + Raylib.

### 4. Takeaways 
After stucked in this deep rabbit hole for like a week, I realize how elegant & simple FASM (or ASM in general) could be. 

Even simpler while stay more powerful than every high level language out there with much shorter syntax or actual procedures, while preserve the accessibility to raw data without type-abstraction which restrict the extraction or transform into more meaningful data to be used.

Imagine all matrix muliply/permute/shuffle along bitmasks (as conditions) could do with hassle of data-type restriction : you can convert freely from one to another, trim/concate bytes into any format you need. The total control at binary level is unmatched to any known languages. Certainly, come at trade-off in longer code segment without any standard libraries to support it (yet).

In my perspective, any high level language is simply just an Assembly Library - packed into fixed, convenient format to be used in certain condition..
