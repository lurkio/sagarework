# sagarework
A rework of the SAGA text adventure engine on the BBC Micro.

There are two bits of the code: the C code to compress the raw Scott Adams files and graphics to the format I use (compiled with gcc) and the 6502 Assembler for the actual engine.

The code was designed to be assembled with Rich Talbot-Watkins's BeebASM (from http://www.retrosoftware.co.uk/wiki/index.php?title=BeebAsm).

A development diary can be found at http://www.retrosoftware.co.uk/wiki/index.php?title=SAGArework

The directories contain:
samples/data - the converted data files where G.* is the graphics data and L.* is the adventure data
samples/disks - some premade disks to run in your favourite BBC Master emulator
src - the assembler source of the engine
tools - the C code for taking an extract Scott Adams file and mangling it into the more compressed format I use
