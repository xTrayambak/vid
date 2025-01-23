# vid
Vid is a very simple programming language that I'm mostly writing to learn compiler design. It is written pretty badly because it's just for learning. :^)

Vid currently only targets x86-64 (AMD64) Linux systems. You cannot feed it IR or anything to make it generate code right now.

The "compiler" can only be instructed on what to do (it can't do much yet :P) by editing the code in `src/vid.nim` to change some stuff.

# vir
VIR is an IR format I'm making for the compiler, learning from my previous [MIR format](https://github.com/ferus-web/mirage). \
The compiler does not understand it yet, and I'm still deciding how it should look.
