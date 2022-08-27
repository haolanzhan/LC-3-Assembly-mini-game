; #########################################################################
;
;   lines.asm - Assembly file for CompEng205 Assignment 2
;	Name: Haolan Zhan
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc

.DATA

	;; If you need to, you can place global variables here
	
.CODE
	

;; Don't forget to add the USES the directive here
;;   Place any registers that you modify (either explicitly or implicitly)
;;   into the USES list so that caller's values can be preserved
	
;;   For example, if your procedure uses only the eax and ebx registers
;;      DrawLine PROC USES eax ebx x0:DWORD, y0:DWORD, x1:DWORD, y1:DWORD, color:DWORD
DrawLine PROC USES eax ebx ecx edx x0:DWORD, y0:DWORD, x1:DWORD, y1:DWORD, color:DWORD
	;; Feel free to use local variables...declare them here
	;; For example:
	;; 	LOCAL foo:DWORD, bar:DWORD
	LOCAL delta_x:DWORD, delta_y:DWORD, inc_x:DWORD, inc_y:DWORD, error_var:DWORD, curr_x:DWORD, curr_y:DWORD, prev_error:DWORD
	
	;; Place your code here
	mov eax, x1 						;;eax <- x1 
	sub eax, x0							;;eax <- x1 - x0 
	jge skip1							;;jump if x1 >= x0 
	neg eax								;;if x1 < x0, negate the difference to make it positive
skip1:
	mov delta_x, eax 					;;delta_x <- eax (move eax into delta_x)
		
	mov eax, y1 						;;eax <- y1 
	sub eax, y0							;;eax <- y1 - y0 
	jge skip2							;;jump if y1 >= y0 
	neg eax								;;if y1 < y0, negate the difference to make it positive
skip2:
	mov delta_y, eax 					;;delta_y <- eax (move eax into delta_y)
	
	mov eax, x0							;; eax <- x0 (to prevent mem-mem addressing)
	cmp eax, x1 						;;<- x0 - x1 
	jl if_less1							;;jump if x0 < x1
	mov inc_x, -1						;;inc_x <- -1 (if x0 >= x1, this is the else block)
	jmp continue1						;;skip the true block
if_less1:
	mov inc_x, 1 						;;inc_x <- 1 (this is the true block) 
continue1: 
	
	mov eax, y0							;;eax<- y0 (to prevent mem-mem addressing)
	cmp eax, y1 						;;<- y0 - y1 
	jl if_less2							;;jump if y0 < y1 (jump to true block)
	mov inc_y, -1						;;inc_y <- -1 (if y0 >= y1, this is the else block)
	jmp continue2						;;skip the true block
if_less2:
	mov inc_y, 1 						;;inc_y <- 1 (this is the true block) 
continue2: 
	
	mov eax, delta_x					;;eax <- delta_x
	mov ebx, delta_y					;;ebx <- delta_y
	cmp eax, ebx						;;<- delta_x - delta_y
	jg if_greater1						;;jump if delta_x > delta_y (jump to true block)
	shr ebx, 1							;;ebx <- ebx >> 1 = delta_y / 2^1 (else block) 
	neg ebx								;;ebx <- -ebx 
	mov error_var, ebx 					;;error_var <- ebx 
	jmp continue3						;;skip the true block
if_greater1:
	shr eax, 1							;;eax <- delta_x >> 1 = delta_x / 2^1 (true block)
	mov error_var, eax					;;error_var <- eax 
continue3: 
	
	mov eax, x0							;;eax <- x0 (prevent mem-mem addressing)
	mov curr_x, eax						;;curr_x <- x0
	mov eax, y0 						;;eax <- y0 (prevent mem-mem addressing)
	mov curr_y, eax 					;;curr_y <- y0 
	
	INVOKE DrawPixel, curr_x, curr_y, color  ;;Call DrawPixel with the following parameters

eval:									;;testing the conditions of the loop
	mov eax, curr_x 					;;eax <- curr_x (to prevent mem-mem addressing)
	mov ebx, curr_y						;;ebx <- curr_y (to prevent mem-mem addressing)
	cmp eax, x1 						;;<- eax - x1 = curr_x - x1 
	jne shortcut2body					;;if curr_x != x1, the loop contition is true, and we skip to the body of the loop
	cmp ebx, y1 						;;if curr_x = x1, compute the second comparition: <- curr_y - y1 
	je break1 							;;if curr_y = y1, we break out of this loop 
shortcut2body:
	INVOKE DrawPixel, curr_x, curr_y, color 	;;Call DrawPixel with the following parameters
	mov ecx, error_var					;;ecx <- error_var (to prevent mem-mem addressing)
	mov prev_error, ecx					;;prev_error <- ecx = error_var 
	mov edx, delta_x 					;;edx <- delta_x (to prevent mem-mem addressing)
	neg edx 							;;edx <- -delta_x 
	cmp prev_error, edx 				;;<- prev_error - edx (compares prev_error and -delta_x)
	jle skip3  							;;if prev_error <= -delta_x, skip the true block 
	sub ecx, delta_y 					;;if prev_error > -delta_x, ecx <- ecx - delta_y (error_var <- error_var - delta_y)
	mov error_var, ecx					;;error_var <- ecx 
	add eax, inc_x 						;;eax <- eax + inc_x (curr_x <- curr_x + inc_x) 
	mov curr_x, eax 					;;curr_x < eax 
skip3:
	mov edx, delta_y					;;edx <- delta_y (to prevent mem-mem addressing) 
	cmp prev_error, edx 				;;<- prev_error - edx (compares prev_error and delta_y)
	jge skip4							;;if prev_error >= delta_y, skip the true block
	add ecx, delta_x 					;;true block: ecx <- ecx + delta_x (error_var <- error_var + delta_x)
	mov error_var, ecx 					;;error_var <- ecx 
	add ebx, inc_y 						;;ebx <- ebx + inc_y (curr_y <- curr_y + inc_y) 
	mov curr_y, ebx						;;curr_y <- ebx 
skip4:
	jmp eval 							;;loop back to evaluate the conditions 
break1: 
	
	ret        	;;  Don't delete this line...you need it
DrawLine ENDP




END
