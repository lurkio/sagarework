GRAPHICS=0
ADAMS=1
EXITCOL=134
OBJCOL=131
MESSCOL=131
SYSCOL=135
TEXTCOL=39
INPUTCOL=134

include "engine.asm"
include "samessages.asm"
.objsep
equb ".",0
.end

save "ENGINE",start,end

; add game files - disk1
putfile "lonesurvivor\lone","G.LONE",datastart
putbasic "lonesurvivor\LOAD.txt","LOAD"
puttext "lonesurvivor\boot","!BOOT",0
