GRAPHICS=0
ADAMS=1
EXITCOL=134
OBJCOL=131
MESSCOL=131
SYSCOL=135
TEXTCOL=41
INPUTCOL=134

include "engine.asm"
include "samessages.asm"
.objsep
equb ".",0
.end

save "ENGINE",start,end

; add game files - disk1
putfile "gking\GKING","G.GKING",datastart
putfile "gking\title","SCR",&5800
putbasic "gking\LOAD.txt","LOAD"
puttext "gking\boot","!BOOT",0
