; #########################################################################
;
;	Programmer: Haolan Zhan 
;   game.asm - Assembly file for CompEng205 Assignment 4/5
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

;;include files
include stars.inc
include lines.inc
include trig.inc
include blit.inc
include game.inc
include \masm32\include\windows.inc
include \masm32\include\winmm.inc
includelib \masm32\lib\winmm.lib
include \masm32\include\masm32.inc
includelib \masm32\lib\masm32.lib
include \masm32\include\user32.inc
includelib \masm32\lib\user32.lib



;; Has keycodes
include keys.inc

	
.DATA	
	;;pillow to catch falling cats
	pillow_sprite STRUCT 
		x_pos DWORD ?						;;integer
		y_pos DWORD ?						;;integer
		state BYTE ?						;;1 or 0, determines fluffy or squished
		ptrBitmap DWORD offset pillow2 		;;bitmap to the normal pillow
		ptrBitmap_s DWORD offset squishedpillow ;;bitmap to the squished pillow 
	pillow_sprite ENDS
	
	pillowNorm pillow_sprite <>
	
	;;Fan object can slow the fall of the cat 
	fan_sprite STRUCT
		x_pos DWORD ?						;;integer
		y_pos DWORD ?						;;integer
		ptrBitmap DWORD offset fan			;;bitmap to the fan 
	fan_sprite ENDS 
	
	game_fan fan_sprite <> 
	
	;;Cat objects are falling from the sky - we need to catch them!
	cat_sprite STRUCT
		x_pos DWORD ? 						;;fxpt 
		y_pos DWORD ? 						;;fxpt
		x_vel DWORD ?						;;fxpt
		y_vel DWORD ? 						;;fxpt
		y_accel DWORD ? 					;;fxpt
		rotate_angle DWORD ?				;;fxpt
		state BYTE ? 						;;1 or 0, determines whether the cat is falling or not
		visible BYTE ?						;;1 or 0, ditermines whether to draw the cat or not. not visible means not active, so no code to update the cat's elements
		wind BYTE ? 						;;1 or 0, determins whether the fan is slowing the acceleration or not 
		y_accel_slowed DWORD ? 				;;fxpt
		initial_wind_vel_dec Byte ? 		;;1 or 0, determines whether to add the initial wind velocity decrement (to make the fan more useful)
											;;Just decreasing the acceleration of the cat is not very helpful if the cat has already acelerated alot
											;;Therefore, initially, when the cat first exists over the fan, there is a one-time decrease in velocity by a factor of 0.5
											;;After this initial decrement to the y-velocity is applied, this byte should clear until the cat leaves the area above the fan 
											;;Therefore, the initial decrement to the y-velocity applies if and only if the cat first enters the area above the fan. 
		score DWORD ? 						;;score assigned to each cat 
		ptrBitmap DWORD offset cat			;;bitmap 
	cat_sprite ENDS
	
	game_cat cat_sprite 30 DUP(<>)			;; creates an array of 30 cats
	
	next_cat DWORD ?						;;pointer to current cat
	last_cat DWORD ?						;;pointer to one past the last cat in above array 
	
	;;bombs that fall from the sky 
	bomb_sprite STRUCT
		x_pos DWORD ? 						;;fxpt
		y_pos DWORD ? 						;;fxpt 
		x_vel DWORD ?						;;fxpt 
		y_vel DWORD ?						;;fxpt 
		y_accel DWORD ?						;;fxpt 
		visible BYTE ? 						;;1 if activated, 0 if not active 
		state BYTE ? 						;;1 if not blown up, 0 if blown up 
		ptrBitmap DWORD offset bomb 		;;normal bomb sprite 
		ptrBitmap_e DWORD offset explode 	;;exploded bomb sprite
	bomb_sprite ENDS
	
	game_bomb bomb_sprite 13 DUP(<>) 		;;creates an array of 10 bombs 
	
	next_bomb DWORD ? 						;;pointer to current bomb
	last_bomb DWORD ? 						;;pointer to one past the last bomb in the array above 
	
	;;states for the entire game 
	game_state BYTE ? 						;;state of the game, 0 is paused, 1 is playing
	game_score DWORD ?  					;;cumulative score of the game 
	game_over BYTE ? 						;;1 means game over, 0 is otherwise 
	exploded_bomb_ptr DWORD ?				;;drawing the bomb that caused the game-over during the game-over screen 
	beat_game_state BYTE ?  				;;1 means that the player beat the game, 0 otherwise 
	
	;;global variables for timing
	cycle_count_upper DWORD ?				;;the current stored cycle count (updated every time a cat is unleashed from the sky)
	cycle_count_lower DWORD ?
	cycle_buffer_upper DWORD ?				;; time elapsed in between cats being released 
	cycle_buffer_lower DWORD ? 
	cycle_count_upper_b DWORD ?				;;current stored cycle count (updated every time a bomb is unleashed from the sky) 
	cycle_count_lower_b DWORD ? 
	cycle_buffer_upper_b DWORD ?			;;Time elasped in between bombs being released from the sky 
	cycle_buffer_lower_b DWORD ? 			
	
	;;string data 
	fmtStrScore BYTE "Score: %i", 0			;; formated string to keep track of the score
	outStrScore BYTE 256 DUP(0)	
	
		;;strings to print during gamestart or while paused
	introStr1 BYTE "   Press 'SPACE' to pause the game, 'P' to Play, or 'R' to restart.    ", 0
	introStr2 BYTE "Use the mouse to control the pillow in order to catch the falling cats!", 0
	introStr3 BYTE "        Use the arrow keys, or 'A' 'D' keys, to move the fan.          ", 0
	introStr4 BYTE "     When cats are directly above the fan, they will fall slower!      ", 0 
	introStr5 BYTE "        Each subsequent cat will fall with greater acceleration.       ", 0
	introStr6 BYTE "           Faster cats will earn you more points per catch!            ", 0
	introStr7 BYTE "          Beware! If you catch a bomb, it will be GAME OVER!           ", 0
	introStr8 BYTE "    You will also earn points for survival time and missing bombs.     ", 0 
	introStr9 BYTE "             You will also loose points for missing cats!              ", 0 
	
		;;strings to print during gameover 
	gameOverStr1 BYTE "          GAME OVER!          ", 0
	gameOverStr2 BYTE "Press 'R' to restart the game.", 0
	
		;;strings to print when the player has beat the game
	beatGameStr1 BYTE "            CONGRATULATIONS!          ", 0 
	beatGameStr2 BYTE "You beat the game!                    ", 0
	beatGameStr3 BYTE "Try to see if you can beat your score!", 0
	beatGameStr4 Byte "Press 'R' to restart the game.        ", 0 
	
	;;sound data 
	SndPathBackground BYTE "background.wav", 0
	SndPathMeow BYTE "meow.wav", 0
	music_state BYTE ?						;;if 1, that means we need to play music. If 0, music is already playing 
	SndPathGameOver BYTE "gameover.wav", 0
	music_state2 BYTE ? 					;;if 1, that measn we need to play the game over sound. If 0, it is already playing 
	SndPathExplosion BYTE "explosion.wav", 0
.CODE



;;return 1 if bitmap 1 and bitmap 2 have overlapping x values (checks if the cat is above the fan)
CheckOverFan PROC oneX:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoBitmap:PTR EECS205BITMAP

	;;call CheckIntersect with the same y_pos for both bitmaps, therefore we will collide solely based on overlapping x positions
	INVOKE CheckIntersect, oneX, 100, oneBitmap, twoX, 100, twoBitmap	;;eax <- 1 or 0
	ret 
CheckOverFan ENDP
	
	


;; Returns 1 in eax if there is an intersection
CheckIntersect PROC USES ebx ecx edx edi esi oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP
	LOCAL oneRight:DWORD, oneLeft:DWORD, oneTop:DWORD, oneBottom:DWORD, 
			twoRight:DWORD, twoLeft:DWORD, twoTop:DWORD, twoBottom:Dword 
	
	;; Store pointers in registers to access bitmaps
	mov esi, oneBitmap
	mov edi, twoBitmap
	
	;;Initialize local variables 
	mov ebx, (EECS205BITMAP PTR[esi]).dwWidth	;;get Width of bitmap pointer 1
	sar ebx, 1 									;;ebx <- ebx / 2 = oneWidth/2 
	mov ecx, oneX								;;ecx <- oneX
	mov edx, ecx 								;;edx <- ecx 
	add edx, ebx 								;;edx <- oneX + oneWidth/2 
	mov oneRight, edx  							;;oneRight <- edx
	sub ecx, ebx 								;;ecx <- oneX - oneWidth/2
	mov oneLeft, ecx 							;;oneLeft <- ecx 
	
	mov ebx, (EECS205BITMAP PTR[esi]).dwHeight	;;get height of bitmap pointer 1
	sar ebx, 1 									;;ebx <- height / 2 
	mov ecx, oneY								;;ecx <- oneY
	mov edx, ecx 								;;edx <- oneY
	add edx, ebx 								;;edx <- edx + ebx = oney + height/2
	mov oneBottom, edx 							;;oneBottom <- edx
	sub ecx, ebx 								;;ecx <- ecx - ebx = oneY-height/2
	mov oneTop, ecx 							;;oneTop <- ecx 
	
	mov ebx, (EECS205BITMAP PTR[edi]).dwWidth	;;get width of the bitmap pointer 2
	sar ebx, 1 									;;ebx <- width/2
	mov ecx, twoX								;;ecx <- twoX 
	mov edx, ecx 								;;edx <- twoX
	add edx, ebx 								;;edx <- twoX + width/2 
	mov twoRight, edx 							;;twoRight <- edx 
	sub ecx, ebx 								;;ecx <- twoX - width/2
	mov twoLeft, ecx 							;;twoLeft <- ecx 
	
	mov ebx, (EECS205BITMAP PTR[edi]).dwHeight	;;get height of bitmap 2
	sar ebx, 1 									;;ebx <- height/2
	mov ecx, twoY								;;ecx <- TwoY
	mov edx, ecx 								;;ecx <- twoY
	add edx, ebx 								;;edx <- twoY + height/2
	mov twoBottom, edx 							;;twoBottom <- ecx 
	sub ecx, ebx 								;;ecx <- twoY - height/2
	mov twoTop, ecx 							;;twoTop <- ecx 
	
	;;Comparisions for Collision: If (oneLeft <= twoRight && oneRight >= twoLeft && oneBottom >= twoTop && oneTop <= twoBottom) -> collision detected
	;;All registers are valid to be used except esi and edi 
	mov eax, 0 
	
	mov ebx, oneLeft
	cmp ebx, twoRight 							;;if oneLeft > tworight, no collision possible
	jnle skip
	
	mov ebx, oneRight
	cmp ebx, twoLeft							;;if oneRight < twoLeft, no collision possible 
	jnge skip
	
	mov ebx, oneBottom
	cmp ebx, twoTop 							;if oneBottom < twoTop, no collision possible 
	jnge skip
	
	mov ebx, oneTop								
	cmp ebx, twoBottom 							;if oneTop > two bottom, no collision possible 	
	jnle skip
	
	mov eax, 1 									;all comparisions passed, collision detected 
	
skip:
	ret 
CheckIntersect ENDP



;;initialize global variables 
GameInit PROC USES eax ebx ecx esi edi edx
	LOCAL initialScore:DWORD, initialAccel:DWORD 
	
	;;generate random seed
	rdtsc 
	invoke nseed, eax 
	
	;;Drawing background centered, so that we start with empty background on restart
	mov esi, offset background							;;get effective address of background bitmap
    INVOKE BasicBlit, esi, 316, 237		
	
	;;Initial conditions for pillowNorm object 
	mov eax, offset pillowNorm							;;get effective address 
	mov (pillow_sprite PTR [eax]).x_pos, 320
	mov (pillow_sprite PTR [eax]).y_pos, 415
	mov (pillow_sprite PTR [eax]).state, 1				;;Pillow is not squished
	
	;;Initial condition for fan object 
	mov eax, offset game_fan							;;get effective address 
	mov (fan_sprite PTR [eax]).x_pos, 200
	mov (fan_sprite PTR [eax]).y_pos, 400
	
	;;Initial condition for cat objet(s) (and initialize next_cat and last_cat)
	;;beginning of loop 
	mov esi, offset game_cat							;;get effective address of beginning of cat array 
	mov next_cat, esi									;;next_cat <- esi 
	mov edi, esi										;;edi <- esi 
	add edi, sizeof game_cat 							;;edi <- esi + sizepf game_cat = pointer to one past the last cat struct
	mov last_cat, edi									;;last_cat <- edi 
	mov initialScore, 100							    ;;initialScore <- initial score value for the first cat 
	mov initialAccel, 30000								;;initialAccel <- fxpt initial acceleration 
	jmp eval_cat										

body_cat:
	mov edx, initialScore								;;edx <- initial score
	mov (cat_sprite PTR [esi]).score, edx 				;;set the score for each cat 
	add initialScore, 20 							    ;;increase the score for each cat by 20 points 
	invoke nrandom, 570 								;;generate random number between 0 and 570
	add eax, 35											;;shift random number range to 35 to 605, so cat does not initialize partly off screen 
	shl eax, 16											;;convert random number to fxpt for randomized initial x pos of the cat
	mov (cat_sprite PTR [esi]).x_pos, eax				;;set random initial x position of the cat 
	mov (cat_sprite PTR [esi]).y_pos, -2949120			;;set y positino to fxpt of -45, off the screen
	invoke nrandom, 20									;;get a random number between 0 and 20
	sub eax, 10											;;shift range to -10 to 10 
	sal eax, 16 										;;convert to fxpt 
	mov (cat_sprite PTR [esi]).x_vel, eax 				;;set random initial x velocity 
	mov (cat_sprite PTR [esi]).y_vel, 0					;;set 0 initial y_vel 
	mov ebx, initialAccel								;;ebx <- initialAccel 
	mov (cat_sprite PTR [esi]).y_accel, ebx				;;set constant acceleration for y dimention 
	shr ebx, 5										    ;;ebx <- ebx/32
	add initialAccel, 2000 								;;increase acceleration so that every cat falls faster than before 
	mov (cat_sprite PTR [esi]).y_accel_slowed, ebx 		;;set to fxpt of initialAccel/32 (acceleration if the fan is below the cat)
	mov (cat_sprite PTR [esi]).state, 1					;;cat is falling 
	mov (cat_sprite PTR [esi]).rotate_angle, 205000		;;fxpt angle to turn upside down
	mov (cat_sprite PTR [esi]).visible, 0				;;not active or visible 
	mov (cat_sprite PTR [esi]).wind, 0					;;cat is not blown-on by the fan (not above the fan) - sets when cat is above fan 
	mov (cat_sprite PTR [esi]).initial_wind_vel_dec, 1 	;;Cat has not yet been acted on by the fan - set when cat is above fan and cleared right away so applied code runs once
	add esi, type game_cat								;;increment to next cat in the array 

eval_cat:
	cmp esi, edi 										;;compare the current array pointer to one past the last array 
	jl body_cat 										;;if we are not at the end of the array, repeat 
	;;end loop 
	
	;;initialize cycle count, time inbetween unleashing cats from the sky, and time inbetween unleashing bombs from the sky 
	rdtsc												;;get cycle count, initialize into global variables 
	mov cycle_count_lower, eax
	mov cycle_count_lower_b, eax 
	mov cycle_count_upper, edx 
	mov cycle_count_upper_b, edx 
	mov cycle_buffer_lower, 0 							;;release cats every 2^32 cycles initially 
	mov cycle_buffer_upper, 1
	mov cycle_buffer_lower_b, 0							;;release bombs every 2x2^32 cycles initially 
	mov cycle_buffer_upper_b, 2 		
	
	;;begining of loop 
	;;initialize the bomb array (while initializing first and last bomb)
	mov esi, offset game_bomb 							;;esi <- pointer to first bomb 
	mov next_bomb, esi 
	mov edi, esi
	add edi, sizeof game_bomb 							;;edi <- pointer to last bomb 
	mov last_bomb, edi 
	jmp eval_bomb
	
body_bomb:
	invoke nrandom, 570 								;;generate random number between 0 and 570
	add eax, 35											;;shift random number range to 35 to 605 
	shl eax, 16											;;convert random number to fxpt for randomized initial x pos of the bomb
	mov (bomb_sprite PTR [esi]).x_pos, eax 				;;set random x position 
	mov (bomb_sprite PTR [esi]).y_pos, -2949120			;;set initial y position to fxpt of -45, off the screen 
	invoke nrandom, 20									;;get random number between 0 and 20 
	sub eax, 10											;;shift range to -10 to 10
	sal eax, 16 										;;convert to fxpt
	mov (bomb_sprite PTR [esi]).x_vel, eax				;;set random initial velocity in x direction
	mov (bomb_sprite PTR [esi]).y_vel, 0				;;set 0 initial v_vel 
	mov (bomb_sprite PTR [esi]).y_accel, 40000			;;set constant fxpt acceleration 
	mov (bomb_sprite PTR [esi]).visible, 0				;;the bomb is not currently active (not drawn) 
	mov (bomb_sprite PTR [esi]).state, 1				;;the bomb has not been exploded 
	add esi, type game_bomb								;;increment to next bomb 

eval_bomb:
	cmp esi, edi 
	jl body_bomb
	;;end of loop 
	
	;;game states 
	mov game_over, 0 									;;game is not over 
	mov game_state, 0									;;set the game state to paused on startup
	mov game_score, 0 									;;clear game score 
	mov beat_game_state, 0								;;player has not yet beat the game 
	
	;;set music state
	mov music_state, 1 									;;main music is not playing 
	mov music_state2, 1									;;game over music is not playing
	
	ret         ;; Do not delete this line!!!
GameInit ENDP





;;body of the game
GamePlay PROC USES esi edi eax ebx ecx edx
	LOCAL catEndPtr:DWORD
	
	;;see if we need to restart
	cmp KeyPress, 52h									;; see if the button R has been pressed
	jne no_restart					
	INVOKE GameInit										;;reset initial conditions
no_restart:
	
	;;see if it is game over 
	cmp game_over, 1 									;;game is over when game_over set to 1 
	je game_over_screen
	
	;;see if player has beat the game
	cmp beat_game_state, 1 								;;player has beat the game when the beat_game_state is set to 1 
	je beat_game_screen
	
	;;see if the pause button has been pressed 
	INVOKE CheckPause 									;;check to see if the space bar or the p button has been pressed
	cmp game_state, 1									;;if the game_state is not 1, do not run the body of GamePlay
	jne paused											;;we are paused (game_state = 0) 
	
	;;Drawing background centered 
	mov edi, offset background							;;get effective address of background bitmap
    INVOKE BasicBlit, edi, 316, 237						

	;;Draw the score of the game in the top left 
	push game_score 
	push offset fmtStrScore
	push offset outStrScore
	call wsprintf
	add esp, 12
	invoke DrawStr, offset outStrScore, 10, 10, 0
	
	;;Drawing Fan
	mov edx, offset game_fan							;;get effective address of fan
	
	INVOKE GetFanXPos									;;eax<-new x position based on keyboard
	mov (fan_sprite PTR [edx]).x_pos, eax 				;;update x-position
	INVOKE BasicBlit, (fan_sprite PTR [edx]).ptrBitmap, (fan_sprite PTR [edx]).x_pos, (fan_sprite PTR [edx]).y_pos 				;;draw the sprite
	
	;;Drawing Pillow 
	mov edi, offset pillowNorm 							;;esi <-  pointer to pillow sprite 
	
	INVOKE GetPillowXPos								;;eax <- updated position of the pillow
	mov (pillow_sprite PTR [edi]).x_pos, eax 			;;pillowNorm.x_pos <- eax = mouse position
	
	cmp (pillow_sprite PTR [edi]).state, 1				;;Draw the squished pillow if the state is 0 
	jne skip
	INVOKE BasicBlit, (pillow_sprite PTR [edi]).ptrBitmap, (pillow_sprite PTR [edi]).x_pos, (pillow_sprite PTR [edi]).y_pos		;; draw the normal pillow 
	jmp skip6
skip: 
	INVOKE BasicBlit, (pillow_sprite PTR [edi]).ptrBitmap_s, (pillow_sprite PTR [edi]).x_pos, (pillow_sprite PTR [edi]).y_pos	;;Draw the squished pillow
skip6:

	;;Call this function see if enough time has passed in order to unleash the next cat from the sky
	mov eax, next_cat 									;;eax <- next_cat pointer 
	cmp eax, last_cat 									;;compare current cat with one past the last_cat in the array  
	jl unleashCat										;;if we have not yet unleashed all the cats, call UnleashEachCat 
	
	INVOKE CheckNoCatVisible							;;this means we have unleashed all the cats. See when the last one unleashed is no longer visible 
	cmp eax, 0 											;;if Eax = 1, than there are no more cats visible, and the player beat the game 
	je no_more_cats 									;;if eax = 0, there are still no more cats visible, but wait until the last cat dissipears to trigger the beat game screen 
	mov beat_game_state, 1 								;;player has beat the game 
	jmp skip_pause 										;;might as well jump to return

unleashCat:
	INVOKE UnleashEachCat								;;unleash next cat from the sky 

no_more_cats:
	;;Drawing Cat in a big loop, updating the proper fields if the cat is visible (if the cat is not visible, then skip all updates and do not draw)	
	mov esi, offset game_cat							;;obtain effective address of first element of the cat array
	jmp eval_cat_main

body_cat_main:
	cmp (cat_sprite PTR [esi]).visible, 0				;;Do not draw or update cat if not visible 
	je skip3 
	
	mov ebx, (cat_sprite PTR [esi]).x_pos				;;Convert positions from FXPT to Int
	mov ecx, (cat_sprite PTR [esi]).y_pos 
	shr ebx, 16
	shr ecx, 16
	
	INVOKE CheckOverFan, ebx, (cat_sprite PTR [esi]).ptrBitmap, (fan_sprite PTR [edx]).x_pos, (fan_sprite PTR [edx]).ptrBitmap		;;check if the cat is directly above the fan
	cmp eax, 1											;;if eax = 1, the cat is directly over the fan
	jne skip8
	mov (cat_sprite PTR [esi]).wind, 1					;;if the cat is over the fan, set the wind state to 1
	cmp (cat_sprite PTR [esi]).initial_wind_vel_dec, 1	;;if the initial velocity decrement has not yet been applied, apply it ONLY ONCE 
	jne skip7
	mov eax, (cat_sprite PTR [esi]).y_vel  				;;eax <- y_vel
	shr eax, 1											;;eax <- y_vel/2
	mov (cat_sprite PTR [esi]).y_vel, eax 				;;update y_vel with half the original speed (only decreasing the acceleration is not noticeable)
	mov (cat_sprite PTR [esi]).initial_wind_vel_dec, 0 	;;clear the initial velocity decrement state after it has been applied, so it only applies once 
	jmp skip7
	
skip8:
	mov (cat_sprite PTR [esi]).wind, 0					;;The cat is not over the fan (or no longer over the fan), thus reset the wind state to 0
	mov (cat_sprite PTR [esi]).initial_wind_vel_dec, 1	;;reset the initial wind vel decrement state to 1 so it may be applied again if the cat appears above the fan later on
	
skip7:
	INVOKE CheckIntersect, ebx, ecx, (cat_sprite PTR [esi]).ptrBitmap,		;;Check for the cat intersecting the pillow 
							(pillow_sprite PTR [edi]).x_pos, (pillow_sprite PTR [edi]).y_pos, (pillow_sprite PTR [edi]).ptrBitmap
							
	cmp eax, 1 											;;eax<-1 if collision detected
	jne skip5
	cmp (cat_sprite PTR [esi]).state, 0					
	je skip9											;;if state already set to zero (cat has been caught), no need to run the next few lines for efficiency
	mov (cat_sprite PTR [esi]).y_accel, 0				;;If the pillow has caught the cat, stop accelerating and moving vertically
	mov (cat_sprite PTR [esi]).y_vel, 0 				
	mov (cat_sprite PTR [esi]).state, 0					;;set state to zero to reflect that the cat has been caught
	mov eax, (cat_sprite PTR [esi]).score 				;;get the score/points of the current cat 
	add game_score, eax 								;;increment the game score by the score of the current cat 
	mov (cat_sprite PTR [esi]).y_accel_slowed, 0		;;stop accelerating even if above the fan 
	mov (cat_sprite PTR [esi]).x_vel, 655360 			;;fxpt of 10, give the cat a constant horizontal velocity after it has been caught so it moves offscreen
	
skip9:
	mov (pillow_sprite PTR [edi]).state, 0				;;After collision, we draw squished pillow. Pillow resets once the cat clears the screen

skip5:
	INVOKE GetCatYVel, esi								;;update cat velocity due to acceleration
	mov (cat_sprite PTR [esi]).y_vel, eax 
	
	INVOKE GetCatYPos, esi								;;update cat position due to velocity
	mov (cat_sprite PTR [esi]).y_pos, eax 
	
	INVOKE GetCatXPos, esi 								;;update cat position due to velocity
	mov (cat_sprite PTR [esi]).x_pos, eax 
	
	mov ebx, (cat_sprite PTR [esi]).x_pos				;;convert xpos and ypos into integar to draw
	mov ecx, (cat_sprite PTR [esi]).y_pos
	shr ebx, 16
	shr ecx, 16
	
	cmp (cat_sprite PTR [esi]).state, 1					;;Get state of the cat, rotate if the state is 1 (falling) -draws upside down
	jne skip2
	INVOKE RotateBlit, (cat_sprite PTR [esi]).ptrBitmap, ebx, ecx, (cat_sprite PTR [esi]).rotate_angle		;;Draw upside down cat falling
	jmp skip3
skip2:
	INVOKE BasicBlit, (cat_sprite PTR [esi]).ptrBitmap, ebx, ecx 		;;if the cat is caught, draw right side up
skip3: 
	add esi, type game_cat
	
eval_cat_main:
	cmp esi, last_cat
	jl body_cat_main
	;;end of loop for updating/drawing visible cats 
	
	;;Call this function see if enough time has passed in order to unleash the next bomb from the sky
	mov eax, next_bomb 									;;eax <- next_bomb pointer 
	cmp eax, last_bomb 									;;compare current bomb with one past the last_bomb in the array  
	jge no_more_bombs 									;;we have already unleashed all the bomb 
	INVOKE UnleashEachBomb								;;unleash the next bomb from the sky 
no_more_bombs:

	;;Loop through all elements in the bomb array, and if the bomb is visible, draw and update them. Keep edi as pointer to pillow_sprite struct
	mov esi, offset game_bomb 							;;get pointer to the first bomb 
	jmp eval_bomb_main
	
body_bomb_main:
	cmp (bomb_sprite PTR [esi]).visible, 1				;;if the bomb is not active or visible, do not draw 
	jne no_bomb 
	
	;;check if bomb intersect with the pillow
	mov ebx, (bomb_sprite PTR [esi]).x_pos				;;Convert positions from FXPT to Int
	mov ecx, (bomb_sprite PTR [esi]).y_pos 
	shr ebx, 16
	shr ecx, 16
	INVOKE CheckIntersect, ebx, ecx, (bomb_sprite PTR [esi]).ptrBitmap,					;;Check for the bomb intersecting the pillow 
							(pillow_sprite PTR [edi]).x_pos, (pillow_sprite PTR [edi]).y_pos, (pillow_sprite PTR [edi]).ptrBitmap
	cmp eax, 1 
	jne didNotCatchBomb									;;If no intersect, we did not catch the bomb.  Skip below code 
	cmp (bomb_sprite PTR [esi]).state, 0				;;if state of bombe is already 0, skip next lines for efficiency
	je skipBombUpdates 			
	mov exploded_bomb_ptr, esi							;;bomb is caught, store the pointer to the current bomb 
	mov game_over, 1 									;;set state to game over 
	mov (bomb_sprite PTR [esi]).y_accel, 0				;;stop bomb motion 
	mov (bomb_sprite PTR [esi]).y_vel, 0
	mov (bomb_sprite PTR [esi]).x_vel, 0 
	
skipBombUpdates:										;;no matter what, set the state to 0 denoting that bomb is caught 
	mov (bomb_sprite PTR [esi]).state, 0

didNotCatchBomb:										
	;;update bomb position
	INVOKE GetBombYVel, esi									;;update bomb velocity due to acceleration
	mov (bomb_sprite PTR [esi]).y_vel, eax 
	
	INVOKE GetBombYPos, esi									;;update bomb position due to velocity
	mov (bomb_sprite PTR [esi]).y_pos, eax 
	
	INVOKE GetBombXPos, esi 								;;update bomb position due to velocity
	mov (bomb_sprite PTR [esi]).x_pos, eax 
	
	mov ebx, (bomb_sprite PTR [esi]).x_pos					;;convert xpos and ypos into integar to draw
	mov ecx, (bomb_sprite PTR [esi]).y_pos
	shr ebx, 16
	shr ecx, 16
	
	cmp (bomb_sprite PTR [esi]).state, 1
	jne draw_explode
	INVOKE BasicBlit, (bomb_sprite PTR [esi]).ptrBitmap, ebx, ecx 		;;we draw normal bomb if the state is 1 (not caught) 
	jmp no_bomb 
draw_explode:
	INVOKE BasicBlit, (bomb_sprite PTR [esi]).ptrBitmap_e, ebx, ecx 	;;we draw exploded bomb if the state is 0 (caught) 
no_bomb:
	add esi, type game_bomb												;;increment to next bomb 
	
eval_bomb_main:
	cmp esi, last_bomb									;;ensures that we loop through all the bombs 
	jl body_bomb_main
	;;end of the bomb loop
	
	jmp skip_pause 										;;do not draw pause/intro/game over/beat game screen, jump to return 

;;draw the screen once the player beats the game 
beat_game_screen:
	mov edi, offset background							;;get effective address of background bitmap, and draw it 
    INVOKE BasicBlit, edi, 316, 237	
	INVOKE DrawStr, offset beatGameStr1, 175, 140, 0	;;Print the neccesary messages, and the score 
	push game_score 
	push offset fmtStrScore
	push offset outStrScore
	call wsprintf
	add esp, 12
	INVOKE DrawStr, offset outStrScore, 175, 155, 0
	INVOKE DrawStr, offset beatGameStr2, 175, 170, 0 
	INVOKE DrawStr, offset beatGameStr3, 175, 185, 0
	INVOKE DrawStr, offset beatGameStr4, 175, 200, 0
	jmp skip_pause										;;jmp to return 


;;game over screen 
game_over_screen:
	mov edi, offset background							;;get effective address of background bitmap and draw it 
    INVOKE BasicBlit, edi, 316, 237	
	mov esi, exploded_bomb_ptr							;;get pointer to the bomb that caused the player to lose 
	mov ebx, (bomb_sprite PTR [esi]).x_pos				;;convert xpos and ypos into integar to draw
	mov ecx, (bomb_sprite PTR [esi]).y_pos
	shr ebx, 16
	shr ecx, 16
	INVOKE BasicBlit, (bomb_sprite PTR [esi]).ptrBitmap_e, ebx, ecx		;;draw the bomb that caused the loss 
	INVOKE DrawStr, offset gameOverStr1, 200, 140, 0	;;print the necessary strings 
	push game_score 
	push offset fmtStrScore
	push offset outStrScore
	call wsprintf
	add esp, 12
	INVOKE DrawStr, offset outStrScore, 200, 155, 0
	INVOKE DrawStr, offset gameOverStr2, 200, 170, 0
	
	;;play game over sound 
	cmp music_state2, 1									;;if the state is 0, we are already playing the game over sound -> do not play again 
	jne music_skip2
	pushad
	INVOKE PlaySound, offset SndPathExplosion, 0, SND_FILENAME OR SND_ASYNC				;;play explosion if the state is 1 
	popad
	pushad
	invoke PlaySound, offset SndPathGameOver, 0, SND_FILENAME OR SND_ASYNC				;;play game over sound 
	popad
	mov music_state2, 0 								;;set state to 0 so that we don't play souns repeatedly every time GamePlay is called 
	
music_skip2:
	jmp skip_pause 										;;skip to return 
	
;;game is paused, draw the intro instructions 
paused:
	invoke DrawStr, offset introStr1, 35, 120, 0		;;draw instructions 
	invoke DrawStr, offset introStr2, 35, 135, 0 
	invoke DrawStr, offset introStr3, 35, 150, 0
	invoke DrawStr, offset introStr4, 35, 165, 0
	invoke DrawStr, offset introStr5, 35, 180, 0
	invoke DrawStr, offset introStr6, 35, 195, 0
	invoke DrawStr, offset introStr7, 35, 210, 0
	invoke DrawStr, offset introStr8, 35, 225, 0
	invoke DrawStr, offset introStr9, 35, 240, 0
	
	;;play background music if music state is 1 
	cmp music_state, 1									;;if state is 1, then we play the background music. Since the state is initially 1, 
														;;and we start in the paused state, the music should play upon loading the game 
	jne skip_pause 
	
	pushad
	invoke PlaySound, offset SndPathBackground, 0, SND_FILENAME OR SND_ASYNC
	popad
	mov music_state, 0 									;;move the state to 0 to ensure the music is not played every time GamePlay is called. 

skip_pause:													
	ret         ;; Do not delete this line!!!
GamePlay ENDP




;;Updates the pillow x position based on the mouse
;;returns x position in eax 
GetPillowXPos PROC USES esi 

	mov esi, offset MouseStatus							;;get mouse status pointer 
	mov eax, (MouseInfo PTR [esi]).horiz 				;;return the mouse x position

skip:
	ret
GetPillowXPos ENDP 




;;Updates the fan x position based on keyboard 
;;return x position in eax 
GetFanXPos PROC USES esi
	
	;;Get current x position of the fan 
	mov esi, offset game_fan							;;esi<-effective address of gan
	mov eax, (pillow_sprite PTR [esi]).x_pos			;;eax<-current x position
	
	;;check to see if the left key or the 'A' key is pressed
	cmp KeyPress, 41h
	je left
	cmp KeyPress, 25h 
	jne next

left: 
	cmp eax, 30											;;do not move left if the fan is on the left edge 
	jl skip
	sub eax, 15											;;eax<-updated position after moving left by 15 pixels
	jmp skip 

next: 
	;;check to see if right key or "D" key is pressed 
	cmp KeyPress, 44h
	je right
	cmp KeyPress, 27h
	jne skip
	
right:
	cmp eax, 610										;;do not move right if the fan is on the right edge 
	jg skip
	add eax, 15											;;eax<-updated position after moving right by 15 pixels
	
skip:
	ret
GetFanXPos ENDP 




;;Updates the Cat's y position based on velocity
;;return y pos in eax 
GetCatYPos PROC USES esi catSpritePtr:DWORD
	
	;;Get current y position and y velocity of the cat
	mov esi, catSpritePtr								;;eax <-effective address of the cat 
	mov eax, (cat_sprite PTR [esi]).y_pos 				
	
	;;if y_pos is off the screen, do not move 
	cmp eax, 34406400  									;;fxpt of 525 (off the screen)
	jge skip 
	
	;;add velocity to position
	add eax, (cat_sprite PTR [esi]).y_vel 				;;eax <- eax + y_vel 
	jmp skip2
	
skip:
	mov (cat_sprite PTR [esi]).visible, 0				;;if the cat is off the screen, clear the visibility state so we no longer draw it
	invoke PlayMeow										;;play sound effect 
	sub game_score, 100									;;Player lose points for missing cats 
skip2: 
	ret
GetCatYPos ENDP




;;Updates the cat's y velocity based on acceleration
;;return y vel in eax 
GetCatYVel PROC USES esi ebx catSpritePtr:DWORD

	;;get current y velocity and y acceration and y position
	mov esi, catSpritePtr								;;esi <- effective address of the cat
	mov eax, (cat_sprite PTR [esi]).y_vel 				
	
	cmp (cat_sprite PTR [esi]).wind, 1					;;If the cat is above the fan, then we use the slower acceleration
	jne skip3 
	mov ebx, (cat_sprite PTR [esi]).y_accel_slowed		;;slower acceleration
	jmp skip4
skip3:
	mov ebx, (cat_sprite PTR [esi]).y_accel				;;faster acceleration (cat is not above the fan) 
skip4: 
	
	;;Add acceleration to velocity 
	add eax, ebx 										;;eax <- velocity + acceleration 

	ret
GetCatYVel ENDP




;;updates the Cat's x position based on it's velocity
;;return x pos in eax 
GetCatXPos PROC USES esi edi catSpritePtr:DWORD
	
	;;get current x position and velocity
	mov esi, catSpritePtr								;;get effective address of cat into esi 
	mov eax, (cat_sprite PTR [esi]).x_pos
	
	add eax, (cat_sprite PTR [esi]).x_vel 				;;eax <- eax + x_vel 
	
	cmp (cat_sprite PTR [esi]).state, 1					;;see if the cat is falling, or being caught 
	je isStillFalling
	
	;;cat has been caught, let it move offscreen 
	cmp eax, 44236800									;;fxpt of 675 (off the screen to the right)
	jl skip
	mov (cat_sprite PTR [esi]).visible, 0				;;stop drawing the cat off screen 
	mov edi, offset pillowNorm
	mov (pillow_sprite PTR [edi]).state, 1				;;draw the normal pillow (instead of the squished version)
	jmp skip 
	
	;;cat has not yet been caught 
isStillFalling: 
	cmp eax, 39649280									;;fxpt of 635 (should reflect at this point)
	jl no_flip
	neg (cat_sprite PTR [esi]).x_vel					;;reflect x velocity if cat hit right edge 

no_flip:
	cmp eax, 2293760									;;fxpt of 35, should reflect
	jg skip 
	neg (cat_sprite PTR [esi]).x_vel					;;reflect x vel if cat hit left edge 

skip:
	ret 
GetCatXPos ENDP





;;check if the pause button has been pressed
CheckPause PROC 
	cmp KeyDown, 20h									;;as long as the space bar has been pressed at some point, we paused
	jne skip		
	mov game_state, 0 									;;pause the game
skip:
	cmp KeyDown, 50h									;;if the p button has been pressed at any point, we play 
	jne skip2
	mov game_state, 1									;;play the game 
skip2:
	ret
CheckPause ENDP



;;check the time elpased since the last released cat in order to know when to release the next cat from the sky (set the visible state to 1 to release)
UnleashEachCat PROC USES esi eax edx 
	rdtsc 													;;get the current cycle count
	sub eax, cycle_count_lower 								;;use sub and sbb to implement {edx, eax} <- current cycle count - past stored cycle count
	sbb edx, cycle_count_upper 								;; {edx, eax} represents the time elaspsed since last unleashed cat 
	
	cmp edx, cycle_buffer_upper								;;compare upper 32 bits of elapsed time with upper 32 bits of a 64 bit constant 
	jb no_action											;;if current upper 32 bits of elapsed time is smaller (unsigned) than the constant,
															;;	not enough time has elapsed yet so we don't unleash a cat
	ja action												;;if the upper 32 bits of elapsed time is larger (unsigned) than the constant, than 
															;;  enough time has passed to unleash the cat 
	cmp eax, cycle_buffer_lower								;; if the upper 32 bits of elapsed time is equal to the constant, 
															;;  we compare the lower 32 bits
	jb no_action											;;if the lower 32 bits of elasped time is below the constant, enough time has yet not passed to 
															;;  unleash a cat. Otherwise we will unleash a cat. 
action:
	;;set next cat visible, increment to the next cat 
	mov esi, next_cat										;;esi <- next_cat (technically current cat) 
	mov (cat_sprite PTR [esi]).visible, 1					;;set current cat visible 
	add esi, type game_cat									;;increment next_cat pointer to point to the next cat
	mov next_cat, esi
	
	;;decrement the buffer time between each cat released 
	sub cycle_buffer_lower, 71582788 						;;subtract cycle_buffer by 2^31/30 so that the final few cats are released twice as fast as initially 
	sbb cycle_buffer_upper, 0 
	
	;;get the current cycle count, and update the global variables so that we know when to release the next cat 
	rdtsc
	mov cycle_count_lower, eax
	mov cycle_count_upper, edx 
	
no_action:
	ret
UnleashEachCat ENDP




;;Check the time elapsed since the last released bomb in order to know when to release the next bomb from the sky (set the visible state to 1 to release)
UnleashEachBomb PROC USES eax edx esi
	rdtsc														;;{edx, eax} <- current cycle count - last cycle count when bomb was released 
	sub eax, cycle_count_lower_b
	sbb edx, cycle_count_upper_b
	
	cmp edx, cycle_buffer_upper_b								;;compare time elasped since last bomb release with the global buffer
	jb no_action												;;release next bomb when time elapsed equals the required buffer time inbetween releases 
	ja action 
	cmp eax, cycle_buffer_lower_b
	jb no_action
	
action:
	;;set next bomb visible, increment to the bomb after this one 
	mov esi, next_bomb
	mov (bomb_sprite PTR [esi]).visible, 1						;;release current bomb (next_bomb = current bomb) 
	add game_score, 50											;;add to score whenever bomb drops (this a time bonus) 
	add esi, type game_bomb										;;increment to the next bomb 
	mov next_bomb, esi
	
	;;decrease buffer time between sequential bomb release
	sub cycle_buffer_lower_b, 183165576							;;subtract cycle buffer by 2^31/15. 
																;;this timing ensures that 13 bombs will fall in the span of 30 cats being released
	sbb cycle_buffer_upper_b, 0 
	
	;;get current cycle count, and update the global variables so that we know when to release the next bomb
	rdtsc
	mov cycle_count_lower_b, eax
	mov cycle_count_upper_b, edx 
	
no_action:
	ret
UnleashEachBomb ENDP





;;updates the bomb's y position 
;;return y pos in eax 
GetBombYPos PROC USES esi bombSpritePtr:DWORD 

	;;Get current y position and y velocity of the bomb 
	mov esi, bombSpritePtr
	mov eax, (bomb_sprite PTR [esi]).y_pos
	
	;;if y position is off the screen, do not move 
	cmp eax, 34406400
	jge skip
	
	;;add velocity to position 
	add eax, (bomb_sprite PTR [esi]).y_vel 
	jmp skip2 
	
skip:
	mov (bomb_sprite PTR [esi]).visible, 0 				;;set the bomb visible state to 0 if it falls below the screen
	add game_score, 100 								;;add to the players score for missing a bomb 

skip2: 
	ret
GetBombYPos ENDP 




;;updates the bomb's y velocity based on acceleration 
;;return y vel in eax 
GetBombYVel PROC USES esi bombSpritePtr:Dword
	
	;;get current y velocity and y acceleration
	mov esi, bombSpritePtr
	mov eax, (bomb_sprite PTR [esi]).y_vel   
	
	;;add accel to vel 
	add eax, (bomb_sprite PTR [esi]).y_accel
	ret
GetBombYVel ENDP




;;updates the bomb's x position based on acceleration 
;;return x pos in eax 
GetBombXPos PROC USES esi bombSpritePtr:Dword
	
	;;get current x pos and vel
	mov esi, bombSpritePtr
	mov eax, (bomb_sprite PTR [esi]).x_pos

	;;add vel to pos 
	add eax, (bomb_sprite PTR [esi]).x_vel 
	
	;;implement boundery reflection 
	cmp eax, 39976960									;;fxpt of 610, we should flip direction
	jl no_flip
	neg (bomb_sprite PTR [esi]).x_vel					;;negate x velocity to flip when in contact with right edge 
	
no_flip:
	cmp eax, 1966080									;;fxpt of 30, we should flip direction
	jg no_flip2
	neg (bomb_sprite PTR [esi]).x_vel					;;negate x velocity to flip when in contact with left edges 
	
no_flip2:
	ret
GetBombXPos ENDP




;;plays the meow sound effect 
PlayMeow PROC 
	pushad
	invoke PlaySound, offset SndPathMeow, 0, SND_FILENAME OR SND_ASYNC 	;;this will halt the background music ... 
	popad 
	mov music_state, 1									;;set the state to 1 so that the next time the game is paused, the background music starts paying again
	ret
PlayMeow ENDP




;;Check when no cats are visible, so that we know when the player has beat the game 
;;returns 0 if there are still cats visible, returns 1 if no cats are visible (in eax) 
CheckNoCatVisible PROC USES esi edi 

	mov esi, offset game_cat 							;;get pointer to first cat 
	mov edi, last_cat 									;;get pointer to one past the last cat 
	mov eax, 1											;;eax <- 1 
	jmp eval 
	
body: 
	cmp (cat_sprite PTR [esi]).visible, 0 				;;if the current cat is not visible, we skip the body 
	je skip 
	mov eax, 0											;;once one cat is found to be visible, we break and return 0
	jmp break 
	
skip: 	
	add esi, type game_cat 								;;increment to next cat 
	
eval: 
	cmp esi, edi 										;;ensure that we loop through all cats 
	jl body 

break: 
	ret
CheckNoCatVisible ENDP 

END