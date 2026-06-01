.model small
.stack 200h

.data
; =========================================================================
; GAME STATE CONTROLLER
; =========================================================================
; 0 = Menu, 1 = Active Mission, 2 = System Protocols, 3 = Victory Terminal
current_state   db 0

; =========================================================================
; ENGINE SYSTEM VARIABLES
; =========================================================================
p_x             db 18       ; Player Column Position (0-19)
p_y             db 18       ; Player Row Position (0-19)
t_x             db 5        ; Target Column Position (0-19)
t_y             db 18       ; Target Row Position (0-19)

new_x           db 0        ; Projected coordinate X
new_y           db 0        ; Projected coordinate Y

superman        db 0        ; 0 = Standard, 1 = Superman (Bypass Walls)
moves_count     dw 0        ; Real-time move accumulator

; =========================================================================
; MAZE BLUEPRINT (20x20 Real-Time Grid Array)
; 1 = Cyber Wall, 0 = Empty Path, 2 = Trailed Tracking Light
; =========================================================================
maze_width      equ 20

maze db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
db 1,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1
db 1,0,1,0,1,0,1,1,1,1,1,1,1,0,1,0,1,1,0,1
db 1,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,0,0,1
db 1,0,1,1,1,1,1,0,1,1,1,0,1,1,1,1,1,0,1,1
db 1,0,0,0,0,0,1,0,1,0,0,0,1,0,0,0,1,0,0,1
db 1,1,1,1,1,0,1,0,1,0,1,1,1,0,1,0,1,1,0,1
db 1,0,0,0,1,0,1,0,1,0,0,0,1,0,1,0,0,0,0,1
db 1,0,1,0,1,0,1,0,1,1,1,0,1,0,1,0,1,1,1,1
db 1,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,1
db 1,0,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,0,1
db 1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1
db 1,1,1,1,1,1,1,1,1,0,1,0,1,1,1,1,1,1,1,1
db 1,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,1
db 1,0,1,1,1,0,1,0,1,0,1,0,1,1,1,1,1,1,0,1
db 1,0,1,0,1,0,0,0,1,0,0,0,1,0,0,0,0,1,0,1
db 1,0,1,0,1,1,1,1,1,0,1,1,1,0,1,1,0,1,0,1
db 1,0,1,0,0,0,0,0,0,0,1,0,0,0,1,0,0,1,0,1
db 1,0,1,1,1,0,1,1,1,1,1,1,1,1,1,1,0,0,0,1
db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

; =========================================================================
; STYLIZED ARCHIVE DISPLAY ASSETS
; =========================================================================
str_game_title  db '===  MAZE  RUNNER  ===$'

; Menu Assets
str_m_border    db '====================================$'
str_m_title     db '     ESCAPE PROTOCOL MAINBOARD$'
str_m_decor     db '      * SYSTEM INITIALIZED *$'
str_m_opt1      db '[1] INITIATE ESCAPE SEQUENCER$'
str_m_opt2      db '[2] SYSTEM PROTOCOLS (HELP)$'
str_m_opt3      db '[3] ABORT RUNNER SYSTEMS$'
str_m_prompt    db 'INPUT DIRECTIVE (1-3): $'

; Instructions Panel Assets
str_i_header    db '=== RUNNER MANUAL PROTOCOLS ===$'
str_i_line1     db '- Nav: Standard ARROW KEYS$'
str_i_line2     db '- Node Target: Yellow PI symbol$'
str_i_line3     db '- Bypass: Press SPACE (Superman)$'
str_i_warn      db 'WARNING: Solid grids block Normal paths$'
str_i_footer    db 'PRESS ANY KEY TO RETURN...$'

; Gameplay Screen HUD Assets
str_hud_lbl1    db '=== MISSION PANEL ===$'
str_hud_stat    db 'SYS STATUS: ACTIVE$'
str_hud_moves   db 'ANALYSED MOVES:$'
str_hud_mode    db 'BYPASS MODE:$'
str_hud_m_norm  db 'NORMAL$'
str_hud_m_super db 'SUPERMAN$'
str_hud_target  db 'NODE COORDS:$'
str_hud_t_val   db '[05, 18]$'
str_hud_esc     db 'Press ESC to Abort$'
str_hud_line    db '|$'

; Victory Terminal Assets
str_v_banner    db '====================================$'
str_v_title     db '      MISSION COMPLETED SUCCESS$'
str_v_line1     db 'Node fully bypassed, Pi secured!$'
str_v_moves     db 'Moves executed: $'
str_v_rating    db 'System Rank: $'
str_v_r_gold    db 'CLASS-A CYBER ESCAPIST$'
str_v_r_silver  db 'CLASS-B ADROIT RUNNER$'
str_v_r_bronze  db 'CLASS-C CASUAL SURVIVOR$'
str_v_footer    db 'Press ESC to load Mainboard$'

.code
main proc
mov ax, @data
mov ds, ax

STATE_CONTROLLER:
cmp current_state, 0
je  RUN_MENU_SCREEN
cmp current_state, 1
je  RUN_GAMEPLAY_SCREEN
cmp current_state, 2
je  RUN_INSTRUCTIONS_SCREEN
cmp current_state, 3
je  RUN_WIN_SCREEN
jmp EXIT_GAME

; -----------------------------------------------------------------------------
; RUN_MENU_SCREEN: Cyber Terminal Main Board interface
; -----------------------------------------------------------------------------
RUN_MENU_SCREEN:
call CLEAR_SCREEN

; Draw Mainboard double outer borders
mov ax, 0013h
int 10h

; Draw Title Border (Light Cyan)
mov ah, 02h
mov dh, 2
mov dl, 2
mov bh, 0
int 10h
lea dx, str_m_border
call PRINT_STR_CYAN

mov dh, 3
mov dl, 2
call SET_CURSOR
lea dx, str_m_title
call PRINT_STR_YELLOW

mov dh, 4
mov dl, 2
call SET_CURSOR
lea dx, str_m_decor
call PRINT_STR_MAGENTA

mov dh, 5
mov dl, 2
call SET_CURSOR
lea dx, str_m_border
call PRINT_STR_CYAN

; Options Section
mov dh, 9
mov dl, 4
call SET_CURSOR
lea dx, str_m_opt1
call PRINT_STR_WHITE

mov dh, 11
mov dl, 4
call SET_CURSOR
lea dx, str_m_opt2
call PRINT_STR_WHITE

mov dh, 13
mov dl, 4
call SET_CURSOR
lea dx, str_m_opt3
call PRINT_STR_WHITE

; Input Selection Prompt
mov dh, 17
mov dl, 3
call SET_CURSOR
lea dx, str_m_prompt
call PRINT_STR_CYAN


WAIT_MENU_INPUT:
mov ah, 00h
int 16h

cmp al, '1'
je  START_GAME_DIRECTIVE
cmp al, '2'
je  START_INS_DIRECTIVE
cmp al, '3'
je  EXIT_GAME_DIRECTIVE
jmp WAIT_MENU_INPUT


START_GAME_DIRECTIVE:
mov current_state, 1
jmp STATE_CONTROLLER
START_INS_DIRECTIVE:
mov current_state, 2
jmp STATE_CONTROLLER
EXIT_GAME_DIRECTIVE:
jmp EXIT_GAME

; -----------------------------------------------------------------------------
; RUN_INSTRUCTIONS_SCREEN: System Protocol Info Deck
; -----------------------------------------------------------------------------
RUN_INSTRUCTIONS_SCREEN:
call CLEAR_SCREEN

; Set Video
mov ax, 0013h
int 10h

; Draw framed protocol layout
mov dh, 2
mov dl, 4
call SET_CURSOR
lea dx, str_i_header
call PRINT_STR_CYAN

mov dh, 6
mov dl, 2
call SET_CURSOR
lea dx, str_i_line1
call PRINT_STR_WHITE

mov dh, 8
mov dl, 2
call SET_CURSOR
lea dx, str_i_line2
call PRINT_STR_WHITE

mov dh, 10
mov dl, 2
call SET_CURSOR
lea dx, str_i_line3
call PRINT_STR_WHITE

mov dh, 14
mov dl, 1
call SET_CURSOR
lea dx, str_i_warn
call PRINT_STR_MAGENTA

mov dh, 18
mov dl, 6
call SET_CURSOR
lea dx, str_i_footer
call PRINT_STR_YELLOW

; Wait loop to cycle back
mov ah, 00h
int 16h
mov current_state, 0
jmp STATE_CONTROLLER


; -----------------------------------------------------------------------------
; RUN_GAMEPLAY_SCREEN: Primary Action Map & Terminal HUD Screen
; -----------------------------------------------------------------------------
RUN_GAMEPLAY_SCREEN:
; Standard graphics init
mov ax, 0013h
int 10h

; Clear parameters on sequence initialization
mov p_x, 18
mov p_y, 18
mov moves_count, 0
mov superman, 0

; Draw Static Panels once to eliminate screen refresh flickering
call DRAW_MAZE
call DRAW_TARGET
call DRAW_UI
call DISPLAY_MOVES


GAME_LOOP:
call DRAW_PLAYER

; BIOS Keystroke input
mov ah, 00h
int 16h

cmp al, 1Bh         ; Check Escape Code
je  GO_TO_MENU

cmp al, ' '         ; Check Space Toggle
jne CHECK_ARROWS
xor superman, 1     ; Flip Superman variable state
call DRAW_UI        ; Update HUD elements instantly
jmp GAME_LOOP


CHECK_ARROWS:
mov cl, p_x
mov ch, p_y
mov new_x, cl
mov new_y, ch

; Map execution offsets matching arrows scan codes in AH
cmp ah, 48h         ; UP Scan Code
je  MOVE_UP
cmp ah, 50h         ; DOWN Scan Code
je  MOVE_DOWN
cmp ah, 4Bh         ; LEFT Scan Code
je  MOVE_LEFT
cmp ah, 4Dh         ; RIGHT Scan Code
je  MOVE_RIGHT
jmp GAME_LOOP


MOVE_UP:
dec new_y
jmp APPLY_MOVE
MOVE_DOWN:
inc new_y
jmp APPLY_MOVE
MOVE_LEFT:
dec new_x
jmp APPLY_MOVE
MOVE_RIGHT:
inc new_x
jmp APPLY_MOVE

APPLY_MOVE:
; Enforce logical boundaries of 20x20 grid
cmp new_x, 0
jl  GAME_LOOP
cmp new_x, 19
jg  GAME_LOOP
cmp new_y, 0
jl  GAME_LOOP
cmp new_y, 19
jg  GAME_LOOP

cmp superman, 1
je  UPDATE_POS      ; Bypass wall evaluation when superman active

; Evaluate wall collision byte
mov al, new_y
mov bl, maze_width
mul bl
mov bl, new_x
mov bh, 0
add ax, bx
mov bx, ax

cmp maze[bx], 1
je  GAME_LOOP       ; Collision registered! Retain position.


UPDATE_POS:
; Convert coords to array index to stamp tracked light trace
mov al, p_y
mov bl, maze_width
mul bl
mov bl, p_x
mov bh, 0
add ax, bx
mov bx, ax

cmp maze[bx], 0
jne LEAVE_AS_IS
mov maze[bx], 2     ; Mark trail index


LEAVE_AS_IS:
call ERASE_PLAYER

; Commit changes to core variables
mov cl, new_x
mov p_x, cl
mov ch, new_y
mov p_y, ch

; Accumulate move tracking metrics
inc moves_count
call DISPLAY_MOVES

; Compare coordinates to win vectors
mov cl, t_x
cmp p_x, cl
jne GAME_LOOP
mov ch, t_y
cmp p_y, ch
jne GAME_LOOP

; Escape achieved, redirect to Terminal Win layout
mov current_state, 3
jmp STATE_CONTROLLER


GO_TO_MENU:
mov current_state, 0
jmp STATE_CONTROLLER

; -----------------------------------------------------------------------------
; RUN_WIN_SCREEN: High-Contrast Victory Dashboard
; -----------------------------------------------------------------------------
RUN_WIN_SCREEN:
call CLEAR_SCREEN

mov ax, 0013h
int 10h

; Draw Banner Top (Green)
mov dh, 3
mov dl, 2
call SET_CURSOR
lea dx, str_v_banner
call PRINT_STR_GREEN

mov dh, 4
mov dl, 2
call SET_CURSOR
lea dx, str_v_title
call PRINT_STR_YELLOW

mov dh, 5
mov dl, 2
call SET_CURSOR
lea dx, str_v_banner
call PRINT_STR_GREEN

; Info Lines
mov dh, 8
mov dl, 4
call SET_CURSOR
lea dx, str_v_line1
call PRINT_STR_WHITE

; Draw Move Stat
mov dh, 11
mov dl, 4
call SET_CURSOR
lea dx, str_v_moves
call PRINT_STR_CYAN
call PRINT_WIN_MOVES

; Draw System Rating based on performance
mov dh, 14
mov dl, 4
call SET_CURSOR
lea dx, str_v_rating
call PRINT_STR_MAGENTA
call PRINT_PERFORMANCE_RATING

; Exit Option footer
mov dh, 18
mov dl, 6
call SET_CURSOR
lea dx, str_v_footer
call PRINT_STR_YELLOW


WAIT_WIN_ESC:
mov ah, 00h
int 16h
cmp al, 1Bh         ; Wait for Escape
je  WIPE_MAZE_TRACKS
jmp WAIT_WIN_ESC

WIPE_MAZE_TRACKS:
; Clear dynamic trail light values inside coordinate grid
mov cx, 0
RESET_LOOP:
mov bx, cx
cmp maze[bx], 2
jne NEXT_RESET
mov maze[bx], 0
NEXT_RESET:
inc cx
cmp cx, 400
jl  RESET_LOOP

mov current_state, 0
jmp STATE_CONTROLLER


; -----------------------------------------------------------------------------
; EXIT_GAME: Restores settings and halts process execution
; -----------------------------------------------------------------------------
EXIT_GAME:
mov ax, 0003h       ; Reset to standard DOS text mode
int 10h
mov ax, 4C00h       ; OS Terminate process
int 21h
main endp

; =============================================================================
; GENERAL HELPER PROCEDURES & CONSOLE UTILITIES
; =============================================================================

CLEAR_SCREEN proc
mov ax, 0003h
int 10h
ret
CLEAR_SCREEN endp

SET_CURSOR proc
mov ah, 02h
mov bh, 0
int 10h
ret
SET_CURSOR endp

; -----------------------------------------------------------------------------
; PRINT_COLOR_STR: Prints colorful text to active page in Mode 13h
; Input: DX = offset of string, BL = color attribute
; -----------------------------------------------------------------------------
PRINT_COLOR_STR proc
push ax
push bx
push cx
push dx
push si

mov si, dx              ; SI points to target string


PRINT_CHAR_LOOP:
lodsb                   ; Load character into AL, increment SI
cmp al, '$'             ; Terminate at end-of-string
je  PRINT_DONE

; 1. Obtain current cursor index
mov ah, 03h
mov bh, 0
int 10h                 ; Row in DH, Col in DL

; 2. Paint color character
mov ah, 09h
mov bh, 0               ; Page 0
mov cx, 1               ; Paint count
int 10h

; 3. Slide Cursor Col position to the right
inc dl
mov ah, 02h
mov bh, 0
int 10h
jmp PRINT_CHAR_LOOP


PRINT_DONE:
pop si
pop dx
pop cx
pop bx
pop ax
ret
PRINT_COLOR_STR endp

PRINT_STR_CYAN proc
mov bl, 03h         ; Cyber Cyan Color
call PRINT_COLOR_STR
ret
PRINT_STR_CYAN endp

PRINT_STR_YELLOW proc
mov bl, 0Eh         ; Golden Yellow Color
call PRINT_COLOR_STR
ret
PRINT_STR_YELLOW endp

PRINT_STR_MAGENTA proc
mov bl, 0Dh         ; Bright Neon Pink/Magenta
call PRINT_COLOR_STR
ret
PRINT_STR_MAGENTA endp

PRINT_STR_WHITE proc
mov bl, 0Fh         ; Bright White
call PRINT_COLOR_STR
ret
PRINT_STR_WHITE endp

PRINT_STR_GREEN proc
mov bl, 0Ah         ; Emerald Green
call PRINT_COLOR_STR
ret
PRINT_STR_GREEN endp

; -----------------------------------------------------------------------------
; DISPLAY_MOVES: Format decimals inside gameplay screen HUD panel
; -----------------------------------------------------------------------------
DISPLAY_MOVES proc
mov ah, 02h
mov dh, 7           ; Align nicely in HUD
mov dl, 23          ; Column alignment
mov bh, 0
int 10h

; Extract hundreds, tens, units dynamically from 16-bit register
mov ax, moves_count
xor dx, dx
mov cx, 100
div cx
push dx

mov dl, al
add dl, '0'
mov ah, 02h
int 21h

pop ax
mov cl, 10
div cl
mov ch, ah

mov dl, al
add dl, '0'
mov ah, 02h
int 21h

mov dl, ch
add dl, '0'
mov ah, 02h
int 21h
ret


DISPLAY_MOVES endp

; -----------------------------------------------------------------------------
; PRINT_WIN_MOVES: Output moves count in victory screen
; -----------------------------------------------------------------------------
PRINT_WIN_MOVES proc
mov ax, moves_count
xor dx, dx
mov cx, 100
div cx
push dx

mov dl, al
add dl, '0'
mov ah, 02h
int 21h

pop ax
mov cl, 10
div cl
mov ch, ah

mov dl, al
add dl, '0'
mov ah, 02h
int 21h

mov dl, ch
add dl, '0'
mov ah, 02h
int 21h
ret


PRINT_WIN_MOVES endp

; -----------------------------------------------------------------------------
; PRINT_PERFORMANCE_RATING: Dynamic ranking calculation
; -----------------------------------------------------------------------------
PRINT_PERFORMANCE_RATING proc
mov ax, moves_count
cmp ax, 50
jbe RATING_GOLD
cmp ax, 100
jbe RATING_SILVER
jmp RATING_BRONZE

RATING_GOLD:
lea dx, str_v_r_gold
call PRINT_STR_GREEN
ret

RATING_SILVER:
lea dx, str_v_r_silver
call PRINT_STR_CYAN
ret

RATING_BRONZE:
lea dx, str_v_r_bronze
call PRINT_STR_MAGENTA
ret
PRINT_PERFORMANCE_RATING endp

; -----------------------------------------------------------------------------
; DRAW_MAZE: Renders the Cyberpunk Wall blueprint (Neon Cyan blocks)
; -----------------------------------------------------------------------------
DRAW_MAZE proc
mov cx, 0
DRAW_MAZE_LOOP:
mov bx, cx
cmp maze[bx], 1
jne NEXT_TILE

mov ax, cx
mov bl, maze_width
div bl              ; AL = Y (Row), AH = X (Col)

push cx
mov dh, al
add dh, 1           ; Leave top row free for header
mov dl, ah
mov bh, 0
mov ah, 02h
int 10h

mov ah, 09h
mov al, 0DBh        ; Block character
mov bh, 0
mov bl, 03h         ; Dark Cyan Cyber Grid color
mov cx, 1
int 10h
pop cx


NEXT_TILE:
inc cx
cmp cx, 400
jl  DRAW_MAZE_LOOP
ret
DRAW_MAZE endp

; -----------------------------------------------------------------------------
; DRAW_TARGET: Renders golden Yellow Pi symbol
; -----------------------------------------------------------------------------
DRAW_TARGET proc
mov ah, 02h
mov bh, 0
mov dh, t_y
add dh, 1
mov dl, t_x
int 10h

mov ah, 09h
mov al, 0E3h        ; Pi sign symbol
mov bh, 0
mov bl, 0Eh         ; Golden Yellow Color
mov cx, 1
int 10h
ret


DRAW_TARGET endp

; -----------------------------------------------------------------------------
; DRAW_PLAYER: Active dynamic avatar update logic
; -----------------------------------------------------------------------------
DRAW_PLAYER proc
mov ah, 02h
mov bh, 0
mov dh, p_y
add dh, 1
mov dl, p_x
int 10h

mov bl, 0Ah         ; Emerald Green avatar color
cmp superman, 1
jne PRINT_SMILEY
mov bl, 0Bh         ; Cyan color shift indicating active superman mode


PRINT_SMILEY:
mov ah, 09h
mov al, 02h         ; Retro smiling arcade avatar
mov bh, 0
mov cx, 1
int 10h
ret
DRAW_PLAYER endp

; -----------------------------------------------------------------------------
; ERASE_PLAYER: Clean tile refresh avoiding full redraw flickering
; -----------------------------------------------------------------------------
ERASE_PLAYER proc
mov al, p_y
mov bl, maze_width
mul bl
mov bl, p_x
mov bh, 0
add ax, bx
mov bx, ax

mov al, ' '
mov cl, 00h

cmp maze[bx], 1
je  DRAW_WALL_BACK
cmp maze[bx], 2
je  DRAW_TRACK_BACK
jmp EXECUTE_ERASE


DRAW_WALL_BACK:
mov al, 0DBh
mov cl, 03h         ; Restore standard Cyber Wall
jmp EXECUTE_ERASE

DRAW_TRACK_BACK:
mov al, '.'         ; Leaving dynamic trail lighting crumb
mov cl, 0Bh         ; Light Cyan glowing light crumbs

EXECUTE_ERASE:
push ax
push cx
mov ah, 02h
mov bh, 0
mov dh, p_y
add dh, 1
mov dl, p_x
int 10h

pop cx
pop ax
mov bl, cl
mov ah, 09h
mov bh, 0
mov cx, 1
int 10h
ret


ERASE_PLAYER endp

; -----------------------------------------------------------------------------
; DRAW_UI: Dual-Panel Mission Controller Layout on the Right Side
; -----------------------------------------------------------------------------
DRAW_UI proc
; Draw dividing vertical cyberbar on Col 20 to isolate Left Board & Right HUD
mov cx, 0
DRAW_DIVIDER:
push cx             ; Save our loop counter safely

mov dh, cl          ; Row
mov dl, 20          ; Border position Col
mov bh, 0
mov ah, 02h
int 10h

mov ah, 09h
mov al, 0DBh        ; Solid block
mov bh, 0
mov bl, 03h         ; Cyber Cyan Wall Color
mov cx, 1
int 10h

pop cx              ; Restore our loop counter safely
inc cx
cmp cx, 22
jl  DRAW_DIVIDER

; Display Right Hand Mission control header
mov dh, 1
mov dl, 21
call SET_CURSOR
lea dx, str_hud_lbl1
call PRINT_STR_CYAN

; Row 3: Live System Telemetry Status
mov dh, 3
mov dl, 21
call SET_CURSOR
lea dx, str_hud_stat
call PRINT_STR_GREEN

; Row 5: Analyzed Move Accumulator Label
mov dh, 5
mov dl, 21
call SET_CURSOR
lea dx, str_hud_moves
call PRINT_STR_WHITE

; Row 9: Bypass Mode Telemetry Label
mov dh, 9
mov dl, 21
call SET_CURSOR
lea dx, str_hud_mode
call PRINT_STR_WHITE

; Row 10: Toggle dynamic label value depending on state
mov dh, 11
mov dl, 23
call SET_CURSOR
cmp superman, 1
je  HUD_SUPER_VAL
lea dx, str_hud_m_norm
call PRINT_STR_CYAN
jmp DRAW_HUD_REMAINDER


HUD_SUPER_VAL:
lea dx, str_hud_m_super
call PRINT_STR_MAGENTA

DRAW_HUD_REMAINDER:
; Row 14: Target node coordinates
mov dh, 14
mov dl, 21
call SET_CURSOR
lea dx, str_hud_target
call PRINT_STR_WHITE

mov dh, 15
mov dl, 23
call SET_CURSOR
lea dx, str_hud_t_val
call PRINT_STR_YELLOW

; Row 19: Emergency exit controls key label
mov dh, 19
mov dl, 21
call SET_CURSOR
lea dx, str_hud_esc
call PRINT_STR_MAGENTA

; Top Border title (Left Hand Panel)
mov dh, 0
mov dl, 1
call SET_CURSOR
lea dx, str_game_title
call PRINT_STR_CYAN
ret


DRAW_UI endp

end main