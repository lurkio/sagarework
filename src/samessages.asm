.systemmessages
.directionn    equb 8,"North ",0                               ; 0
.directions    equb 8,"South ",0                               ; 1
.directione    equb 7,"East ",0                                ; 2
.directionw    equb 7,"West ",0                                ; 3
.directionu    equb 5,"Up ",0                                  ; 4
.directiond    equb 7,"Down ",0                                ; 5
IF GRAPHICS=1
   .exitslead     equb 13,"Exits are: ",0                      ; 6
   .cansee        equb 17,"Visible items: ",&0d                ; 7
   .youare        equb 12,"I am in a ",0                        ; 8
ELSE
   .exitslead     equb 14,130,"Exits are: ",0                  ; 6
   .cansee        equb 18,129,"Visible items: ",&0d            ; 7
   .youare        equb 12,134,"I am in a",0                    ; 8
ENDIF
.unknownverb   equb 23,131,"isn't a word I know.",0               ; 9
IF GRAPHICS=1
   .cantgo        equb 22,"I can't go that way.",&0d              ; 10
   .ok            equb 6,"O.K.",&0d                               ; 11
   .whatnow       equb 23,"What shall I do now? ",0               ; 12
   .eh            equb 5,"Eh?",&0d                                ; 13
   .movedark      equb 37,"It's dangerous to move in the dark!",&0d ; 14
   .notpickedup   equb 19,"I haven't got it.",&0d                 ; 15
   .carrying      equb 16,"I'm carrying: ",&0d                    ; 16
   .cantsee       equb 22,"I can't see it here.",&0d              ; 17
   .cantdo        equb 26,"That is beyond my power.",&0d          ; 18
   .direction     equb 18,"Try a direction.",&0d                  ; 19
   .toomuch       equb 24,"I'm carrying too much!",&0d            ; 20
   .dead          equb 11,"I'm dead!",&0d                         ; 21
   .again         equb 14,"Play again? ",0                        ; 22
   .restoregame   equb 24,"Restore a saved game? ",0              ; 23
   .cantdonow     equb 27,"I can't do that just now!",&0d         ; 24
   .nothingm      equb 10,"Nothing.",&0d                          ; 25
   .unknownnoun   equb 21,"I don't understand ",0                 ; 26
   .toodark       equb 23,"It's too dark to see!",&0d             ; 27
   .lightout      equb 20,"The light ran out!",&0d                ; 28
   .breakneck     equb 26,"I fell and broke my neck",&0d          ; 29
   .lightdim      equb 27,"Your light is growing dim",&0d         ; 30 
   .filename      equb 12,"Filename? ",0                          ; 31
   .separator     equb 39,"[-----------------------------------]",&0d ; 32
ELSE
   .cantgo        equb 23,131,"I can't go that way.",&0d              ; 10
   .ok            equb 7,131,"O.K.",&0d                               ; 11
   .whatnow       equb 23,135,"What shall I do now?",0               ; 12
   .eh            equb 6,131,"Eh?",&0d                                ; 13
   .movedark      equb 38,131,"It's dangerous to move in the dark!",&0d ; 14
   .notpickedup   equb 20,131,"I haven't got it.",&0d                 ; 15
   .carrying      equb 17,131,"I'm carrying: ",&0d                    ; 16
   .cantsee       equb 23,131,"I can't see it here.",&0d              ; 17
   .cantdo        equb 27,131,"That is beyond my power.",&0d          ; 18
   .direction     equb 19,131,"Try a direction.",&0d                  ; 19
   .toomuch       equb 46,131,"I'm carrying too much! Try: TAKE INVENTORY.",&0d            ; 20
   .dead          equb 12,131,"I'm dead!",&0d                         ; 21
   .again         equb 14,135,"Play again?",0                         ; 22
   .restoregame   equb 24,135,"Restore a saved game?",0              ; 23
   .cantdonow     equb 28,131,"I can't do that just now!",&0d         ; 24
   .nothingm      equb 11,131,"Nothing.",&0d                          ; 25
   .unknownnoun   equb 22,131,"I don't understand ",0                 ; 26
   .toodark       equb 24,134,"It's too dark to see!",&0d             ; 27
   .lightout      equb 21,131,"The light ran out!",&0d                ; 28
   .breakneck     equb 27,131,"I fell and broke my neck",&0d          ; 29
   .lightdim      equb 28,131,"Your light is growing dim",&0d         ; 30 
   .filename      equb 13,135,"Filename? ",0                          ; 31
   .separator     equb 40,133,"[-----------------------------------]",&0d ; 32
ENDIF

