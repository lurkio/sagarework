
GRAPHICS=1
ADAMS=0
EXITCOL=0
OBJCOL=0
MESSCOL=0
SYSCOL=0
TEXTCOL=39
INPUTCOL=0

include "engine.asm"
include "samessages.asm"
.objsep
equb ". ",0
.end

save "ENGINE",start,end

; add game files - disk1
putfile "MAdisc1\G.TGB","G.TGB",datastart
putfile "MAdisc1\G.TIME","G.TIME",datastart
putfile "MAdisc1\G.AOD1","G.AOD1",datastart
putfile "MAdisc1\G.AOD2","G.AOD2",datastart
putfile "MAdisc1\L.TGB","L.TGB",graphics
putfile "MAdisc1\L.TIME","L.TIME",graphics
putfile "MAdisc1\L.AOD1","L.AOD1",graphics
putfile "MAdisc1\L.AOD2","L.AOD2",graphics
putbasic "MAdisc1\MENU","MENU"
putbasic "MAdisc1\B.TGB","B.TGB"
puttext "MAdisc1\!BOOT","!BOOT",0
