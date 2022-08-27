; #########################################################################
;
;   blit.asm - Assembly file for CompEng205 Assignment 3
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc
include trig.inc
include blit.inc


.DATA

	;; If you need to, you can place global variables here
	
.CODE

DrawPixel PROC USES eax ebx ecx edx x:DWORD, y:DWORD, color:DWORD
	
	mov eax, x						;eax<-x
	mov ebx, y 						;ebx<-y
	mov ecx, color					;ecx <- color 
	
	cmp eax, 0						
	jnl skip_dp1 					;if eax >= 0, skip
	ret
	;;mov eax, 0 						;if eax < 0, we are out of bounds, set eax to 0
skip_dp1:

	cmp eax, 636					
	jng skip_dp2					;if eax <= 639, skip
	ret
	;;mov eax, 639					;if eax > 639, we are out of bounds, set eax to 639
skip_dp2:

	cmp ebx, 0
	jnl skip_dp3					;if ebx >= 0, skip
	ret
	;;mov ebx, 0						;if ebx < 0, we are out of bounds, set ebx to 0
skip_dp3:

	cmp ebx, 479					
	jng skip_dp4					;if ebx <= 479, skip
	ret
	;;mov ebx, 479					;if ebx > 479, we are out of bounds, set ebx to 479
skip_dp4:
	
	mov edx, ebx 					; edx <- ebx 
	shl edx, 9						; edx <- ebx * 2^9 
	shl ebx, 7						; ebx <- ebx * 2^7
	add ebx, edx 					; ebx <- ebx + edx = ebx(2^9 + 2^7) = ebx(640)
	add ebx, [ScreenBitsPtr]		; ebx <- ebx + [ScreenBitsPtr] = y(640) + M[ScreenBitsPtr]
	mov [eax + ebx], ecx 			;M[x + y*640 + ScreenBitsPtr] <- ecx 

	ret 			; Don't delete this line!!!
DrawPixel ENDP

BasicBlit PROC USES eax ebx ecx edx esi edi ptrBitmap:PTR EECS205BITMAP , xcenter:DWORD, ycenter:DWORD
	LOCAL bitmapwidth:DWORD, bitmapheight:DWORD, xstart:DWORD, ystart:DWORD, xcurr:DWORD, ycurr:DWORD, colorcurr:DWORD
	
	mov eax, ptrBitmap								;move pointer into eax 
	mov ebx, (EECS205BITMAP PTR [eax]).dwWidth   	;ebx <- bitmap width 
	mov bitmapwidth, ebx 							;bitmapwidth <- ebx (storage in local variable)
	mov ecx, (EECS205BITMAP PTR [eax]).dwHeight		;ecx <- bitmap height
	mov bitmapheight, ecx							;bitmapheight <- ecx (storage in local variable)
	
	sar ebx, 1 										;ebx <- bitmap width / 2
	sar ecx, 1 										;ecx <- bitmap height / 2
	
	mov edx, xcenter 								;edx <- xcenter
	sub edx, ebx 									;edx <- xcenter - bitmap_width/2
	mov xstart, edx 								;xstart <- edx (calculate the top left x-coordinate of the image)
	 
	
	mov edx, ycenter								;edx <- ycenter
	sub edx, ecx 									;edx <- ycenter - bitmap_height/2
	mov ystart, edx 								;ystart <- edx (calculate the top left y-coordinate of the image)
	
	xor ebx, ebx									; Set outer loop variable to 0 (iterate through the rows)
	xor ecx, ecx 									; Set inner loop variable to 0 (iterate through the columns)

;ebx = outter loop variable = i, ecx = inner loop variable = j, eax = bitmap pointer; other registers are temporary
;outer loop: iterate through the rows until the row index is equal to the height
	jmp outerLoop 									; jump to evaluate outer loop condition
outerBody: 

;inner loop: iterate through the columns until the column index is equal to the width
	jmp innerLoop									; jump to evaluate the inner loop condition

innerBody:
	mov eax, ebx 									; eax <- ebx = i 
	imul bitmapwidth								; {edx, eax} <- eax * bitmapwidth = i * bitmapwidth
	mov edi, eax 									; edi <- eax = i * bitmapwidth
	add edi, ecx									; edi <- edi + ecx = i*bitmapwidth + j 
	mov eax, ptrBitmap								; mov ptrBitmap back into eax, which was overriden by imul 
	
	mov edx, (EECS205BITMAP PTR[eax]).lpBytes		;edx now a pointer to the first pixel data corresponding to (0,0) on the bitmap
	movzx esi, BYTE PTR [edx + edi]					; esi <- m[edx + edi] = m[lpBytes + i*bitmapwidth+j] = target color data 
	movzx edx, (EECS205BITMAP PTR[eax]).bTransparent	; edx <- ptrBitmap.bTransparent  
	cmp esi, edx 									; compare the current color data with the bTransparent color 
	je skipDraw 									; if esi = bTransparent, then we skip drawing this pixel 
	
	mov colorcurr, esi 								; colorcurr <- esi
	
	mov edx, ecx 									; edx <- ecx = j
	add edx, xstart 								; edx <- edx + xstart = j + xstart (we draw from xstart to xstart + bitmapwidth-1)
	mov xcurr, edx 									; xcurr <- edx = j + xstart 
	
	mov edx, ebx 									; edx <- ebx = i
	add edx, ystart									; edx <- edx + ystart = i + ystart (we draw from ystart to ystart + bitmapheight-1)
	mov ycurr, edx 									; ycurr <- edx = i + ystart 
	
	INVOKE DrawPixel, xcurr, ycurr, colorcurr 		; Call DrawPixel(xcurr, ycurr, colorcurr)

skipDraw:
	inc ecx 										; ecx <- ecx++ = j++ (loop through all the columns) 
	
innerLoop:
	cmp ecx, bitmapwidth							;compare j and bitmap width (we iterate from 0 to bitmapwidth - 1 to get all columns)
	jl innerBody									; if j < bitmapwidth, jump to inner body 
;end of inner loop 
	inc ebx 										; ebx <- ebx++ = i++
	xor ecx, ecx 									; we must clear the inner loop index for the next iteration of the outer loop 
	
outerLoop:											
	cmp ebx, bitmapheight 							;compare i and bitmapheight (we iterate from 0 to bitmapheight - 1 to get all rows) 
	jl outerBody 									;if i < bitmapheight, jump to outer body 
;end of outer loop 
	
	ret 			; Don't delete this line!!!	
BasicBlit ENDP


RotateBlit PROC USES eax ebx ecx edx esi edi ptrBitmap:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:FXPT
	LOCAL  cosa:DWORD, sina:DWORD, fxptwidth:DWORD, fxptheight:DWORD, bmheight:DWORD, bmwidth:DWORD, shiftX:DWORD, shiftY:DWORD, dstWidth:DWORD, dstHeight:DWORD,
			transparancy:DWORD, srcX:DWORD, srcY:DWORD, xcurr:DWORD, ycurr:DWORD, colorcurr:DWORD 
	;initialize local variables
	INVOKE FixedCos, angle								;Call fixedCos
	mov cosa, eax 										;cosa <- fixedcos(angle)
	
	INVOKE FixedSin, angle								
	mov sina, eax 										;sina <- fixedcos(angle)
	
	mov esi, ptrBitmap 									;esi <- lpBmp (bit map pointer)
	mov eax, (EECS205BITMAP PTR [esi]).dwWidth 			;eax <- bit map width 
	mov bmwidth, eax 									;bmwidth <- eax = bit map width
	sal eax, 16											;eax <- eax << 16 (shifting the width 16 bits to the left to convert it into a fxpt 
	mov fxptwidth, eax 									;fxptwidth <- bit map width << 16 
	mov eax, (EECS205BITMAP PTR [esi]).dwHeight			;eax <- bit map height
	mov bmheight, eax 									;bmheight <- bit map height 
	sal eax, 16											;eax <- eax << 16
	mov fxptheight, eax 								;fxptheight <- bit map height << 16
	movzx eax, (EECS205BITMAP PTR[esi]).bTransparent	;edx <- transparency color
	mov transparancy, eax 
	
	;find ShiftX, esi = bit map pointer, ebx = cosa/2, ecx = sina/2
	mov ebx, cosa 										;ebx <- cosa 
	sar ebx, 1											;ebx <- cosa >> 1 = cosa / 2
	mov ecx, sina 										;ecx <- sina 
	sar ecx, 1 											;ecx <- sina >> 1 = sina / 2
	
	mov eax, fxptwidth									;eax <- fxptwidth
	imul ebx 											;{edx, eax} <- fxptwidth * cosa/2
	mov edi, edx 										;edi <- edx (truncating 32.32 fxpt into a 32 bit int 
	mov eax, fxptheight									;eax <- fxptheight
	imul ecx 											;{edx, eax} <- fxptheight * sina/2
	sub edi, edx 										;edi <- edi - edx (truncating 32.32 fxpt into a 32 bit int in edx)
	mov shiftX, edi 									;shiftX<-edi 
	
	;find shiftY, ebx should still be cosa/2 and ecx should still be sina/2, esi = bit map pointer 
	mov eax, fxptheight 								;eax <-  fxptheight 
	imul ebx 											;{edx, eax} <- fxptheight * cosa/2
	mov edi, edx 										;edi <- edx (truncating 32 bits right of the binary point)
	mov eax, fxptwidth									;eax <- fxtptwidth
	imul ecx 											;{edx, eax} <- fxptwifth * sina/2 
	add edi, edx 										;edi <- edi + edx (truncate eax away since it's right of the binary point) 
	mov shiftY, edi 									; shiftY <- edi
	
	;find dstWidth and dstHeight, esi = bit map pointer 
	mov eax, bmwidth									;eax <- bmwidth
	add eax, bmheight									;eax <- bmheight + bmwidth
	mov dstWidth, eax 									;dstWidth <- eax = bmheight + bmwidth
	mov dstHeight, eax 									;dstHeight <- dstWidth 
	
	;nested for loops, esi = bit map pointer, ebx = dstX = outer loop variable, ecx = dstY = inner loop variable 
	mov ebx, dstWidth									;ebx <- dstWidth = outer loop variable
	neg ebx 											;ebx <- -dstWidth
	mov ecx, dstHeight									;ecx <- dstHeight = inner loop variable 
	neg ecx												;ecx <- -ecx 										
	
	;outer loop 
	jmp outerLoopEval 									;jmp to outer loop evaluation
outerLoopBody:
	
	;inner loop 
	jmp innerLoopEval									;jmp to innerLoopEval 
innerLoopBody:
	
	;find srcX 
	mov eax, cosa 										;eax <- cosa 
	mov edi, ebx										;edi <- ebx = dstX 
	sal edi, 16											;edi <- dstX << 16 (convert int to fxpt)
	imul edi 											;{edx, eax} <- cosa * (fxpt)dstX
	mov srcX, edx 										;srcX <- edx (truncate results by ignoring 32 bits right of binary point)
	mov eax, sina 										;eax<-sina 
	mov edi, ecx 										;edi<-ecx = dstY
	sal edi, 16											;edi <- dstY << 16 (convert int to fxpt) 
	imul edi 											;{edx, eax} <- sina * (fxpt)dstY 
	add srcX, edx										;edx <- edx + srcX (edx = truncated results of multiplication to convert back to int)

	;find srcY
	mov eax, cosa 										;eax <- cosa 
	mov edi, ecx 										; edi <- ecx = dstY
	sal edi ,16											;edi <- dstY << 16 (convert int to fxpt)
	imul edi											;{edx, eax} <- cosa * (fxpt)dsty
	mov srcY, edx										;srcY <- edx = truncated product to ignore fractional component	
	mov eax, sina										;eax <- sina
	mov edi, ebx 										;edi <- ebx = dstX
	sal edi, 16											;edi <- dstX << 16 (convert int to fxpt)
	imul edi 											;{edx, eax} <- edi * eax = fxpt(dstX) * sina  
	sub srcY, edx 										; srcY <- srcY - edx (trunctated results to only get the integer portion)
	
	
	;if statement (9 conditions must all be true in order for us to draw) 
	cmp srcX, 0 										; compare SrcX and 0
	jnge shortExit										; if srcX < 0, do not draw 
		
	mov eax, bmwidth									;eax<-bmwidth
	cmp srcX, eax 										;compare srcX and bmwidth
	jnl shortExit										;do not draw if srcX >= bmwidth 
	
	cmp srcY, 0 										;compare srcY and 0
	jnge shortExit										;do not draw if srcY < 0
	
	mov eax, bmheight 									;eax <- bmheight 
	cmp srcY, eax 										;cmp srcY, bmheight 
	jnl shortExit 										;if srcY >= bmheight, do not draw 
	
	mov eax, xcenter 									;eax <- xcenter
	add eax, ebx 										;eax <- eax + ebx = xcenter + dstX 
	sub eax, shiftX 									;eax <- eax - shiftX = xcenter + dstX - shiftX 
	mov xcurr, eax 										;xcurr <- eax = xcenter + dstX - shiftX
	
	cmp xcurr, 0 										;compare xcurr, 0
	jnge shortExit 										;if xcurr < 0, then do not draw 
	
	cmp xcurr, 639 										;cmp xcurr, 639 
	jnl shortExit 										;if xcurr >= 639, do not draw
	
	mov eax, ycenter 									;eax <- ycenter	
	add eax, ecx 										;eax <- ycenter + ecx = ycenter + dstY 
	sub eax, shiftY 									;eax <- eax - shiftY = ycenter + dstY - shiftY 
	mov ycurr, eax 										;ycurr <- eax = ycenter + dstY - shiftY 
	
	cmp ycurr, 0 										;cmp ycurr, 0
	jnge shortExit										;if ycurr < 0, do not draw
	
	cmp ycurr, 479										;comparision
	jnl shortExit										;if ycurr >= 479, no not draw 
	
	mov eax, bmwidth 									;eax <- bmwidth (width of the bit map)
	imul srcY 											;{edx, eax} <- bmwidth * srcY 
	add eax, srcX 										;eax <- eax + srcX = bmwidth(srcY) + srcX 
	mov edi, (EECS205BITMAP PTR[esi]).lpBytes			;edi <- lpBytes 
	xor edx, edx 										;edx <- 0 just in case
	movzx edx, BYTE PTR [edi + eax]						;edx <- sign extended m[edi + eax] to access the color data
	mov eax, transparancy								;eax <- transparent color value 
	
	cmp edx, eax 									 	
	je shortExit 									 	;if edx = eax (color data = transparent color), we do not draw
		
	mov colorcurr, edx  								;colorcurr <- edx 
	
	INVOKE DrawPixel, xcurr, ycurr, colorcurr 			;call DrawPixel(xcurr, ycurr, colorcurr)

shortExit:
	inc ecx 											;increment dstY for inner loop evalutaion 
innerLoopEval: 											 
	cmp ecx, dstHeight									;compare dstY and dstHeight 
	jl innerLoopBody									;if dstY < dstHeight, re iterate through inner loop
	;end inner loop 
	
	inc ebx												;increment dstX for outer loop evaluation
	mov ecx, dstHeight									;ecx<-dstHeight 
	neg ecx 											;ecx <- -dstHeight (reset ecx for next iteration of the inner loop) 
outerLoopEval:											
	cmp ebx, dstWidth									;compare dstX and dstWidth
	jl outerLoopBody									;if dstX < dstWidth, jump to ouuter loop body 
	;outer loop end 
	
	ret 			; Don't delete this line!!!		
RotateBlit ENDP



END
