; #########################################################################
;
;   trig.asm - Assembly file for CompEng205 Assignment 3
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include trig.inc

.DATA

;;  These are some useful constants (fixed point values that correspond to important angles)
PI_HALF = 102943           	;;  PI / 2
PI =  205887	                ;;  PI 
TWO_PI	= 411774                ;;  2 * PI 
PI_INC_RECIP =  5340353        	;;  Use reciprocal to find the table entry for a given angle ;;int value is 81.49
	                        ;;              (It is easier to use than divison would be)


	;; If you need to, you can place global variables here
	
.CODE

; Don't forget to use USES for saving registers 
FixedSin PROC USES ebx edx angle:FXPT
	LOCAL do_negate:DWORD
	
	mov do_negate, 0 
	mov eax, angle   			; eax <- angle
	
	cmp eax, 0					; compare eax and 0
	jnl continue3				; if angle >= 0, skip  
	neg eax						; if angle < 0, eax <- -eax 
	mov do_negate, 1			; set do_negate as a boolean true in order to negate the results at the end 
	
continue3:	
	jmp eval1					; jump to while loop
body1:
	sub eax, TWO_PI 			; eax <- eax - 2PI = angle - 2PI 
eval1:
	cmp eax, TWO_PI				
	jge body1					; goto body if eax >= 2PI, otherwise we have a correct range of [0, 2PI)
 
	;eax should b in the range of [0,2pi) by now 
	cmp eax, PI 				; <- eax - PI
	jg greater2					; if eax > PI, we must subtract PI from eax and negate the result at the end
	je equal2					; if eax = PI, we just return 0 
	jmp continue2 				; if eax < PI, we continue to the section where the range is [0, pi) 
	
greater2: 
	cmp do_negate, 1 			; Check if do_negate is already 1
	je skip2					; If do_negate = 1, set do_negate to 0 (double negative) 
	mov do_negate, 1			; represent do_negate as a boolean true 
	jmp skip3					; skip 
skip2:
	mov do_negate, 0			; do_negate <- 0
skip3:
	sub eax, PI 				; eax <- eax - PI = angle - PI 
	jmp continue2 				; continue to the section where the range is [0, pi)

equal2:	
	mov eax, 0;					; eax <- 0
	jmp skip1;					; skip to return 

continue2:
	;eax should be in the range of [0, pi) by now 
	cmp eax, PI_HALF 			; <- eax - PI_HALF
	jg greater1	 				; if eax > PI/2, we must find PI-eax 
	je equal					; if eax = PI/2, we return 1 
	jmp continue1				; if eax < Pi/2, we directly look up the index in the SINTAB table 
	
greater1:
	mov edx, PI					; edx <- PI
	sub edx, eax 				; edx <- edx - eax = PI - angle 
	mov eax, edx 				; eax <- edx 
	jmp continue1 				; continue to use the SINTAB table
	
equal:
	mov eax, 65536				; return value of 1 if Input is pi/2 + k*pi 
	jmp skip1					; skip to return 
	
	;eax should be in the range of [0, pi/2) by now 
continue1: 
	mov ebx, PI_INC_RECIP		; ebx <- PI_INC_RECIP
	imul ebx					; {edx, eax} <- angle * PI_INC_RECIP (binary point should be between edx, eax)
	xor eax, eax 
	mov ax, [SINTAB + 2 * edx]  ; get the edx'th entry of the sintable word array, pretty much garantee a rounding down for the index stored in edx 
	cmp do_negate, 1; 			; check if do_negate is set to 1
	jne skip1					; if not, we return 
	neg eax; 					; eax <- -eax 
	
skip1:
	ret			; Don't delete this line!!!
FixedSin ENDP 
	
FixedCos PROC USES ebx angle:FXPT

	mov ebx, angle 				; eax <- FXPT 
	add ebx, PI_HALF			; eax <- eax + PI/2 = FXPT+PI/2
	INVOKE FixedSin, ebx 		; eax <- sin(eax) = sin(FXPT + PI/2) 
	
	ret			; Don't delete this line!!!	
FixedCos ENDP	
END
