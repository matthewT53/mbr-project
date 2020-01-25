# COMP6845 MBR project:
## Setting up the environment:
### Install:
1. qemu - Emulator
2. nasm - Assembler

## Getting a bootloader:
* dd if="drive" of=boot.bin bs=512 count=1

## Running this stuff:
* Compile asm to mbr bin: nasm -f bin ???.asm -o ???.bin
* Disassemble bin to asm: ndisasm -b16 -o7C00h ???.bin > ???.asm
(can omit flag -07c00h to display assembly from 0x0000 instead of 0x7c00)
* qemu-system-i386 -fda boot.bin -boot a -s -S
* -s and -S pauses qemu allowing you to attach a debugger and also
starts a debugging server at localhost:1234.

### Option 2:
* Use bochs on linux.
* Follow the link below to setup:
    * https://stechazine.blogspot.com/2013/03/how-to-setup-boch-32-emulator-in-ubuntu.html

## Attaching a debugger:
* We chose to use GDB.
* In gdb type:
```
    target remote localhost:1234
```

## Debugging reading sectors:
* Put a breakpoint after the interrupt call (0x13).
* Don't try to step through the interrupt using "ni".

## Scripts:
* Use create_disk.py to extend boot.bin with more sectors so we can test
reading and writing.

## Some useful links:
* https://blog.ghaiklor.com/how-to-implement-your-own-hello-world-boot-loader-c0210ef5e74b
* https://stackoverflow.com/questions/14242958/debugging-bootloader-with-gdb-in-qemu
