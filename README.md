# Raylib on FASM
A playground exclusively on raylib/fasm.

#### rect_bounce 
A more detailed analysis into how SIMD + Bitmask work for non-jumping condition trick : boundary-check on all screen sides + offset new (or preserve old) position by combined bitmasks result.

#### get_keycode
Which initially was drag-drop demo but then I realize Wayland doesn't support drag-drop like X11 for raylib. So eventually turn this into get_keycode demo to understand flow & arrange code block more effectively. Also :

How to skip frame properly in Raylib ?

Because swap-buffer will be called whenever you update your both frames in buffer or not.. Which took me 5Hrs to debug what was wrong then realized it was the buffer showing old frame, LMAO xD.

### 1. Compile

    make build && ./rect_bounce

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
